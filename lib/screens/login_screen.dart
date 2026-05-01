import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'root.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();
  final _auth = LocalAuthentication();
  bool _canCheckBiometric = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceSupport();
    _autoLoginWithBiometric();
  }

  Future<void> _checkDeviceSupport() async {
    final isSupported = await _auth.isDeviceSupported();
    setState(() => _canCheckBiometric = isSupported);
  }

  Future<void> _autoLoginWithBiometric() async {
    final hasBioSession = await _authController.hasBiometricSession();
    if (hasBioSession && _canCheckBiometric) _handleBiometricAuth();
  }

  Future<void> _handleBiometricAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final bioUsername = prefs.getString('biometric_username');
    if (bioUsername == null) {
      if (mounted) _showSnack('Belum ada akun yang daftarin sidik jari bre!', Colors.orange);
      return;
    }
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Scan sidik jari buat masuk sebagai $bioUsername',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (authenticated && mounted) {
        final user = await _authController.loginWithBiometric();
        if (user != null) {
          _showSnack('Welcome back, ${user.username}!', AppColors.success);
          _navigateBasedOnRole(user.role);
        }
      }
    } catch (e) {
      debugPrint("Error biometric: $e");
    }
  }

  void _navigateBasedOnRole(String role) {
    if (role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RootScreen()));
    }
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showSnack('Isi dulu username sama passwordnya ya', Colors.orange);
      return;
    }
    setState(() => _isLoading = true);
    final user = await _authController.login(username, password);
    setState(() => _isLoading = false);
    if (user != null) {
      await _authController.saveSession(user);
      if (mounted) {
        _showSnack('Login Sukses!', AppColors.success);
        _navigateBasedOnRole(user.role);
      }
    } else {
      if (mounted) _showSnack('Username atau Password salah!', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- HEADER ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Lapang.in',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selamat datang kembali 👋',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15),
                    ),
                  ],
                ),
              ),

              // --- FORM ---
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('Masuk ke Akun', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Masukkan kredensial kamu untuk lanjut', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 28),

                    // Username
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),

                    // Biometric
                    if (_canCheckBiometric) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('atau', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _handleBiometricAuth,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2),
                              color: AppColors.primary.withOpacity(0.06),
                            ),
                            child: const Icon(Icons.fingerprint_rounded, size: 36, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text('Login dengan sidik jari', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ),
                    ],

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum punya akun? ', style: TextStyle(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text('Daftar Sekarang', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
