import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// Mengelola semua logika autentikasi: login, register, session, biometrik
class AuthController {
  final UserRepository _userRepo = UserRepository();

  // Hash password pakai SHA-1 (sesuai yang disimpan di DB)
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Login dengan username + password
  Future<UserModel?> login(String username, String password) async {
    final hashed = hashPassword(password);
    return _userRepo.login(username, hashed);
  }

  // Login dengan email OR username + password
  Future<UserModel?> loginWithEmailOrUsername(String emailOrUsername, String password) async {
    final hashed = hashPassword(password);
    return _userRepo.loginWithEmailOrUsername(emailOrUsername, hashed);
  }

  // Simpan session ke SharedPreferences setelah login berhasil
  Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('user_id', user.id ?? 0);
    await prefs.setString('username', user.username);
    await prefs.setString('role', user.role);
    
    // Debug logging
    print('[AuthController] Session saved:');
    print('  - user_id: ${user.id}');
    print('  - username: ${user.username}');
    print('  - role: ${user.role}');
  }

  // Hapus session saat logout (tanpa hapus data biometrik & foto profil)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('role');
  }

  // Ambil data session yang sedang aktif
  Future<Map<String, dynamic>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool('isLoggedIn') ?? false,
      'user_id': prefs.getInt('user_id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'role': prefs.getString('role') ?? 'user',
    };
  }

  // Ambil user_id dari session aktif
  Future<int> getSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    print('[AuthController] getSessionUserId: $userId');
    return userId;
  }

  // Ambil username dari session aktif
  Future<String> getSessionUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  // Simpan session setelah biometric login berhasil
  // (query DB dulu untuk dapetin user_id yang benar)
  Future<UserModel?> loginWithBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final bioUser = prefs.getString('biometric_username');
    final bioRole = prefs.getString('biometric_role');

    if (bioUser == null) return null;

    // Ambil data lengkap user dari DB untuk dapetin user_id
    final user = await _userRepo.getUserByUsername(bioUser);
    if (user == null) return null;

    // Simpan session lengkap termasuk user_id
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('user_id', user.id ?? 0);
    await prefs.setString('username', bioUser);
    await prefs.setString('role', bioRole ?? 'user');

    return user;
  }

  // Simpan data biometrik (username + role pemilik sidik jari)
  Future<void> saveBiometricOwner(String username, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', true);
    await prefs.setString('biometric_username', username);
    await prefs.setString('biometric_role', role);
  }

  // Cek apakah biometrik sudah diaktifkan untuk user yang sedang login
  Future<bool> isBiometricEnabled(String currentUsername) async {
    final prefs = await SharedPreferences.getInstance();
    final bioUser = prefs.getString('biometric_username');
    return bioUser == currentUsername;
  }

  // Cek apakah ada session biometrik yang tersimpan
  Future<bool> hasBiometricSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final isBioEnabled = prefs.getBool('biometric_enabled') ?? false;
    return isLoggedIn && isBioEnabled;
  }

  // Register user baru dengan data lengkap
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? name,
    String? email,
    String? phone,
  }) async {
    // Check username
    final usernameTaken = await _userRepo.isUsernameTaken(username);
    if (usernameTaken) {
      return {
        'success': false,
        'message': 'Username sudah dipakai, gunakan username lain!',
      };
    }

    // Check email
    if (email != null && email.isNotEmpty) {
      final emailTaken = await _userRepo.isEmailTaken(email);
      if (emailTaken) {
        return {
          'success': false,
          'message': 'Email sudah dipakai, gunakan email lain!',
        };
      }
    }

    // Check phone
    if (phone != null && phone.isNotEmpty) {
      final phoneTaken = await _userRepo.isPhoneTaken(phone);
      if (phoneTaken) {
        return {
          'success': false,
          'message': 'Nomor telepon sudah dipakai, gunakan nomor lain!',
        };
      }
    }

    final user = UserModel(
      username: username,
      password: hashPassword(password),
      name: name,
      email: email,
      phone: phone,
      role: 'user',
    );
    
    await _userRepo.register(user);
    
    return {
      'success': true,
      'message': 'Registrasi berhasil!',
    };
  }

  // Verify password untuk user tertentu (untuk payment confirmation)
  Future<bool> verifyPassword(String username, String password) async {
    final hashed = hashPassword(password);
    final user = await _userRepo.login(username, hashed);
    return user != null;
  }

  // Update password untuk user tertentu
  Future<void> updatePassword(String username, String newPassword) async {
    final hashed = hashPassword(newPassword);
    await _userRepo.updatePassword(username, hashed);
  }
}
