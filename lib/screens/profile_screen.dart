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
import 'about_us_screen.dart';
import 'root.dart'; // Import untuk profileStatsRefreshNotifier

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
  
  // Dynamic stats
  int _totalBookings = 0;
  String _favoriteHobby = '-';
  int _highScore = 0;
  
  // Helper method untuk get icon berdasarkan jenis olahraga
  String _getHobbyIcon(String hobby) {
    switch (hobby.toLowerCase()) {
      case 'futsal':
        return '⚽';
      case 'mini soccer':
      case 'mini_soccer':
      case 'minsoc':
        return '⚽';
      case 'badminton':
        return '🏸';
      case 'basket':
      case 'basketball':
        return '🏀';
      case 'tennis':
        return '🎾';
      case 'voli':
      case 'volleyball':
        return '🏐';
      default:
        return '🏃'; // Default icon untuk olahraga umum
    }
  }
  
  // Helper method untuk format display name hobi
  String _formatHobbyName(String hobby) {
    if (hobby == '-') return '-';
    
    switch (hobby.toLowerCase()) {
      case 'mini soccer':
      case 'mini_soccer':
        return 'Minsoc';
      case 'futsal':
        return 'Futsal';
      case 'badminton':
        return 'Badminton';
      case 'basket':
      case 'basketball':
        return 'Basket';
      case 'tennis':
        return 'Tennis';
      case 'voli':
      case 'volleyball':
        return 'Voli';
      default:
        return hobby; // Return as-is jika tidak ada mapping
    }
  }

  final AuthController _authController = AuthController();
  final TimeController _timeController = TimeController();
  final LocalAuthentication auth = LocalAuthentication();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  String _selectedTimeZone = 'WIB';

  final Map<String, int> _timeZoneOffsets = TimeController.profileTimeZones;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBiometricStatus();
    _loadUserStats(); // Load dynamic stats
    
    // Listen to profile stats refresh notifier
    profileStatsRefreshNotifier.addListener(_onStatsRefreshTriggered);
  }
  
  void _onStatsRefreshTriggered() {
    print('[ProfileScreen] Stats refresh triggered by notifier');
    _loadUserStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh biometric status setiap kali screen muncul
    _checkBiometricStatus();
    // Refresh stats setiap kali screen muncul
    _loadUserStats();
  }



  @override
  void dispose() {
    profileStatsRefreshNotifier.removeListener(_onStatsRefreshTriggered);
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
          final userData = UserModel.fromMap(result.first);
          setState(() {
            _currentUser = userData;
            // Load foto dari database, fallback ke SharedPreferences
            _imagePath = userData.image ?? prefs.getString('profile_image_$_username');
          });
          print('[ProfileScreen] User loaded from database: ${_currentUser?.name}');
          print('[ProfileScreen] Profile image path: $_imagePath');
          
          // Sync ke SharedPreferences jika ada di database
          if (userData.image != null && userData.image!.isNotEmpty) {
            await prefs.setString('profile_image_$_username', userData.image!);
          }
        }
      } catch (e) {
        print('[ProfileScreen] Error loading user from database: $e');
      }
    }
  }

  // Load dynamic user stats
  Future<void> _loadUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final username = prefs.getString('username') ?? 'guest';
      
      print('[ProfileScreen] Loading stats for userId: $userId, username: $username');
      
      if (userId == null) {
        print('[ProfileScreen] User ID not found in SharedPreferences');
        return;
      }

      final db = await _dbHelper.database;

      // 1. Hitung total bookings user
      final bookingResult = await db.rawQuery(
        'SELECT COUNT(*) as total FROM bookings WHERE user_id = ?',
        [userId],
      );
      final totalBookings = (bookingResult.first['total'] as int?) ?? 0;
      print('[ProfileScreen] Total bookings: $totalBookings');

      // 2. Cari jenis lapangan yang paling sering di-booking (hobi)
      // Cek dulu apakah ada bookings
      String favoriteHobby = '-';
      if (totalBookings > 0) {
        final hobbyResult = await db.rawQuery('''
          SELECT l.jenis, COUNT(*) as count
          FROM bookings b
          JOIN lapangans l ON b.lapangan_id = l.id
          WHERE b.user_id = ?
          GROUP BY l.jenis
          ORDER BY count DESC
          LIMIT 1
        ''', [userId]);
        
        print('[ProfileScreen] Hobby query result: $hobbyResult');
        
        if (hobbyResult.isNotEmpty) {
          final jenis = hobbyResult.first['jenis'] as String?;
          favoriteHobby = jenis ?? '-';
          print('[ProfileScreen] Favorite hobby: $favoriteHobby');
        }
      }

      // 3. Ambil highscore tertinggi dari game dodge ball (dari SharedPreferences)
      final highScore = prefs.getInt('dodgeball_highscore_$username') ?? 0;
      print('[ProfileScreen] Highscore for $username: $highScore');
      print('[ProfileScreen] Highscore key: dodgeball_highscore_$username');

      // Update state
      if (mounted) {
        setState(() {
          _totalBookings = totalBookings;
          _favoriteHobby = favoriteHobby;
          _highScore = highScore;
        });
      }

      print('[ProfileScreen] Stats updated - Bookings: $_totalBookings, Hobi: $_favoriteHobby, Highscore: $_highScore');
    } catch (e) {
      print('[ProfileScreen] Error loading user stats: $e');
      print('[ProfileScreen] Stack trace: ${StackTrace.current}');
    }
  }

  // Helper method untuk set highscore manual (untuk restore atau testing)
  Future<void> _setHighscoreManual(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? 'guest';
      
      await prefs.setInt('dodgeball_highscore_$username', score);
      print('[ProfileScreen] ✅ Highscore set manually for $username: $score');
      
      // Reload stats
      await _loadUserStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Highscore berhasil di-set ke $score!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('[ProfileScreen] ❌ Error setting highscore: $e');
    }
  }

  // Dialog untuk restore highscore (long press pada stats card Poin)
  void _showRestoreHighscoreDialog() {
    final TextEditingController scoreController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.restore_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 12),
            Text(
              'Restore Highscore',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan highscore yang ingin di-restore:',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Highscore',
                hintText: 'Contoh: 1000',
                prefixIcon: const Icon(Icons.emoji_events_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.inputFill,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Highscore saat ini: $_highScore',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final score = int.tryParse(scoreController.text);
              if (score != null && score >= 0) {
                Navigator.pop(context);
                _setHighscoreManual(score);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Masukkan angka yang valid!'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Restore',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
    // Pastikan username sudah di-load terlebih dahulu
    if (_username == "User") {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      if (username != null) {
        setState(() => _username = username);
      }
    }
    
    final isEnabled = await _authController.isBiometricEnabled(_username);
    if (mounted) {
      setState(() => _isBiometricEnabled = isEnabled);
    }
    print('[ProfileScreen] Biometric status checked for $_username: $isEnabled');
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
        // Refresh status biometrik setelah berhasil setup
        await _checkBiometricStatus();
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
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nonaktifkan Login Biometrik?',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Anda akan perlu memasukkan username dan password untuk login setelah menonaktifkan fitur ini.',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 14,
            color: Color(0xFF78716C),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Lexend',
                color: Color(0xFF78716C),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Nonaktifkan',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    // If user confirmed, proceed with reset
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('biometric_enabled');
      await prefs.remove('biometric_username');
      await prefs.remove('biometric_role');
      // Refresh status biometrik setelah reset
      await _checkBiometricStatus();
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
  }

  // Show change password dialog
  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isOldPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;
    bool isLoading = false;
    String? errorMessage; // Error message to display in dialog

    // Store root context for SnackBars
    final rootContext = context;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Text(
                'Ganti Password',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan password lama dan password baru Anda',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Error message display
                if (errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Old Password
                TextField(
                  controller: oldPasswordController,
                  obscureText: !isOldPasswordVisible,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password Lama',
                    hintText: 'Masukkan password lama',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isOldPasswordVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          isOldPasswordVisible = !isOldPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill,
                  ),
                ),
                const SizedBox(height: 16),
                // New Password
                TextField(
                  controller: newPasswordController,
                  obscureText: !isNewPasswordVisible,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    hintText: 'Masukkan password baru',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isNewPasswordVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          isNewPasswordVisible = !isNewPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill,
                  ),
                ),
                const SizedBox(height: 16),
                // Confirm Password
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    hintText: 'Masukkan ulang password baru',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Password minimal 6 karakter',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withOpacity(0.8),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Clear previous error
                      setDialogState(() => errorMessage = null);

                      // Validation
                      if (oldPasswordController.text.isEmpty ||
                          newPasswordController.text.isEmpty ||
                          confirmPasswordController.text.isEmpty) {
                        setDialogState(() {
                          errorMessage = 'Semua field harus diisi';
                        });
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        setDialogState(() {
                          errorMessage = 'Password baru minimal 6 karakter';
                        });
                        return;
                      }

                      if (newPasswordController.text != confirmPasswordController.text) {
                        setDialogState(() {
                          errorMessage = 'Password baru dan konfirmasi tidak cocok';
                        });
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        // Verify old password
                        final isValid = await _authController.verifyPassword(
                          _username,
                          oldPasswordController.text,
                        );

                        if (!isValid) {
                          setDialogState(() {
                            isLoading = false;
                            errorMessage = 'Password lama salah!';
                          });
                          return;
                        }

                        // Update password
                        await _authController.updatePassword(
                          _username,
                          newPasswordController.text,
                        );

                        setDialogState(() => isLoading = false);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (rootContext.mounted) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(
                              content: const Text('Password berhasil diubah!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage = 'Error: $e';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Ubah Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
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
                    child: _buildStatsCard('🧾', _totalBookings.toString(), 'Booking'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatsCard(
                      _getHobbyIcon(_favoriteHobby), 
                      _formatHobbyName(_favoriteHobby), 
                      'Hobi'
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onLongPress: () => _showRestoreHighscoreDialog(),
                      child: _buildStatsCard('🏆', _highScore.toString(), 'Poin'),
                    ),
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
                      Icons.local_offer_rounded,
                      'Voucher',
                      'Lihat voucher',
                      _showVouchersDialog,
                    ),
                    _buildSettingDivider(),
                    _buildSettingItem(
                      Icons.lock_reset_rounded,
                      'Ganti Password',
                      'Ubah password akun',
                      _showChangePasswordDialog,
                    ),
                    _buildSettingDivider(),
                    _buildSettingItem(
                      Icons.sports_esports_rounded,
                      'Main Dodge Ball',
                      'Mainkan game',
                      () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DodgeBallScreen(),
                          ),
                        );
                        // Refresh stats setelah kembali dari game
                        _loadUserStats();
                      },
                    ),
                    _buildSettingDivider(),
                    _buildSettingItem(
                      Icons.info_rounded,
                      'About Us',
                      'Tentang aplikasi & tim',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutUsScreen(),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
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
