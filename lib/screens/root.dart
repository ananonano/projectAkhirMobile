import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'booking_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'maps_screen.dart';

// Global notifier untuk trigger update profile image
final ValueNotifier<int> profileImageUpdateNotifier = ValueNotifier<int>(0);

// Global notifier untuk trigger refresh home screen setelah rating
final ValueNotifier<int> homeScreenRefreshNotifier = ValueNotifier<int>(0);

// Global notifier untuk trigger refresh recommendations setelah booking
final ValueNotifier<int> recommendationsRefreshNotifier = ValueNotifier<int>(0);

// Global notifier untuk trigger refresh profile stats
final ValueNotifier<int> profileStatsRefreshNotifier = ValueNotifier<int>(0);

// Global notifier untuk trigger refresh booking screen setelah booking baru
final ValueNotifier<int> bookingScreenRefreshNotifier = ValueNotifier<int>(0);

// Global key untuk akses RootScreen dari child screens
final GlobalKey<_RootScreenState> rootScreenKey = GlobalKey<_RootScreenState>();

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String? _profileImagePath;
  int? _selectedLapanganId; // Store selected lapangan ID for Maps screen
  
  // Draggable FAB position
  Offset _fabPosition = const Offset(0, 0); // Will be initialized in build
  bool _fabInitialized = false;
  
  // Animation for magnetic snap
  late AnimationController _fabAnimationController;
  late Animation<Offset> _fabAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animation controller for magnetic snap
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutCubic,
    ))..addListener(() {
      setState(() {
        _fabPosition = _fabAnimation.value;
      });
    });
    
    _loadProfileImage();
    
    // Listen to profile image updates
    profileImageUpdateNotifier.addListener(_onProfileImageUpdated);
  }
  
  // Build screens dynamically to pass parameters
  List<Widget> _buildScreens() {
    return [
      const HomeScreen(),
      MapsScreen(selectedLapanganId: _selectedLapanganId),
      const BookingScreen(),
      const ProfileScreen(),
    ];
  }
  
  // Method to navigate to Maps tab with selected venue
  void navigateToMaps(int lapanganId) {
    print('[RootScreen] navigateToMaps called with ID: $lapanganId');
    setState(() {
      _selectedLapanganId = lapanganId;
      _selectedIndex = 1; // Switch to Maps tab
    });
    print('[RootScreen] Switched to Maps tab with selectedLapanganId: $_selectedLapanganId');
  }
  
  void _onProfileImageUpdated() {
    // Reload profile image when notified
    _loadProfileImage();
  }

  @override
  void dispose() {
    profileImageUpdateNotifier.removeListener(_onProfileImageUpdated);
    WidgetsBinding.instance.removeObserver(this);
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload foto saat app kembali ke foreground
    if (state == AppLifecycleState.resumed) {
      _loadProfileImage();
    }
  }

  // Tarik path gambar dari memori — pakai key per-username biar konsisten sama ProfileScreen
  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String username = prefs.getString('username') ?? '';
    final newImagePath = prefs.getString('profile_image_$username');
    
    if (mounted) {
      setState(() {
        _profileImagePath = newImagePath;
      });
    }
  }

  // Fungsi buat bikin avatar bulat di Bottom Nav (Ala Instagram)
  Widget _buildProfileIcon(bool isActive) {
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      final file = File(_profileImagePath!);
      
      // Cek apakah file exists
      if (file.existsSync()) {
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFFF64E42) : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback ke ikon default jika error
                return const Icon(Icons.person_rounded);
              },
            ),
          ),
        );
      }
    }
    // Ikon default kalau belum upload atau file tidak ada
    return const Icon(Icons.person_rounded);
  }

  @override
  Widget build(BuildContext context) {
    // Initialize FAB position on first build (bottom right with padding)
    if (!_fabInitialized) {
      final screenSize = MediaQuery.of(context).size;
      final bottomNavHeight = 80.0; // Approximate bottom nav height
      _fabPosition = Offset(
        screenSize.width - 72, // 16px padding + 56px button width
        screenSize.height - bottomNavHeight - 72, // Above bottom nav
      );
      _fabInitialized = true;
    }
    
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent navbar from moving when keyboard appears
      body: Stack(
        children: [
          // Main content with bottom navigation
          Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _buildScreens(),
                ),
              ),
              // Bottom Navigation Bar
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, -4))],
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) async {
                    setState(() {
                      // Reset selected lapangan when manually switching tabs
                      if (index != 1) {
                        _selectedLapanganId = null;
                      }
                      _selectedIndex = index;
                    });
                    // Reload foto profil setiap kali pindah tab
                    await _loadProfileImage();
                  },
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.textSecondary,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.map_outlined),
                      activeIcon: Icon(Icons.map_rounded),
                      label: 'Explore',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long_outlined),
                      activeIcon: Icon(Icons.receipt_long_rounded),
                      label: 'History',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildProfileIcon(false),
                      activeIcon: _buildProfileIcon(true),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Draggable Floating Action Button
          Positioned(
            left: _fabPosition.dx,
            top: _fabPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  // Update position while dragging
                  _fabPosition = Offset(
                    _fabPosition.dx + details.delta.dx,
                    _fabPosition.dy + details.delta.dy,
                  );
                });
              },
              onPanEnd: (details) {
                // Snap to edges for better UX (magnetic effect)
                final screenSize = MediaQuery.of(context).size;
                final bottomNavHeight = 80.0;
                
                double newX = _fabPosition.dx;
                double newY = _fabPosition.dy;
                
                const padding = 16.0;
                const fabSize = 56.0;
                
                // MAGNETIC SNAP: Snap to left or right edge based on position
                final screenCenter = screenSize.width / 2;
                if (newX + (fabSize / 2) < screenCenter) {
                  // Closer to left, snap to left edge
                  newX = padding;
                } else {
                  // Closer to right, snap to right edge
                  newX = screenSize.width - fabSize - padding;
                }
                
                // Vertical bounds (avoid bottom nav and status bar)
                final topPadding = MediaQuery.of(context).padding.top + padding;
                final bottomLimit = screenSize.height - bottomNavHeight - fabSize - padding;
                
                if (newY < topPadding) {
                  newY = topPadding;
                } else if (newY > bottomLimit) {
                  newY = bottomLimit;
                }
                
                // Animate to final position
                _fabAnimation = Tween<Offset>(
                  begin: _fabPosition,
                  end: Offset(newX, newY),
                ).animate(CurvedAnimation(
                  parent: _fabAnimationController,
                  curve: Curves.easeOutCubic,
                ))..addListener(() {
                  setState(() {
                    _fabPosition = _fabAnimation.value;
                  });
                });
                
                _fabAnimationController.reset();
                _fabAnimationController.forward();
              },
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primary,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}