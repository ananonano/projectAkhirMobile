import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import '../models/lapangan_model.dart';
import '../models/user_preference_model.dart';
import '../database/database.dart';

/// Service untuk sistem rekomendasi lapangan
/// Menggunakan Content-Based Filtering dengan scoring system
class RecommendationService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Get recommended fields for user
  /// Returns list of fields sorted by relevance score
  Future<List<LapanganModel>> getRecommendedFields({
    required int userId,
    Position? userLocation,
    int limit = 10,
  }) async {
    try {
      print('[RecommendationService] Starting getRecommendedFields for user $userId');
      
      // 1. Load user preferences with timeout
      final preferences = await _loadUserPreferences(userId)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('[RecommendationService] Timeout loading preferences, returning null');
              return null;
            },
          );
      
      print('[RecommendationService] Preferences loaded: ${preferences != null}');
      
      // 2. Get all available fields
      final allFields = await _db.getAllLapangan();
      print('[RecommendationService] Found ${allFields.length} fields');
      
      if (allFields.isEmpty) {
        return [];
      }
      
      // 3. Calculate score for each field
      final scoredFields = <MapEntry<LapanganModel, double>>[];
      
      for (var field in allFields) {
        final score = await _calculateFieldScore(
          field: field,
          preferences: preferences,
          userLocation: userLocation,
        );
        scoredFields.add(MapEntry(field, score));
      }
      
      print('[RecommendationService] Scored ${scoredFields.length} fields');
      
      // 4. Sort by score (highest first)
      scoredFields.sort((a, b) => b.value.compareTo(a.value));
      
      // 5. Return top N fields
      final result = scoredFields
          .take(limit)
          .map((e) => e.key)
          .toList();
      
      print('[RecommendationService] Returning ${result.length} recommendations');
      return result;
    } catch (e) {
      print('[RecommendationService] Error getting recommendations: $e');
      return [];
    }
  }

  /// Calculate relevance score for a field
  /// Higher score = more relevant
  Future<double> _calculateFieldScore({
    required LapanganModel field,
    required UserPreferenceModel? preferences,
    Position? userLocation,
  }) async {
    double score = 0.0;

    // If no preferences (new user), use basic scoring
    if (preferences == null) {
      return _calculateNewUserScore(field, userLocation);
    }

    // 1. Sport Type Match (+3 points)
    if (preferences.favoriteSportType != null &&
        field.jenis.toUpperCase() == preferences.favoriteSportType!.toUpperCase()) {
      score += 3.0;
    }

    // 2. Price Match (+2 points if within range)
    if (preferences.averagePrice != null) {
      final priceDiff = (field.harga - preferences.averagePrice!).abs();
      final priceRange = preferences.averagePrice! * 0.3; // 30% tolerance
      
      if (priceDiff <= priceRange) {
        score += 2.0;
      } else if (priceDiff <= priceRange * 2) {
        score += 1.0; // Partial match
      }
    }

    // 3. Distance Match (+2 points if nearby)
    if (userLocation != null && field.lat != null && field.lng != null) {
      final distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        field.lat!,
        field.lng!,
      );

      if (preferences.maxDistance != null) {
        if (distance <= preferences.maxDistance!) {
          score += 2.0;
        } else if (distance <= preferences.maxDistance! * 1.5) {
          score += 1.0; // Partial match
        }
      } else {
        // Default: prefer nearby fields
        if (distance <= 5.0) {
          score += 2.0;
        } else if (distance <= 10.0) {
          score += 1.0;
        }
      }
    }

    // 4. Favorite Field (+3 points)
    if (field.id != null && preferences.favoriteFieldIds.contains(field.id)) {
      score += 3.0;
    }

    // 5. Sport Type Frequency (+1 point)
    final sportCount = preferences.sportTypeCount[field.jenis.toUpperCase()] ?? 0;
    if (sportCount > 0) {
      score += 1.0;
    }

    // 6. Rating Bonus (+0.5 to +1.5 based on rating)
    final rating = await _getFieldRating(field.id ?? 0);
    if (rating > 0) {
      score += (rating / 5.0) * 1.5; // Max 1.5 points for 5-star rating
    }

    // 7. Popularity Bonus (+0.5 if frequently booked)
    final bookingCount = await _getFieldBookingCount(field.id ?? 0);
    if (bookingCount > 10) {
      score += 0.5;
    }

    return score;
  }

  /// Calculate score for new users (no preferences yet)
  double _calculateNewUserScore(LapanganModel field, Position? userLocation) {
    double score = 0.0;

    // Prioritize nearby fields
    if (userLocation != null && field.lat != null && field.lng != null) {
      final distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        field.lat!,
        field.lng!,
      );

      if (distance <= 5.0) {
        score += 3.0;
      } else if (distance <= 10.0) {
        score += 2.0;
      } else if (distance <= 20.0) {
        score += 1.0;
      }
    }

    // Add small random factor for variety
    score += Random().nextDouble() * 0.5;

    return score;
  }

  /// Load user preferences from database
  Future<UserPreferenceModel?> _loadUserPreferences(int userId) async {
    try {
      print('[RecommendationService] Loading preferences for user $userId');
      final db = await _db.database;
      
      // Check if preferences table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user_preferences'"
      );
      
      print('[RecommendationService] Preferences table exists: ${tables.isNotEmpty}');
      
      if (tables.isEmpty) {
        // Table doesn't exist, build preferences from booking history
        print('[RecommendationService] Building preferences from history (no table)');
        return await _buildPreferencesFromHistory(userId);
      }

      final result = await db.query(
        'user_preferences',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      print('[RecommendationService] Found ${result.length} preference records');

      if (result.isEmpty) {
        // No preferences saved, build from history
        print('[RecommendationService] Building preferences from history (no records)');
        return await _buildPreferencesFromHistory(userId);
      }

      print('[RecommendationService] Loaded preferences from database');
      return UserPreferenceModel.fromMap(result.first);
    } catch (e) {
      print('[RecommendationService] Error loading preferences: $e');
      print('[RecommendationService] Attempting to build from history as fallback');
      try {
        return await _buildPreferencesFromHistory(userId);
      } catch (e2) {
        print('[RecommendationService] Error building from history: $e2');
        return null;
      }
    }
  }

  /// Build preferences from booking history
  Future<UserPreferenceModel?> _buildPreferencesFromHistory(int userId) async {
    try {
      print('[RecommendationService] Building preferences from history for user $userId');
      final db = await _db.database;
      
      // Check if bookings table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='bookings'"
      );
      
      if (tables.isEmpty) {
        print('[RecommendationService] Bookings table does not exist');
        return null;
      }
      
      // Get user's booking history
      final bookings = await db.query(
        'bookings',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      print('[RecommendationService] Found ${bookings.length} bookings for user $userId');

      if (bookings.isEmpty) {
        print('[RecommendationService] No bookings found, returning null');
        return null; // New user, no data
      }

      // Analyze booking patterns
      final sportTypeCount = <String, int>{};
      final prices = <double>[];
      final fieldIds = <int>{};

      for (var booking in bookings) {
        // Get lapangan details
        final lapanganId = booking['lapangan_id'] as int?;
        if (lapanganId != null) {
          final lapangan = await db.query(
            'lapangans',
            where: 'id = ?',
            whereArgs: [lapanganId],
          );

          if (lapangan.isNotEmpty) {
            final jenis = lapangan.first['jenis'] as String?;
            final harga = lapangan.first['harga'] as int?;

            if (jenis != null) {
              sportTypeCount[jenis.toUpperCase()] = (sportTypeCount[jenis.toUpperCase()] ?? 0) + 1;
            }

            if (harga != null) {
              prices.add(harga.toDouble());
            }

            fieldIds.add(lapanganId);
          }
        }
      }

      print('[RecommendationService] Analyzed: ${sportTypeCount.length} sport types, ${prices.length} prices, ${fieldIds.length} fields');

      // Find favorite sport type (most booked)
      String? favoriteSportType;
      int maxCount = 0;
      sportTypeCount.forEach((sport, count) {
        if (count > maxCount) {
          maxCount = count;
          favoriteSportType = sport;
        }
      });

      // Calculate average price
      final averagePrice = prices.isNotEmpty
          ? prices.reduce((a, b) => a + b) / prices.length
          : null;

      print('[RecommendationService] Built preferences: sport=$favoriteSportType, avgPrice=$averagePrice');

      return UserPreferenceModel(
        userId: userId,
        favoriteSportType: favoriteSportType,
        averagePrice: averagePrice,
        maxDistance: 10.0, // Default 10km
        favoriteFieldIds: fieldIds.toList(),
        sportTypeCount: sportTypeCount,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('[RecommendationService] Error building preferences: $e');
      print('[RecommendationService] Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Get average rating for a field
  Future<double> _getFieldRating(int fieldId) async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery(
        'SELECT AVG(rating) as avg_rating FROM reviews WHERE lapangan_id = ?',
        [fieldId],
      );

      if (result.isNotEmpty && result.first['avg_rating'] != null) {
        return (result.first['avg_rating'] as num).toDouble();
      }
    } catch (e) {
      print('[RecommendationService] Error getting rating: $e');
    }
    return 0.0;
  }

  /// Get booking count for a field
  Future<int> _getFieldBookingCount(int fieldId) async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bookings WHERE lapangan_id = ?',
        [fieldId],
      );

      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
    } catch (e) {
      print('[RecommendationService] Error getting booking count: $e');
    }
    return 0;
  }

  /// Update user preferences (called after booking)
  Future<void> updateUserPreferences(int userId) async {
    try {
      final preferences = await _buildPreferencesFromHistory(userId);
      
      if (preferences == null) return;

      final db = await _db.database;
      
      // Create table if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_preferences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL UNIQUE,
          favorite_sport_type TEXT,
          average_price REAL,
          max_distance REAL,
          favorite_field_ids TEXT,
          sport_type_count TEXT,
          last_updated TEXT
        )
      ''');

      // Insert or update
      await db.insert(
        'user_preferences',
        preferences.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('[RecommendationService] Preferences updated for user $userId');
    } catch (e) {
      print('[RecommendationService] Error updating preferences: $e');
    }
  }
}
