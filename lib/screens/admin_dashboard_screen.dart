import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/lapangan_controller.dart';
import '../models/lapangan_model.dart';
import '../theme/app_theme.dart';
import '../repositories/booking_repository.dart';
import '../repositories/review_repository.dart';
import 'admin_bookings_screen.dart';
import 'login_screen.dart';
import '../widgets/admin_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late BookingRepository _bookingRepo;
  late ReviewRepository _reviewRepo;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  int _bookingsToday = 0;
  double _revenueToday = 0;
  int _activeFields = 0;
  List<Map<String, dynamic>> _recentBookings = [];
  List<Map<String, dynamic>> _recentReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('[DASHBOARD INIT] Starting initialization...');
    try {
      _bookingRepo = BookingRepository();
      _reviewRepo = ReviewRepository();
      print('[DASHBOARD INIT] Repositories initialized');
      _loadDashboardData();
      print('[DASHBOARD INIT] _loadDashboardData() called');
    } catch (e) {
      print('[DASHBOARD INIT] Error in initState: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Load all bookings and filter for today
      final allBookings = await _bookingRepo.getAllBookings();
      print('[DEBUG DASHBOARD] Total bookings loaded: ${allBookings.length}');
      
      final todayDate = DateTime.now();
      // Database uses "dd MMM yyyy" format like "04 May 2026"
      final todayDateStr = DateFormat('dd MMM yyyy').format(todayDate);
      
      print('[DEBUG DASHBOARD] Today date: $todayDateStr');
      print('[DEBUG DASHBOARD] All booking dates:');
      for (var b in allBookings) {
        print('[DEBUG DASHBOARD] - ${b['tanggal']} | ${b['nama_lapangan']} | ${b['status']}');
      }
      
      final bookingsToday = allBookings
          .where((b) => (b['tanggal'] ?? '').toString() == todayDateStr)
          .toList();
      
      print('[DEBUG DASHBOARD] Bookings today count: ${bookingsToday.length}');
      
      _bookingsToday = bookingsToday.length;
      
      // Calculate revenue today - handle String, int, and double types
      _revenueToday = 0;
      for (var b in bookingsToday) {
        final hargaRaw = b['total_harga'];
        double harga = 0;
        
        if (hargaRaw is String) {
          // Remove "Rp" and dots, then parse
          final cleanStr = hargaRaw.replaceAll('Rp', '').replaceAll('.', '').replaceAll(',', '').trim();
          harga = double.tryParse(cleanStr) ?? 0;
        } else if (hargaRaw is int) {
          harga = hargaRaw.toDouble();
        } else if (hargaRaw is double) {
          harga = hargaRaw;
        }
        
        _revenueToday += harga;
        print('[DEBUG DASHBOARD] Booking revenue: $hargaRaw -> $harga');
      }
      
      print('[DEBUG DASHBOARD] Total revenue today: $_revenueToday');

      // Load active fields count
      final activeFieldIds = <int>{};
      for (var booking in allBookings) {
        activeFieldIds.add(booking['lapangan_id'] ?? 0);
      }
      _activeFields = activeFieldIds.length;

      // Get recent bookings (all bookings) sorted by newest first (by ID)
      _recentBookings = List.from(allBookings);
      
      print('[DEBUG DASHBOARD] Recent bookings before sorting: ${_recentBookings.length}');
      
      // Sort by ID (newest first - higher ID = more recent)
      _recentBookings.sort((a, b) {
        final idA = a['id'] ?? 0;
        final idB = b['id'] ?? 0;
        return idB.compareTo(idA); // Descending order (newest first)
      });
      
      // Take only top 5 for dashboard
      _recentBookings = _recentBookings.take(5).toList();
      print('[DEBUG DASHBOARD] Final recent bookings (top 5): ${_recentBookings.length}');
      for (var b in _recentBookings) {
        print('[DEBUG DASHBOARD] - ID: ${b['id']} | ${b['nama_lapangan']} on ${b['tanggal']} at ${b['jam']}');
      }

      // For reviews, load all recent reviews from all lapangans
      _recentReviews = [];
      try {
        print('[DEBUG DASHBOARD] About to call getAllRecentReviews...');
        _recentReviews = await _reviewRepo.getAllRecentReviews(limit: 5);
        print('[DEBUG DASHBOARD] Recent reviews loaded: ${_recentReviews.length}');
        for (var review in _recentReviews) {
          print('[DEBUG DASHBOARD] - ${review['user_name']} rated ${review['lapangan_name']}: ${review['rating']} stars');
        }
      } catch (e) {
        print('[ERROR DASHBOARD] Error loading recent reviews: $e');
        _recentReviews = [];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('[ERROR DASHBOARD] Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAF5),
      drawer: AdminDrawer(
        activeMenu: AdminMenuIndex.dashboard,
        scaffoldKey: _scaffoldKey,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Stack(
              children: [
                // Scrollable Content
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 70, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Cards
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 55, bottom: 24),
                        child: Column(
                          spacing: 12,
                          children: [
                            // Revenue Today - Full Width Compact
                            _StatCard(
                              title: 'REVENUE\nTODAY',
                              value: 'Rp ${NumberFormat('#,###').format(_revenueToday.toInt())}',
                              icon: Icons.trending_up_rounded,
                            ),
                            // Bookings & Venue Status Side by Side
                            SizedBox(
                              height: 120,
                              child: Row(
                                spacing: 12,
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      title: 'BOOKINGS\nTODAY',
                                      value: _bookingsToday.toString(),
                                      icon: Icons.event_available_rounded,
                                    ),
                                  ),
                                  Expanded(
                                    child: _StatCardGreen(
                                      title: 'ACTIVE\nFIELDS',
                                      value: _activeFields.toString(),
                                      subtitle: 'Venue locations',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Recent Bookings
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Bookings',
                                  style: TextStyle(
                                    color: Color(0xFF1A1C1A),
                                    fontSize: 18,
                                    fontFamily: 'Lexend',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AdminBookingsScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'View History',
                                    style: TextStyle(
                                      color: Color(0xFF6B8F71),
                                      fontSize: 14,
                                      fontFamily: 'Lexend',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_recentBookings.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E2DC),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No recent bookings',
                                    style: TextStyle(
                                      color: Color(0xFF78716C),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Column(
                                spacing: 8,
                                children: _recentBookings.map((booking) {
                                  return _BookingCard(booking: booking);
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Recent Reviews
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent Reviews',
                              style: TextStyle(
                                color: Color(0xFF1A1C1A),
                                fontSize: 18,
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_recentReviews.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E2DC),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No reviews yet',
                                    style: TextStyle(
                                      color: Color(0xFF78716C),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Column(
                                spacing: 12,
                                children: _recentReviews.map((review) {
                                  return _ReviewCard(review: review);
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                // Fixed Header Bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: MediaQuery.of(context).padding.copyWith(bottom: 12, left: 0, right: 0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F1EC),
                      border: Border(
                        bottom: BorderSide(
                          width: 1,
                          color: Color(0xFFE5E2DC),
                        ),
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
                              onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
                                  const Text(
                                    'Venue Dashboard',
                                    style: TextStyle(
                                      color: Color(0xFF6B8F71),
                                      fontSize: 16,
                                      fontFamily: 'Lexend',
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Champion Arena',
                                    style: TextStyle(
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
                          // Profile Button
                          InkWell(
                            onTap: _logout,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B8F71),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 18,
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E2DC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6B8F71).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF6B8F71), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF78716C),
                    fontSize: 11,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    height: 1.30,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1A1C1A),
                    fontSize: 24,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.32,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardGreen extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _StatCardGreen({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF6B8F71),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.domain, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    height: 1.30,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.32,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _BookingCard({required this.booking});

  String _getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('pending') || lowerStatus.contains('waiting')) {
      return '0xFFFF9800';
    } else if (lowerStatus.contains('confirm') || lowerStatus.contains('terbayar') || lowerStatus.contains('paid')) {
      return '0xFF6B8F71';
    } else if (lowerStatus.contains('progress')) {
      return '0xFF2196F3';
    } else if (lowerStatus.contains('complete') || lowerStatus.contains('selesai')) {
      return '0xFF4CAF50';
    } else if (lowerStatus.contains('cancel')) {
      return '0xFFE74C3C';
    }
    return '0xFF78716C';
  }

  @override
  Widget build(BuildContext context) {
    final lapanganName = booking['nama_lapangan'] ?? 'Field ${booking['lapangan_id']}';
    final timeSlot = booking['jam'] ?? 'N/A';
    final bookingDate = booking['tanggal'] ?? 'N/A';
    final bookedBy = booking['user_id']?.toString() ?? booking['nama_pemesan'] ?? 'Unknown';
    final status = booking['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final gambar = booking['gambar'] as String?;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E2DC)),
      ),
      child: Row(
        children: [
          // Gambar lapangan di sebelah kiri
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF4F1EC),
              image: gambar != null && gambar.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(gambar),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {},
                    )
                  : null,
            ),
            child: gambar == null || gambar.isEmpty
                ? const Icon(Icons.sports_soccer, color: Color(0xFF6B8F71), size: 32)
                : null,
          ),
          const SizedBox(width: 12),
          // Info lapangan di tengah
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lapanganName,
                  style: const TextStyle(
                    color: Color(0xFF1A1C1A),
                    fontSize: 14,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$bookingDate • $timeSlot',
                  style: const TextStyle(
                    color: Color(0xFF78716C),
                    fontSize: 12,
                    fontFamily: 'Lexend',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Booked by: $bookedBy',
                  style: const TextStyle(
                    color: Color(0xFF78716C),
                    fontSize: 11,
                    fontFamily: 'Lexend',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status badge di sebelah kanan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(int.parse(statusColor)).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Color(int.parse(statusColor)).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: Color(int.parse(statusColor)),
                fontSize: 10,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] ?? 0;
    final userName = review['user_name'] ?? 'User';
    final lapanganName = review['lapangan_name'] ?? 'Lapangan';
    final comment = review['comment'] ?? 'No comment';
    final createdAt = review['created_at'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E2DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          // Header: User name and Rating stars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Color(0xFF1A1C1A),
                        fontSize: 13,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      lapanganName,
                      style: const TextStyle(
                        color: Color(0xFF78716C),
                        fontSize: 11,
                        fontFamily: 'Lexend',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star_rounded,
                    color: index < rating
                        ? const Color(0xFFFFB800)
                        : const Color(0xFFE5E2DC),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          // Comment
          if (comment.isNotEmpty)
            Text(
              comment,
              style: const TextStyle(
                color: Color(0xFF78716C),
                fontSize: 12,
                fontFamily: 'Lexend',
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          // Date
          if (createdAt.isNotEmpty)
            Text(
              _formatDate(createdAt),
              style: const TextStyle(
                color: Color(0xFFB8B5AC),
                fontSize: 10,
                fontFamily: 'Lexend',
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

// ==========================================
// FORM LAPANGAN SCREEN - ADD/EDIT FIELDS
// ==========================================
class FormLapanganScreen extends StatefulWidget {
  final LapanganModel? lapangan;
  const FormLapanganScreen({super.key, this.lapangan});

  @override
  State<FormLapanganScreen> createState() => _FormLapanganScreenState();
}

class _FormLapanganScreenState extends State<FormLapanganScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final LapanganController _controller = LapanganController();

  String _selectedJenis = 'FUTSAL';
  final List<String> _jenisOptions = ['FUTSAL', 'BASKETBALL', 'BADMINTON', 'MINI_SOCCER', 'TENNIS'];
  final List<String> _selectedImagePaths = [];

  @override
  void initState() {
    super.initState();
    if (widget.lapangan != null) {
      _namaController.text = widget.lapangan!.namaLapangan;
      _descController.text = widget.lapangan!.description ?? '';
      _hargaController.text = widget.lapangan!.harga.toString();
      _alamatController.text = widget.lapangan!.address ?? '';
      _latController.text = widget.lapangan!.lat.toString();
      _lngController.text = widget.lapangan!.lng.toString();
      _selectedJenis = widget.lapangan!.jenis;
      if ((widget.lapangan!.image ?? '').isNotEmpty) {
        _selectedImagePaths.addAll((widget.lapangan!.image ?? '').split(','));
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _descController.dispose();
    _hargaController.dispose();
    _alamatController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImagePaths.addAll(images.map((img) => img.path).toList());
      });
    }
  }

  Future<void> _simpanLapangan() async {
    if (_namaController.text.isEmpty || _hargaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Harga wajib diisi bre!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final lapangan = LapanganModel(
      id: widget.lapangan?.id,
      namaLapangan: _namaController.text,
      description: _descController.text,
      image: _selectedImagePaths.join(','),
      jenis: _selectedJenis,
      harga: int.tryParse(_hargaController.text) ?? 0,
      capacity: 10,
      address: _alamatController.text,
      lat: double.tryParse(_latController.text) ?? 0.0,
      lng: double.tryParse(_lngController.text) ?? 0.0,
    );

    if (widget.lapangan == null) {
      await _controller.addLapangan(lapangan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mantap! Lapangan berhasil ditambahkan.'), backgroundColor: Colors.green),
        );
      }
    } else {
      await _controller.updateLapangan(lapangan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mantap! Lapangan berhasil diperbarui.'), backgroundColor: Colors.green),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type, int maxLines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.lapangan == null ? 'Tambah Lapangan' : 'Edit Lapangan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Foto Lapangan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            if (_selectedImagePaths.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImagePaths.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _selectedImagePaths[index].startsWith('http')
                                ? Image.network(_selectedImagePaths[index], width: 120, height: 120, fit: BoxFit.cover)
                                : Image.file(File(_selectedImagePaths[index]), width: 120, height: 120, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImagePaths.removeAt(index)),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickMultipleImages,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Pilih Foto dari Galeri', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_namaController, 'Nama Lapangan', TextInputType.text, 1),
            _buildTextField(_descController, 'Deskripsi', TextInputType.multiline, 3),
            DropdownButtonFormField<String>(
              value: _selectedJenis,
              decoration: const InputDecoration(labelText: 'Jenis Olahraga'),
              items: _jenisOptions
                  .map((val) => DropdownMenuItem(value: val, child: Text(val.replaceAll('_', ' '))))
                  .toList(),
              onChanged: (newVal) => setState(() => _selectedJenis = newVal!),
            ),
            const SizedBox(height: 16),
            _buildTextField(_hargaController, 'Harga per Jam (Rp)', TextInputType.number, 1),
            _buildTextField(_alamatController, 'Alamat Lengkap', TextInputType.text, 2),
            Row(
              children: [
                Expanded(child: _buildTextField(_latController, 'Latitude', TextInputType.number, 1)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_lngController, 'Longitude', TextInputType.number, 1)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _simpanLapangan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  widget.lapangan == null ? 'Tambah Lapangan' : 'Perbarui Lapangan',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
