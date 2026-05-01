import '../database/database.dart';
import '../models/voucher_model.dart';

class VoucherRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Get all vouchers for a user
  Future<List<VoucherModel>> getUserVouchers(String username) async {
    final database = await _db.database;
    final data = await database.query(
      'vouchers',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'created_at DESC',
    );
    return data.map((map) => VoucherModel.fromMap(map)).toList();
  }

  // Get unused vouchers for a user
  Future<List<VoucherModel>> getUnusedVouchers(String username) async {
    final database = await _db.database;
    final data = await database.query(
      'vouchers',
      where: 'username = ? AND is_used = 0',
      whereArgs: [username],
      orderBy: 'percent_discount DESC',
    );
    return data.map((map) => VoucherModel.fromMap(map)).toList();
  }

  // Create new voucher from dodge ball score
  Future<int> createVoucher(VoucherModel voucher) async {
    final database = await _db.database;
    return database.insert('vouchers', voucher.toMap());
  }

  // Mark voucher as used
  Future<int> useVoucher(int voucherId) async {
    final database = await _db.database;
    return database.update(
      'vouchers',
      {
        'is_used': 1,
        'used_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [voucherId],
    );
  }

  // Get voucher by ID
  Future<VoucherModel?> getVoucherById(int id) async {
    final database = await _db.database;
    final data = await database.query(
      'vouchers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) return null;
    return VoucherModel.fromMap(data.first);
  }

  // Delete voucher by ID (admin only)
  Future<int> deleteVoucher(int id) async {
    final database = await _db.database;
    return database.delete('vouchers', where: 'id = ?', whereArgs: [id]);
  }

  // Get all vouchers (for admin management)
  Future<List<VoucherModel>> getAllVouchers() async {
    final database = await _db.database;
    final data = await database.query(
      'vouchers',
      orderBy: 'created_at DESC',
    );
    return data.map((map) => VoucherModel.fromMap(map)).toList();
  }

  // Check if user already got voucher from same score in this game
  Future<bool> hasVoucherFromScore(String username, int score) async {
    final database = await _db.database;
    final data = await database.query(
      'vouchers',
      where: 'username = ? AND earned_score = ?',
      whereArgs: [username, score],
    );
    return data.isNotEmpty;
  }
}
