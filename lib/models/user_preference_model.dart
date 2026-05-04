/// Model untuk menyimpan preferensi user
class UserPreferenceModel {
  final int? id;
  final int userId;
  final String? favoriteSportType; // FUTSAL, BADMINTON, etc.
  final double? averagePrice; // Rata-rata harga yang sering dibooking
  final double? maxDistance; // Jarak maksimal yang sering dipilih (km)
  final List<int> favoriteFieldIds; // List ID lapangan favorit
  final Map<String, int> sportTypeCount; // Count berapa kali booking per sport type
  final DateTime? lastUpdated;

  UserPreferenceModel({
    this.id,
    required this.userId,
    this.favoriteSportType,
    this.averagePrice,
    this.maxDistance,
    this.favoriteFieldIds = const [],
    this.sportTypeCount = const {},
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'favorite_sport_type': favoriteSportType,
      'average_price': averagePrice,
      'max_distance': maxDistance,
      'favorite_field_ids': favoriteFieldIds.join(','),
      'sport_type_count': _encodeSportTypeCount(sportTypeCount),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory UserPreferenceModel.fromMap(Map<String, dynamic> map) {
    return UserPreferenceModel(
      id: map['id'],
      userId: map['user_id'],
      favoriteSportType: map['favorite_sport_type'],
      averagePrice: map['average_price'],
      maxDistance: map['max_distance'],
      favoriteFieldIds: map['favorite_field_ids'] != null && map['favorite_field_ids'].toString().isNotEmpty
          ? map['favorite_field_ids'].toString().split(',').map((e) => int.tryParse(e) ?? 0).toList()
          : [],
      sportTypeCount: _decodeSportTypeCount(map['sport_type_count']),
      lastUpdated: map['last_updated'] != null ? DateTime.parse(map['last_updated']) : null,
    );
  }

  static String _encodeSportTypeCount(Map<String, int> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  static Map<String, int> _decodeSportTypeCount(dynamic data) {
    if (data == null || data.toString().isEmpty) return {};
    
    final Map<String, int> result = {};
    final parts = data.toString().split(',');
    
    for (var part in parts) {
      final kv = part.split(':');
      if (kv.length == 2) {
        result[kv[0]] = int.tryParse(kv[1]) ?? 0;
      }
    }
    
    return result;
  }
}
