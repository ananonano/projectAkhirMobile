import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../controllers/auth_controller.dart';
import '../controllers/time_controller.dart';
import '../theme/app_theme.dart';
import '../database/database.dart';
import '../models/user_model.dart';
import '../widgets/user_vouchers_widget.dart';
import 'login_screen.dart';
import 'dodge_ball_screen.dart';
import 'edit_profile_screen.dart';
import 'time_converter_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = "User";
  String _role = "user";
  bool _isBiometricEnabled = false;
  String? _imagePath; // State buat nyimpen path gambar
  UserModel? _currentUser;

  final AuthController _authController = AuthController();
  final TimeController _timeController = TimeController();
  final LocalAuthentication auth = LocalAuthentication();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  String _selectedTimeZone = 'WIB';

  final Map<String, int> _timeZoneOffsets = TimeController.profileTimeZones;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBiometricStatus();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }



  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getFormattedTime() {
    return _timeController.getCurrentTimeInZone(_selectedTimeZone);
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    
    setState(() {
      _username = username ?? "User";
      _role = prefs.getString('role') ?? "user";
      // Load foto profil berdasarkan username spesifik (bukan global)
      _imagePath = prefs.getString('profile_image_$_username');
    });

    // Load user dari database
    if (username != null) {
      try {
        final db = await _dbHelper.database;
        final result = await db.query(
          'users',
          where: 'username = ?',
          whereArgs: [username],
        );

        if (result.isNotEmpty) {
          setState(() {
            _currentUser = UserModel.fromMap(result.first);
          });
          print('[ProfileScreen] User loaded from database: ${_currentUser?.name}');
        }
      } catch (e) {
        print('[ProfileScreen] Error loading user from database: $e');
      }
    }
  }

  void _showVouchersDialog() {
    showDialog(
      context: context,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.local_offer_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'Voucher Saya',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: UserVouchersWidget(username: _username),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }



  Future<void> _checkBiometricStatus() async {
    final isEnabled = await _authController.isBiometricEnabled(_username);
    setState(() => _isBiometricEnabled = isEnabled);
  }

  Future<void> _setupBiometric() async {
    try {
      final bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('HP lu nggak support biometrik bre!')),
          );
        }
        return;
      }

      // Cek apakah sudah ada akun lain yang pakai biometrik di HP ini
      final prefs = await SharedPreferences.getInstance();
      final existingBioUser = prefs.getString('biometric_username');
      if (existingBioUser != null && existingBioUser != _username) {
        // Tampilkan konfirmasi sebelum overwrite
        if (mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Ganti Akun Biometrik?', style: TextStyle(fontWeight: FontWeight.w800)),
              content: Text(
                'HP ini sudah terdaftar untuk akun "$existingBioUser".\n\n'
                'Catatan: Satu HP hanya bisa menyimpan 1 akun biometrik. '
                'Jika dilanjutkan, akun "$existingBioUser" tidak bisa login pakai sidik jari lagi.',
                style: const TextStyle(height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Ganti ke Akun Ini', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (confirm != true) return;
        }
      }

      bool authenticated = await auth.authenticate(
        localizedReason: 'Verifikasi sidik jari untuk mengaktifkan login biometrik untuk akun $_username',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (authenticated) {
        await _authController.saveBiometricOwner(_username, _role);
        setState(() => _isBiometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sidik jari untuk $_username berhasil didaftarkan!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error setup biometric: $e");
    }
  }

  // Reset biometrik dari akun ini
  Future<void> _resetBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_enabled');
    await prefs.remove('biometric_username');
    await prefs.remove('biometric_role');
    setState(() => _isBiometricEnabled = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login biometrik berhasil dinonaktifkan.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _openEditProfile() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User data not loaded')),
      );
      return;
    }

    final updatedUser = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser!),
      ),
    );

    if (updatedUser != null && mounted) {
      // Update state dengan user baru
      setState(() {
        _currentUser = updatedUser;
        // Update _imagePath langsung dari updatedUser
        _imagePath = updatedUser.image;
      });
      
      // Reload dari SharedPreferences untuk memastikan sinkron
      await _loadUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _logout() async {
    await _authController.logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _tampilSaranKesan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text(
              'Saran & Kesan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Kesan:\nMata kuliah TPM ini seru banget karena langsung praktek bikin aplikasi nyata (Lapang.in) yang siap pakai.\n\n'
          'Saran:\nSemoga ke depannya materi integrasi API dan AI bisa dibahas lebih mendalam lagi.',
          style: TextStyle(height: 1.6, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF64E42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== PROFILE CARD =====
              Container(
                width: double.infinity,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadows: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 1,
                                color: const Color(0xFFEEEEEA),
                              ),
                            ),
                            child: _buildProfileImage(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        _currentUser?.name ?? _username,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color:
                              AppColors.primary.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(9999),
                          ),
                        ),
                        child: const Text(
                          'Aktif',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Edit Button
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: ShapeDecoration(
                          color: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openEditProfile,
                            child: const Center(
                              child: Text(
                                'Edit Profil',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // ===== STATS CARDS (HORIZONTAL) =====
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard('👕', '12', 'Booking'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatsCard('🎮', '8', 'Hobi'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatsCard('⭐', '450', 'Poin'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // ===== CURRENT TIME SECTION - ATTRACTIVE CARD =====
              Container(
                width: double.infinity,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadows: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Top gradient section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.9),
                            AppColors.primaryLight.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Waktu Saat Ini',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      _selectedTimeZone,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _getFormattedTime(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom section with timezone selector
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubah Zona Waktu',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  width: 2,
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedTimeZone,
                              isExpanded: true,
                              underline: const SizedBox(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              icon: const Icon(
                                Icons.expand_more_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              items: _timeZoneOffsets.keys.map((tz) {
                                return DropdownMenuItem(
                                  value: tz,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        tz,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newTz) {
                                if (newTz != null) {
                                  setState(() => _selectedTimeZone = newTz);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // ===== PENGATURAN AKUN =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'PENGATURAN AKUN',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      Icons.fingerprint_rounded,
                      'Login Biometrik',
                      _isBiometricEnabled
                          ? 'Aktif'
                          : 'Nonaktif',
                      _isBiometricEnabled
                          ? _resetBiometric
                          : _setupBiometric,
                    ),
                    _buildSettingDivider(),
                    _buildSettingItem(
                      Icons.lock_rounded,
                      'Keamanan Akun',
                      'Ubah password',
                      () {},
                    ),
                    _buildSettingDivider(),
                    _buildSettingItem(
                      Icons.local_offer_rounded,
                      'Voucher',
                      'Lihat voucher',
                      _showVouchersDialog,
                    ),
                    _buildSettingDivider(),
                    _buildSettingItem(
                      Icons.sports_esports_rounded,
                      'Main Dodge Ball',
                      'Mainkan game',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DodgeBallScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ===== LOGOUT BUTTON =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _logout,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Log Out',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: AppColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: ShapeDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingDivider() {
    return Divider(
      height: 1,
      color: AppColors.border,
      indent: 16,
      endIndent: 16,
    );
  }

  // Method untuk build profile image dengan error handling
  Widget _buildProfileImage() {
    // Jika tidak ada path atau kosong, tampilkan default gradient
    if (_imagePath == null || _imagePath!.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primaryLight.withOpacity(0.8),
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          size: 48,
          color: Colors.white,
        ),
      );
    }

    // Jika path adalah URL (network image)
    if (_imagePath!.startsWith('http')) {
      return Image.network(
        _imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback ke default jika gagal load
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.primaryLight.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 48,
              color: Colors.white,
            ),
          );
        },
      );
    }

    // Jika path adalah file lokal
    final file = File(_imagePath!);
    
    // Cek apakah file exists
    if (!file.existsSync()) {
      // File tidak ada, tampilkan default
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primaryLight.withOpacity(0.8),
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          size: 48,
          color: Colors.white,
        ),
      );
    }

    // File exists, tampilkan gambar
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback ke default jika gagal load
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.8),
                AppColors.primaryLight.withOpacity(0.8),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 48,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
