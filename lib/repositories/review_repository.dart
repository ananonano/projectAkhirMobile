import 'package:sqflite/sqflite.dart';
import '../database/database.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Add a new review
  Future<int> addReview(Review review) async {
    try {
      Database db = await _dbHelper.database;
      int id = await db.insert('reviews', review.toMap());
      print('[ReviewRepo] Review added with ID: $id');
      return id;
    } catch (e) {
      print('[ReviewRepo] Error adding review: $e');
      rethrow;
    }
  }

  // Get all reviews for a specific lapangan with user info
  Future<List<Review>> getReviewsByLapangan(int lapanganId) async {
    try {
      Database db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          r.id,
          r.user_id,
          r.lapangan_id,
          r.rating,
          r.comment,
          r.created_at,
          u.name as user_name,
          u.image as user_image
        FROM reviews r
        JOIN users u ON r.user_id = u.id
        WHERE r.lapangan_id = ?
        ORDER BY r.created_at DESC
      ''', [lapanganId]);

      return result.map((map) => Review.fromMap(map)).toList();
    } catch (e) {
      print('[ReviewRepo] Error getting reviews: $e');
      return [];
    }
  }

  // Get user's review for a specific lapangan (to check if they already reviewed)
  Future<Review?> getUserReview(int userId, int lapanganId) async {
    try {
      Database db = await _dbHelper.database;
      final result = await db.query(
        'reviews',
        where: 'user_id = ? AND lapangan_id = ?',
        whereArgs: [userId, lapanganId],
      );

      if (result.isNotEmpty) {
        return Review.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('[ReviewRepo] Error getting user review: $e');
      return null;
    }
  }

  // Alias for getUserReview
  Future<Review?> getUserReviewForLapangan(int userId, int lapanganId) async {
    return getUserReview(userId, lapanganId);
  }

  // Update an existing review
  Future<int> updateReview(Review review) async {
    try {
      Database db = await _dbHelper.database;
      int changes = await db.update(
        'reviews',
        review.toMap(),
        where: 'id = ?',
        whereArgs: [review.id],
      );
      print('[ReviewRepo] Review updated, changes: $changes');
      return changes;
    } catch (e) {
      print('[ReviewRepo] Error updating review: $e');
      rethrow;
    }
  }

  // Delete a review
  Future<int> deleteReview(int reviewId) async {
    try {
      Database db = await _dbHelper.database;
      int changes = await db.delete(
        'reviews',
        where: 'id = ?',
        whereArgs: [reviewId],
      );
      print('[ReviewRepo] Review deleted, changes: $changes');
      return changes;
    } catch (e) {
      print('[ReviewRepo] Error deleting review: $e');
      rethrow;
    }
  }

  // Get average rating for a lapangan
  Future<double> getAverageRating(int lapanganId) async {
    try {
      Database db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT AVG(rating) as avg_rating FROM reviews WHERE lapangan_id = ?',
        [lapanganId],
      );

      if (result.isNotEmpty && result.first['avg_rating'] != null) {
        return (result.first['avg_rating'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('[ReviewRepo] Error getting average rating: $e');
      return 0.0;
    }
  }

  // Get review count for a lapangan
  Future<int> getReviewCount(int lapanganId) async {
    try {
      Database db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM reviews WHERE lapangan_id = ?',
        [lapanganId],
      );

      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      print('[ReviewRepo] Error getting review count: $e');
      return 0;
    }
  }

  // Get all recent reviews across all lapangans (for admin dashboard)
  Future<List<Map<String, dynamic>>> getAllRecentReviews({int limit = 5}) async {
    try {
      Database db = await _dbHelper.database;
      
      // Sort by ID descending (newest first) for consistency with bookings
      final result = await db.rawQuery('''
        SELECT 
          r.id,
          r.user_id,
          r.lapangan_id,
          r.rating,
          r.comment,
          r.created_at,
          COALESCE(u.name, 'Unknown User') as user_name,
          u.image as user_image,
          COALESCE(l.nama_lapangan, 'Unknown Lapangan') as lapangan_name
        FROM reviews r
        LEFT JOIN users u ON r.user_id = u.id
        LEFT JOIN lapangans l ON r.lapangan_id = l.id
        ORDER BY r.id DESC
        LIMIT ?
      ''', [limit]);

      print('[ReviewRepo] Loaded ${result.length} recent reviews');
      for (var review in result) {
        print('[ReviewRepo] - ID: ${review['id']} | ${review['user_name']} rated ${review['lapangan_name']}: ${review['rating']} stars');
      }
      return result;
    } catch (e) {
      print('[ReviewRepo] Error getting all recent reviews: $e');
      return [];
    }
  }
}
