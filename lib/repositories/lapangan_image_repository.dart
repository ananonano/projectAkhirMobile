import '../database/database.dart';

class LapanganImage {
  final int? id;
  final int lapanganId;
  final String imagePath;
  final int position;
  final String? createdAt;

  LapanganImage({
    this.id,
    required this.lapanganId,
    required this.imagePath,
    this.position = 0,
    this.createdAt,
  });

  factory LapanganImage.fromMap(Map<String, dynamic> map) {
    return LapanganImage(
      id: map['id'],
      lapanganId: map['lapangan_id'],
      imagePath: map['image_path'],
      position: map['position'] ?? 0,
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lapangan_id': lapanganId,
      'image_path': imagePath,
      'position': position,
    };
  }
}

class LapanganImageRepository {
  static final LapanganImageRepository _instance = LapanganImageRepository._private();
  final DatabaseHelper _db = DatabaseHelper.instance;

  LapanganImageRepository._private();

  factory LapanganImageRepository() {
    return _instance;
  }

  // Add new image to lapangan
  Future<int> addImage(LapanganImage image) async {
    try {
      final db = await _db.database;
      final result = await db.insert('lapangan_images', image.toMap());
      print('[LapanganImageRepo] Image added with ID: $result for lapangan ${image.lapanganId}');
      return result;
    } catch (e) {
      print('[LapanganImageRepo] Error adding image: $e');
      rethrow;
    }
  }

  // Get all images for a lapangan
  Future<List<LapanganImage>> getImagesByLapangan(int lapanganId) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'lapangan_images',
        where: 'lapangan_id = ?',
        whereArgs: [lapanganId],
        orderBy: 'position ASC',
      );
      print('[LapanganImageRepo] Loaded ${result.length} images for lapangan $lapanganId');
      return result.map((map) => LapanganImage.fromMap(map)).toList();
    } catch (e) {
      print('[LapanganImageRepo] Error getting images: $e');
      return [];
    }
  }

  // Delete image
  Future<void> deleteImage(int imageId) async {
    try {
      final db = await _db.database;
      await db.delete('lapangan_images', where: 'id = ?', whereArgs: [imageId]);
      print('[LapanganImageRepo] Image deleted: $imageId');
    } catch (e) {
      print('[LapanganImageRepo] Error deleting image: $e');
      rethrow;
    }
  }

  // Update image position (for reordering)
  Future<void> updateImagePosition(int imageId, int newPosition) async {
    try {
      final db = await _db.database;
      await db.update(
        'lapangan_images',
        {'position': newPosition},
        where: 'id = ?',
        whereArgs: [imageId],
      );
      print('[LapanganImageRepo] Image position updated: $imageId -> position $newPosition');
    } catch (e) {
      print('[LapanganImageRepo] Error updating position: $e');
      rethrow;
    }
  }

  // Add multiple images at once
  Future<void> addMultipleImages(int lapanganId, List<String> imagePaths) async {
    try {
      final db = await _db.database;
      for (int i = 0; i < imagePaths.length; i++) {
        final image = LapanganImage(
          lapanganId: lapanganId,
          imagePath: imagePaths[i],
          position: i,
        );
        await db.insert('lapangan_images', image.toMap());
      }
      print('[LapanganImageRepo] Added ${imagePaths.length} images for lapangan $lapanganId');
    } catch (e) {
      print('[LapanganImageRepo] Error adding multiple images: $e');
      rethrow;
    }
  }

  // Delete all images for a lapangan
  Future<void> deleteAllImages(int lapanganId) async {
    try {
      final db = await _db.database;
      await db.delete('lapangan_images', where: 'lapangan_id = ?', whereArgs: [lapanganId]);
      print('[LapanganImageRepo] All images deleted for lapangan $lapanganId');
    } catch (e) {
      print('[LapanganImageRepo] Error deleting all images: $e');
      rethrow;
    }
  }
}
