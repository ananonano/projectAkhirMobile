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

  // Cek apakah email sudah dipakai
  Future<bool> isEmailTaken(String email) async {
    return _db.checkEmailExists(email);
  }

  // Cek apakah phone sudah dipakai
  Future<bool> isPhoneTaken(String phone) async {
    return _db.checkPhoneExists(phone);
  }

  // Daftarkan user baru
  Future<int> register(UserModel user) async {
    return _db.registerUser(user.toMap());
  }

  // Login dengan email OR username
  Future<UserModel?> loginWithEmailOrUsername(String emailOrUsername, String hashedPassword) async {
    final map = await _db.loginWithEmailOrUsername(emailOrUsername, hashedPassword);
    if (map == null) return null;
    return UserModel.fromMap(map);
  }
}
