import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'booking_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;
  String? _profileImagePath;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // Tarik path gambar dari memori — pakai key per-username biar konsisten sama ProfileScreen
  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String username = prefs.getString('username') ?? '';
    setState(() {
      _profileImagePath = prefs.getString('profile_image_$username');
    });
  }

  // Fungsi buat bikin avatar bulat di Bottom Nav (Ala Instagram)
  Widget _buildProfileIcon(bool isActive) {
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? const Color(0xFFF64E42) : Colors.transparent,
            width: 2,
          ),
          image: DecorationImage(
            image: FileImage(File(_profileImagePath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    // Ikon default kalau belum upload
    return const Icon(Icons.person_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
      ),
      
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            _loadProfileImage();
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
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: _buildProfileIcon(false),
              activeIcon: _buildProfileIcon(true),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}