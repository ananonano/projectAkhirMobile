import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart';
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
      builder: (context) => AlertDialog(
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
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Buka galeri
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Simpan gambar dengan key yang unique per username
      await prefs.setString('profile_image_$_username', image.path);

      setState(() {
        _imagePath = image.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diupdate bre!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
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

    if (updatedUser != null) {
      setState(() => _currentUser = updatedUser);
      // Reload image from updated user data
      if (updatedUser.image != null) {
        setState(() => _imagePath = updatedUser.image);
      }
      
      // Reload user data from database to ensure everything is synced
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
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF64E42), Color(0xFFD93D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Profil Saya',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          _getFormattedTime(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier',
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTimeZone,
                              dropdownColor: const Color(0xFFF64E42),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              items: _timeZoneOffsets.keys.map((String zone) {
                                return DropdownMenuItem<String>(
                                  value: zone,
                                  child: Text(zone),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedTimeZone = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  // TAPPABLE AVATAR
                  child: GestureDetector(
                    onTap: _pickImage, // Pas diklik, buka galeri
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey[300],
                            // Logika nampilin foto yang diupload
                            backgroundImage: _imagePath != null
                                ? FileImage(File(_imagePath!))
                                : const AssetImage('assets/images/profile.jpg')
                                      as ImageProvider,
                            child: _imagePath == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF64E42),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 65),

            Text(
              (_currentUser?.name ?? _username).toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF64E42).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Mahasiswa Informatika',
                style: TextStyle(
                  color: Color(0xFFF64E42),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan Keamanan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildMenuCard(
                    Icons.fingerprint_rounded,
                    'Login Biometrik',
                    _isBiometricEnabled
                        ? 'Aktif untuk akun $_username — Ketuk untuk nonaktifkan'
                        : 'Daftarkan sidik jari untuk login cepat',
                    _isBiometricEnabled ? AppColors.success : Colors.blueAccent,
                    _isBiometricEnabled ? _resetBiometric : _setupBiometric,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Reward & Voucher',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildMenuCard(
                    Icons.local_offer_rounded,
                    'Voucher Saya',
                    'Lihat voucher yang kamu dapatkan',
                    Colors.orange,
                    _showVouchersDialog,
                  ),

                  const SizedBox(height: 12),

                  _buildMenuCard(
                    Icons.sports_esports_rounded,
                    'Main Dodge Ball',
                    'Hindari bola musuh & cetak High Score!',
                    Colors.purpleAccent,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DodgeBallScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Menu Tugas TPM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildMenuCard(
                    Icons.feedback_rounded,
                    'Saran & Kesan Kuliah',
                    'Review untuk mata kuliah TPM',
                    Colors.orangeAccent,
                    _tampilSaranKesan,
                  ),

                  const SizedBox(height: 12),

                  _buildMenuCard(
                    Icons.logout_rounded,
                    'Logout',
                    'Keluar dari sesi saat ini',
                    Colors.redAccent,
                    _logout,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
