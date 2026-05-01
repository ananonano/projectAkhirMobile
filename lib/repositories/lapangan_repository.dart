import '../database/database.dart';
import '../models/lapangan_model.dart';

/// Semua operasi database yang berhubungan dengan tabel `lapangans`
class LapanganRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Ambil semua lapangan, dengan filter opsional
  Future<List<LapanganModel>> getLapangans({
    String? jenis,
    String? location,
  }) async {
    final database = await _db.database;

    String whereString = '';
    List<dynamic> whereArgs = [];

    if (jenis != null && jenis.isNotEmpty) {
      whereString += 'jenis = ?';
      whereArgs.add(jenis);
    }

    if (location != null && location.isNotEmpty) {
      if (whereString.isNotEmpty) whereString += ' AND ';
      whereString += '(nama_lapangan LIKE ? OR address LIKE ?)';
      whereArgs.add('%$location%');
      whereArgs.add('%$location%');
    }

    final data = await database.query(
      'lapangans',
      where: whereString.isNotEmpty ? whereString : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return data.map((map) => LapanganModel.fromMap(map)).toList();
  }

  // Ambil semua lapangan tanpa filter (untuk admin dashboard)
  Future<List<LapanganModel>> getAllLapangans() async {
    final database = await _db.database;
    final data = await database.query('lapangans', orderBy: 'id DESC');
    return data.map((map) => LapanganModel.fromMap(map)).toList();
  }

  // Tambah lapangan baru
  Future<int> insertLapangan(LapanganModel lapangan) async {
    final database = await _db.database;
    return database.insert('lapangans', lapangan.toMap());
  }

  // Hapus lapangan berdasarkan ID
  Future<int> deleteLapangan(int id) async {
    final database = await _db.database;
    return database.delete('lapangans', where: 'id = ?', whereArgs: [id]);
  }

  // Update lapangan berdasarkan ID
  Future<int> updateLapangan(LapanganModel lapangan) async {
    final database = await _db.database;
    return database.update(
      'lapangans',
      lapangan.toMap(),
      where: 'id = ?',
      whereArgs: [lapangan.id],
    );
  }
}
