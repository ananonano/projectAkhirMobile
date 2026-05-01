import '../database/database.dart';
import '../models/user_model.dart';

/// Semua operasi database yang berhubungan dengan tabel `users`
class UserRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Login: cari user berdasarkan username + password (sudah di-hash SHA-1)
  Future<UserModel?> login(String username, String hashedPassword) async {
    final map = await _db.getUser(username, hashedPassword);
    if (map == null) return null;
    return UserModel.fromMap(map);
  }

  // Ambil user berdasarkan username saja (untuk biometric login)
  Future<UserModel?> getUserByUsername(String username) async {
    final map = await _db.getUserByUsername(username);
    if (map == null) return null;
    return UserModel.fromMap(map);
  }

  // Cek apakah username sudah dipakai
  Future<bool> isUsernameTaken(String username) async {
    return _db.checkUsernameExists(username);
  }

  // Daftarkan user baru
  Future<int> register(UserModel user) async {
    return _db.registerUser(user.toMap());
  }
}
