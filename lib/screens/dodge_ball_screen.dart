import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/voucher_controller.dart';
import '../models/voucher_model.dart';
import 'root.dart'; // Import untuk profileStatsRefreshNotifier

class DodgeBallScreen extends StatefulWidget {
  const DodgeBallScreen({super.key});

  @override
  State<DodgeBallScreen> createState() => _DodgeBallScreenState();
}

class _DodgeBallScreenState extends State<DodgeBallScreen> {
  // --- STATE GAME ---
  double _screenWidth = 0;
  double _screenHeight = 0;

  double _playerX = 0;
  final double _playerYOffset = 120;
  final double _ballSize = 60.0;

  List<Map<String, double>> _enemies = [];
  Timer? _gameTimer;

  // SENSOR 1: Akselerometer
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  // SENSOR 2: Giroskop
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  double _gyroZ = 0.0;
  bool _isTurboMode = false;

  final Random _random = Random();

  double _enemySpeed = 5.0;
  int _score = 0;
  int _highScore = 0;
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isNewBest = false;

  // --- VOUCHER SYSTEM ---
  final VoucherController _voucherController = VoucherController();
  VoucherModel? _earnedVoucher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenWidth == 0) {
      _screenWidth = MediaQuery.of(context).size.width;
      _screenHeight = MediaQuery.of(context).size.height;
      _playerX = (_screenWidth - _ballSize) / 2;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _setupAccelerometer();
    _setupGyroscope();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  // --- LOAD & SAVE HIGH SCORE ---
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'guest';
    setState(() {
      _highScore = prefs.getInt('dodgeball_highscore_$username') ?? 0;
    });
  }

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'guest';
    await prefs.setInt('dodgeball_highscore_$username', score);
    
    // Trigger profile stats refresh after saving new highscore
    profileStatsRefreshNotifier.value++;
    print('[DodgeBall] Triggered profile stats refresh after new highscore: $score');
  }

  // --- SENSOR 1: AKSELEROMETER ---
  void _setupAccelerometer() {
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (_isPlaying && !_isGameOver) {
        setState(() {
          _playerX -= event.x * 2.5;
          if (_playerX < 0) _playerX = 0;
          if (_playerX > _screenWidth - _ballSize) _playerX = _screenWidth - _ballSize;
        });
      }
    });
  }

  // --- SENSOR 2: GIROSKOP ---
  void _setupGyroscope() {
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (_isPlaying && !_isGameOver) {
        setState(() {
          _gyroZ = event.z;
          _isTurboMode = _gyroZ.abs() > 2.0;
        });
      }
    });
  }

  // --- KONTROL TOUCH DRAG (FALLBACK) ---
  void _onPanUpdate(DragUpdateDetails details) {
    if (_isPlaying && !_isGameOver) {
      setState(() {
        _playerX += details.delta.dx;
        if (_playerX < 0) _playerX = 0;
        if (_playerX > _screenWidth - _ballSize) _playerX = _screenWidth - _ballSize;
      });
    }
  }

  // --- LOGIKA GAME ---
  void _startGame() {
    setState(() {
      _score = 0;
      _enemySpeed = 6.0;
      _enemies.clear();
      _isPlaying = true;
      _isGameOver = false;
      _isNewBest = false;
      _playerX = (_screenWidth - _ballSize) / 2;
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
  }

  void _updateGame() {
    if (!mounted) return;
    setState(() {
      for (var enemy in _enemies) {
        enemy['y'] = enemy['y']! + _enemySpeed;
      }

      int scorePerBall = _isTurboMode ? 20 : 10;
      _enemies.removeWhere((enemy) {
        if (enemy['y']! > _screenHeight) {
          _score += scorePerBall;
          if (_score % 100 == 0) _enemySpeed += 1.2;
          return true;
        }
        return false;
      });

      double baseSpawnRate = 0.03 + (_score * 0.0001);
      double spawnRate = _isTurboMode ? baseSpawnRate * 2.0 : baseSpawnRate;
      if (_random.nextDouble() < spawnRate) {
        _enemies.add({
          'x': _random.nextDouble() * (_screenWidth - _ballSize),
          'y': -_ballSize,
        });
      }

      double playerHitboxY = _screenHeight - _playerYOffset;
      Rect playerRect = Rect.fromLTWH(_playerX, playerHitboxY, _ballSize, _ballSize);

      for (var enemy in _enemies) {
        Rect enemyRect = Rect.fromLTWH(enemy['x']!, enemy['y']!, _ballSize, _ballSize);
        if (playerRect.deflate(12).overlaps(enemyRect.deflate(12))) {
          _gameOver();
          break;
        }
      }
    });
  }

  void _gameOver() async {
    _gameTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
      if (_score > _highScore) {
        _highScore = _score;
        _isNewBest = true;
        _saveHighScore(_highScore);
      }
    });

    // Award voucher if score is high enough
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? 'guest';
      
      final voucher = await _voucherController.awardVoucherFromDodgeBall(username, _score);
      if (mounted && voucher != null) {
        setState(() => _earnedVoucher = voucher);
        _showVoucherRewardDialog(voucher);
      }
    } catch (e) {
      print('[DodgeBall] Error awarding voucher: $e');
    }
  }

  void _showVoucherRewardDialog(VoucherModel voucher) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Voucher Reward!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              '${voucher.percentDiscount}% OFF',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: ${voucher.earnedScore}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Voucher ini bisa digunakan 1x saat booking',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  // --- CUSTOM WIDGET BOLA ---
  Widget _buildBall({required Color color, required IconData iconData}) {
    return Container(
      width: _ballSize,
      height: _ballSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Center(
        child: Icon(iconData, color: Colors.white.withOpacity(0.8), size: _ballSize * 0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: GestureDetector(
        onPanUpdate: _onPanUpdate,
        child: Stack(
          children: [
            // Background grid
            CustomPaint(
              size: Size(_screenWidth, _screenHeight),
              painter: GridPainter(),
            ),

            // Bola musuh
            ..._enemies.map((enemy) {
              return Positioned(
                left: enemy['x'],
                top: enemy['y'],
                child: _buildBall(color: Colors.orange, iconData: Icons.sports_basketball_rounded),
              );
            }),

            // Bola player
            if (_isPlaying || !_isGameOver)
              Positioned(
                left: _playerX,
                bottom: _playerYOffset - _ballSize,
                child: _buildBall(color: Colors.blueAccent, iconData: Icons.sports_soccer_rounded),
              ),

            // Score real-time
            if (_isPlaying)
              Positioned(
                top: 60,
                width: _screenWidth,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        _score.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Courier',
                          shadows: [Shadow(color: Colors.blueAccent, blurRadius: 20)],
                        ),
                      ),
                      if (_isTurboMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 10)],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.rotate_right, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('⚡ TURBO MODE — 2x SCORE!',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Start menu & game over overlay
            if (!_isPlaying)
              Container(
                color: Colors.black.withOpacity(0.7),
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_volleyball_rounded, size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Text(
                      _isGameOver ? "GAME OVER" : "DODGE BALL",
                      style: const TextStyle(
                          color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 10),
                    if (_isGameOver) ...[
                      Text("Score: $_score",
                          style: const TextStyle(color: Colors.white70, fontSize: 24)),
                      const SizedBox(height: 8),
                      if (_earnedVoucher != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            border: Border.all(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Text('🎉 Voucher Earned!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('${_earnedVoucher!.percentDiscount}% OFF', style: const TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Best: $_highScore",
                              style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          if (_isNewBest) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text("NEW BEST!",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      const Text(
                        "Miringin HP → gerak kiri/kanan\nPutar HP → TURBO MODE (2x score!)\natau Swipe Layar buat gerak!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 10,
                        shadowColor: Colors.blueAccent.withOpacity(0.5),
                      ),
                      child: Text(
                        _isGameOver ? "PLAY AGAIN" : "START GAME",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Kembali ke Lapang.in",
                          style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Background grid painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
