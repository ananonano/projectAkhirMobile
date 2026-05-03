import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_bookings_screen.dart';
import '../screens/admin_field_management_screen.dart';
import '../screens/revenue_report_screen.dart';
import '../screens/login_screen.dart';

enum AdminMenuIndex {
  dashboard,
  bookings,
  venueManager,
  revenue,
  settings,
}

class AdminDrawer extends StatelessWidget {
  final AdminMenuIndex activeMenu;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const AdminDrawer({
    super.key,
    required this.activeMenu,
    required this.scaffoldKey,
  });

  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _navigate(BuildContext context, AdminMenuIndex menu) {
    Navigator.pop(context); // tutup drawer dulu

    if (menu == activeMenu) return; // sudah di halaman ini

    Widget screen;
    switch (menu) {
      case AdminMenuIndex.dashboard:
        screen = const AdminDashboardScreen();
        break;
      case AdminMenuIndex.bookings:
        screen = const AdminBookingsScreen();
        break;
      case AdminMenuIndex.venueManager:
        screen = const AdminFieldManagementScreen(
          activeMenu: AdminMenuIndex.venueManager,
        );
        break;
      case AdminMenuIndex.revenue:
        screen = const RevenueReportScreen();
        break;
      case AdminMenuIndex.settings:
        screen = const AdminFieldManagementScreen(
          activeMenu: AdminMenuIndex.settings,
        );
        break;
    }

    // Ganti seluruh stack admin supaya tidak numpuk
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {
        'label': 'Dashboard',
        'icon': Icons.dashboard_rounded,
        'menu': AdminMenuIndex.dashboard,
      },
      {
        'label': 'Bookings',
        'icon': Icons.event_available_rounded,
        'menu': AdminMenuIndex.bookings,
      },
      {
        'label': 'Venue Manager',
        'icon': Icons.domain_rounded,
        'menu': AdminMenuIndex.venueManager,
      },
      {
        'label': 'Revenue',
        'icon': Icons.trending_up_rounded,
        'menu': AdminMenuIndex.revenue,
      },
      {
        'label': 'Settings',
        'icon': Icons.settings_rounded,
        'menu': AdminMenuIndex.settings,
      },
    ];

    return Drawer(
      backgroundColor: const Color(0xFFFAFAF5),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF6B8F71),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Champion Arena',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isSelected = activeMenu == item['menu'];

                  return GestureDetector(
                    onTap: () =>
                        _navigate(context, item['menu'] as AdminMenuIndex),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6B8F71)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B8F71),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1A1C1A),
                              fontSize: 16,
                              fontFamily: 'Lexend',
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer Logout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E2DC)),
                ),
              ),
              child: GestureDetector(
                onTap: () => _logout(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget header bar admin yang konsisten di semua halaman admin.
/// Berisi hamburger menu (≡) di kiri dan judul halaman.
class AdminHeaderBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget? trailing;

  const AdminHeaderBar({
    super.key,
    required this.title,
    required this.scaffoldKey,
    this.subtitle = 'Champion Arena',
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MediaQuery.of(context)
          .padding
          .copyWith(bottom: 12, left: 0, right: 0),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F1EC),
        border: Border(
          bottom: BorderSide(width: 1, color: Color(0xFFE5E2DC)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hamburger Menu
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => scaffoldKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.menu_rounded,
                    size: 24,
                    color: Color(0xFF6B8F71),
                  ),
                ),
              ),
            ),
            // Title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF6B8F71),
                        fontSize: 16,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF78716C),
                        fontSize: 11,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Trailing widget (opsional, misal tombol logout)
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
