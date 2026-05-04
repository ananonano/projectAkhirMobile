import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/booking_controller.dart';
import '../repositories/review_repository.dart';
import '../repositories/lapangan_image_repository.dart';
import '../models/review_model.dart';
import '../database/database.dart';
import 'payment_screen.dart';
import 'edit_lapangan_images_screen.dart';
import 'root.dart';

class DetailLapanganScreen extends StatefulWidget {
  final Map<String, dynamic> lapangan;

  const DetailLapanganScreen({super.key, required this.lapangan});

  @override
  State<DetailLapanganScreen> createState() => _DetailLapanganScreenState();
}

class _DetailLapanganScreenState extends State<DetailLapanganScreen> {
  // --- STATE SLIDER GAMBAR ---
  int _currentImageIndex = 0;
  List<String> _imagePaths = [];
  final PageController _pageController = PageController();

  final BookingController _bookingController = BookingController();
  final ReviewRepository _reviewRepository = ReviewRepository();
  final LapanganImageRepository _imageRepository = LapanganImageRepository();

  // --- STATE BOOKING (JADWAL & JAM) ---
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedTimes = [];
  late List<String> _availableTimes;
  List<String> _bookedTimes = []; // Jam yang udah dipesen orang lain
  bool _isLoadingJadwal = false;

  // --- STATE REVIEWS ---
  List<Review> _reviews = [];
  double _averageRating = 0.0;
  int _reviewCount = 0;
  bool _isLoadingReviews = false;
  Review? _userReview;

  @override
  void initState() {
    super.initState();
    _loadImagesFromDatabase();
    // Generate available times berdasarkan jam_buka dan jam_tutup
    _generateAvailableTimesFromLapangan();
    // Fetch booked times segera tapi don't block UI
    _loadBookedTimes();
    // Load reviews and ratings
    _loadReviews();
  }

  void _generateAvailableTimesFromLapangan() {
    try {
      // Extract jam_buka dan jam_tutup dari lapangan data
      String jamBuka = widget.lapangan['jam_buka'] ?? '08:00';
      String jamTutup = widget.lapangan['jam_tutup'] ?? '22:00';
      
      // Parse jam buka (format: "HH:MM")
      int startHour = int.parse(jamBuka.split(':')[0]);
      int endHour = int.parse(jamTutup.split(':')[0]);
      
      // Generate list jam tersedia
      List<String> times = [];
      for (int hour = startHour; hour < endHour; hour++) {
        times.add('${hour.toString().padLeft(2, '0')}:00');
      }
      
      _availableTimes = times;
      print('[DEBUG] Available times generated: $startHour - $endHour | Times: $_availableTimes');
    } catch (e) {
      print('[ERROR] Error parsing opening hours: $e');
      // Fallback ke default 08:00-22:00
      _availableTimes = List.generate(
        15,
        (index) => '${(index + 8).toString().padLeft(2, '0')}:00',
      );
    }
  }

  Future<void> _loadBookedTimes() async {
    try {
      await _fetchBookedTimes();
    } catch (e) {
      print('Error loading booked times in init: $e');
      if (mounted) {
        setState(() {
          _isLoadingJadwal = false;
          _bookedTimes = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadImagesFromDatabase() async {
    final lapanganId = widget.lapangan['id'];
    if (lapanganId == null) {
      _parseImages(); // Fallback ke metode lama jika tidak ada ID
      return;
    }

    // Load dari lapangan_images table
    final images = await _imageRepository.getImagesByLapangan(lapanganId);
    if (images.isNotEmpty) {
      setState(() {
        _imagePaths = images.map((img) => img.imagePath).toList();
      });
      print('[DetailScreen] Loaded ${_imagePaths.length} images from database');
    } else {
      // Fallback ke image field dari lapangan jika tidak ada di lapangan_images
      _parseImages();
    }
  }

  void _parseImages() {
    String rawImages = widget.lapangan['image'] ?? '';
    if (rawImages.isNotEmpty) {
      _imagePaths = rawImages.split(',').map((e) => e.trim()).toList();
    }
  }

  bool _isTimePassed(String timeStr) {
    final now = DateTime.now();
    final selectedDateToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    if (!selectedDateToday) return false;
    try {
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final timeDate = DateTime(now.year, now.month, now.day, hour, minute);
      return timeDate.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  Future<void> _selectDateFromPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF597D60),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimes.clear();
      });
      await _fetchBookedTimes();
    }
  }

  Future<void> _fetchBookedTimes() async {
    if (!mounted) return;

    if (mounted) {
      setState(() => _isLoadingJadwal = true);
    }
    
    try {
      // PERBAIKAN: Parsing ID secara eksplisit ke int untuk mencegah crash
      int lapanganId = int.tryParse(widget.lapangan['id']?.toString() ?? '0') ?? 0;
      
      print('[DEBUG] Fetching booked times for lapanganId: $lapanganId, date: $_selectedDate');
      
      if (lapanganId == 0) {
        print('[DEBUG] Invalid lapangan ID - lapangan data: ${widget.lapangan}');
        if (mounted) {
          setState(() {
            _isLoadingJadwal = false;
            _bookedTimes = [];
          });
        }
        return;
      }
      
      final booked = await _bookingController.getBookedTimes(
        lapanganId,
        _selectedDate,
      );
      
      print('[DEBUG] Booked times received: $booked');
      
      if (mounted) {
        setState(() {
          _bookedTimes = booked ?? [];
          _isLoadingJadwal = false;
          _selectedTimes.clear();
        });
      }
    } catch (e, stackTrace) {
      print('[ERROR] Error in _fetchBookedTimes: $e');
      print('[ERROR] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _bookedTimes = [];
          _isLoadingJadwal = false;
        });
      }
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    
    setState(() => _isLoadingReviews = true);
    
    try {
      int lapanganId = int.tryParse(widget.lapangan['id']?.toString() ?? '0') ?? 0;
      if (lapanganId == 0) {
        print('[ReviewScreen] Invalid lapangan ID');
        return;
      }

      final reviews = await _reviewRepository.getReviewsByLapangan(lapanganId);
      final avgRating = await _reviewRepository.getAverageRating(lapanganId);
      final reviewCount = await _reviewRepository.getReviewCount(lapanganId);
      
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = avgRating;
          _reviewCount = reviewCount;
          _isLoadingReviews = false;
        });
      }
      
      print('[ReviewScreen] Loaded ${reviews.length} reviews, avg rating: $avgRating');
    } catch (e) {
      print('[ReviewScreen] Error loading reviews: $e');
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  void _showRatingDialog() {
    int selectedRating = 5;
    TextEditingController commentController = TextEditingController(
      text: _userReview?.comment ?? '',
    );
    selectedRating = _userReview?.rating ?? 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Beri Rating & Ulasan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rating:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedRating = index + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          index < selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFF597D60),
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Komentar (opsional):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Bagikan pengalaman Anda...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF597D60),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitReview(selectedRating, commentController.text);
              },
              child: const Text(
                'Kirim',
                style: TextStyle(color: Color(0xFF597D60)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(int rating, String comment) async {
    try {
      int lapanganId = int.tryParse(widget.lapangan['id']?.toString() ?? '0') ?? 0;
      
      // Get current logged-in user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      
      if (username == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Silakan login terlebih dahulu')),
        );
        return;
      }
      
      // Get user data from database
      final userData = await DatabaseHelper.instance.getUserByUsername(username);
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User tidak ditemukan')),
        );
        return;
      }
      
      int userId = userData['id'] as int;
      
      if (lapanganId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Lapangan tidak valid')),
        );
        return;
      }

      final review = Review(
        id: _userReview?.id,
        userId: userId,
        lapanganId: lapanganId,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
      );

      if (_userReview == null) {
        // Add new review
        await _reviewRepository.addReview(review);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan berhasil ditambahkan!')),
        );
      } else {
        // Update existing review
        await _reviewRepository.updateReview(review);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan berhasil diperbarui!')),
        );
      }

      // Reload reviews
      await _loadReviews();
      
      // Trigger home screen refresh
      homeScreenRefreshNotifier.value++;
      print('[DetailScreen] Triggered home screen refresh after review submission');
    } catch (e) {
      print('[ReviewScreen] Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  IconData _getSportIcon(String sportKey) {
    switch (sportKey.toUpperCase()) {
      case 'FUTSAL':
        return Icons.sports_soccer_rounded;
      case 'BASKETBALL':
        return Icons.sports_basketball_rounded;
      case 'BADMINTON':
        return Icons.sports_tennis_rounded; // Changed to tennis icon
      case 'TENNIS':
        return Icons.sports_baseball_rounded; // Changed to baseball icon
      case 'MINI_SOCCER':
        return Icons.sports_soccer_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star_rounded
              : (index < rating
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded),
          color: const Color(0xFF597D60),
          size: 18,
        );
      }),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (review.userImage != null && review.userImage!.isNotEmpty)
                CircleAvatar(
                  radius: 18,
                  backgroundImage: review.userImage!.startsWith('http')
                      ? NetworkImage(review.userImage!) as ImageProvider
                      : FileImage(File(review.userImage!)),
                  onBackgroundImageError: (_, __) {},
                )
              else
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF597D60).withOpacity(0.2),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF597D60),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStarRating(review.rating.toDouble()),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (review.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy', 'id_ID').format(
                DateTime.parse(review.createdAt!),
              ),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rating & Ulasan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStarRating(_averageRating),
                      const SizedBox(width: 8),
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($_reviewCount ulasan)',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showRatingDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF597D60).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Color(0xFF597D60),
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Rating',
                        style: TextStyle(
                          color: Color(0xFF597D60),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingReviews)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF597D60),
              ),
            )
          else if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Belum ada ulasan. Jadilah yang pertama!',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Column(
              children: _reviews
                  .map((review) => _buildReviewItem(review))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Gambar tidak tersedia',
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFasilitasCard(IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFE5E2DC)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 7,
        children: [
          Icon(icon, size: 28, color: const Color(0xFF597D60)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A1C1A),
              fontSize: 13,
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFasilitasCards() {
    return Column(
      children: [
        _buildFasilitasCard(Icons.wc_rounded, 'Toilet'),
        const SizedBox(height: 12),
        _buildFasilitasCard(Icons.local_parking_rounded, 'Parkir'),
        const SizedBox(height: 12),
        _buildFasilitasCard(Icons.wifi_rounded, 'WiFi'),
        const SizedBox(height: 12),
        _buildFasilitasCard(Icons.stars_rounded, 'Kualitas'),
      ],
    );
  }

  Widget _buildMapPreview() {
    // Get coordinates from lapangan data
    double lat = double.tryParse(widget.lapangan['lat']?.toString() ?? '-7.797068') ?? -7.797068;
    double lng = double.tryParse(widget.lapangan['lng']?.toString() ?? '110.370529') ?? 110.370529;
    String address = widget.lapangan['address'] ?? 'Alamat tidak tersedia';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map Container
        Container(
          width: double.infinity,
          height: 216,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 1,
                color: Color(0xFFE5E2DC),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none, // Disable interactions in preview
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.projectakhir',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF597D60),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Address
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: Color(0xFF597D60),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(
                  color: Color(0xFF1A1C1A),
                  fontSize: 14,
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      bool hasImages = _imagePaths.isNotEmpty;
      final currencyFormat = NumberFormat.currency(
        locale: 'id',
        symbol: 'Rp ',
        decimalDigits: 0,
      );

      int hargaPerJam = int.tryParse(widget.lapangan['harga']?.toString() ?? '0') ?? 0;
      int totalHarga = _selectedTimes.isEmpty
          ? hargaPerJam
          : (hargaPerJam * _selectedTimes.length);

      int bookedCount = _bookedTimes.length;
      int totalSlots = _availableTimes.length;
      double filledPercentage = totalSlots > 0 ? bookedCount / totalSlots : 0;

      return Scaffold(
        backgroundColor: const Color(0xFFFAFAF5),
        body: Stack(
          children: [
            // Scrollable content (Image + Main content)
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 80, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  SizedBox(
                    height: 334,
                    child: Stack(
                      children: [
                        hasImages
                            ? PageView.builder(
                                controller: _pageController,
                                itemCount: _imagePaths.length,
                                onPageChanged: (index) =>
                                    setState(() => _currentImageIndex = index),
                                itemBuilder: (context, index) =>
                                    _buildImageProvider(_imagePaths[index]),
                              )
                            : _buildPlaceholder(),
                        // Gradient overlay
                        Positioned(
                          left: 0,
                          top: 222,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Indicator dots
                        if (hasImages && _imagePaths.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_imagePaths.length, (index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentImageIndex == index ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Main Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 40,
                      children: [
                        // Title + Badge + Rating
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                widget.lapangan['nama_lapangan'] ?? 'Gelora Futsal',
                                style: const TextStyle(
                                  color: Color(0xFF1A1C1A),
                                  fontSize: 32,
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              letterSpacing: -0.32,
                            ),
                          ),
                        ),
                            Row(
                              spacing: 8,
                              children: [
                                // Sport Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF6B8F71).withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 4,
                                    children: [
                                      Icon(
                                        _getSportIcon(widget.lapangan['jenis'] ?? 'FUTSAL'),
                                        size: 14,
                                        color: const Color(0xFF6B8F71),
                                      ),
                                      Text(
                                        (widget.lapangan['jenis'] ?? 'Futsal')
                                            .toString()
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF6B8F71),
                                          fontSize: 10,
                                          fontFamily: 'Lexend',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Rating
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 2,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: const Color(0xFF416448),
                                    ),
                                    Text(
                                      _averageRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Color(0xFF416448),
                                        fontSize: 12,
                                        fontFamily: 'Lexend',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Fasilitas Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 24,
                          children: [
                            Text(
                              'Fasilitas',
                              style: const TextStyle(
                                color: Color(0xFF1A1C1A),
                                fontSize: 24,
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.w400,
                                height: 1.3,
                              ),
                            ),
                            _buildFasilitasCards(),
                          ],
                        ),

                        // Lokasi Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Lokasi',
                                  style: const TextStyle(
                                    color: Color(0xFF1A1C1A),
                                    fontSize: 24,
                                    fontFamily: 'Lexend',
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to Maps tab with this venue highlighted
                                    final lapanganId = int.tryParse(widget.lapangan['id']?.toString() ?? '0');
                                    print('[DetailScreen] Lihat Peta tapped, lapanganId: $lapanganId');
                                    if (lapanganId != null && lapanganId > 0) {
                                      // Pop back to root screen
                                      Navigator.pop(context);
                                      print('[DetailScreen] Popped, calling navigateToMaps...');
                                      // Navigate to Maps tab with selected venue
                                      rootScreenKey.currentState?.navigateToMaps(lapanganId);
                                    } else {
                                      print('[DetailScreen] ERROR: Invalid lapangan ID');
                                    }
                                  },
                                  child: const Text(
                                    'Lihat Peta',
                                    style: TextStyle(
                                      color: Color(0xFF597D60),
                                      fontSize: 14,
                                      fontFamily: 'Lexend',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _buildMapPreview(),
                          ],
                        ),

                        // Pilih Jadwal Main Section  
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 20,
                          children: [
                            Text(
                              'Pilih Jadwal Main',
                              style: const TextStyle(
                                color: Color(0xFF1A1C1A),
                                fontSize: 24,
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            // Date Selector
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 10,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tanggal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _selectDateFromPicker,
                                      icon: const Icon(
                                        Icons.calendar_today_rounded,
                                        color: Color(0xFF597D60),
                                        size: 22,
                                      ),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 31,
                                    itemBuilder: (context, index) {
                                      DateTime date = DateTime.now().add(
                                        Duration(days: index),
                                      );
                                      bool isSelected =
                                          _selectedDate.day == date.day &&
                                          _selectedDate.month == date.month;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedDate = date;
                                            _selectedTimes.clear();
                                          });
                                          _fetchBookedTimes();
                                        },
                                        child: Container(
                                          width: 65,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF597D60)
                                                : Colors.white,
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF597D60)
                                                  : Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                DateFormat('EEE').format(date),
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('dd').format(date),
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // Jam Tersedia
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 10,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Jam Tersedia',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${_bookedTimes.length} dari ${_availableTimes.length} terisi',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF424842),
                                      ),
                                    ),
                                  ],
                                ),
                                // Occupancy Progress Bar
                                Container(
                                  width: double.infinity,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F1EC),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Stack(
                                    children: [
                                      if (filledPercentage > 0)
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: (MediaQuery.of(context).size.width - 48) *
                                                filledPercentage,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF416448),
                                              borderRadius: BorderRadius.circular(9999),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (_isLoadingJadwal)
                                  Container(
                                    width: double.infinity,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF597D60),
                                      ),
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: _availableTimes.map((time) {
                                      bool isBooked = _bookedTimes.contains(time);
                                      bool isPassed = _isTimePassed(time);
                                      bool isSelected = _selectedTimes.contains(time);
                                      bool isDisabled = isBooked || isPassed;

                                      return GestureDetector(
                                        onTap: isDisabled
                                            ? null
                                            : () {
                                                setState(() {
                                                  if (isSelected) {
                                                    _selectedTimes.remove(time);
                                                  } else {
                                                    _selectedTimes.add(time);
                                                  }
                                                });
                                              },
                                        child: Container(
                                          width: (MediaQuery.of(context).size.width - 68) / 3,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isDisabled
                                                ? Colors.grey[200]
                                                : (isSelected
                                                      ? const Color(0xFF597D60)
                                                      : Colors.white),
                                            border: Border.all(
                                              color: isDisabled
                                                  ? Colors.transparent
                                                  : (isSelected
                                                        ? const Color(0xFF597D60)
                                                        : Colors.grey.shade300),
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              time,
                                              style: TextStyle(
                                                color: isDisabled
                                                    ? Colors.grey[400]
                                                    : (isSelected
                                                          ? Colors.white
                                                          : Colors.black87),
                                                fontWeight: FontWeight.bold,
                                                decoration: isDisabled
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Rating & Ulasan Section
                        _buildReviewsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Fixed Header Bar (Full Top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: MediaQuery.of(context).padding.copyWith(bottom: 16, left: 0, right: 0),
                decoration: const ShapeDecoration(
                  color: Color(0xFFF4F1EC),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: Color(0xFFE5E2DC),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF597D60),
                              size: 20,
                            ),
                          ),
                          Text(
                            'Jakarta, ID',
                            style: const TextStyle(
                              color: Color(0xFF6B8F71),
                              fontSize: 16,
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        spacing: 8,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.share_rounded,
                                color: Color(0xFF597D60),
                                size: 20,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Share coming soon'),
                                  ),
                                );
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_rounded,
                                color: Color(0xFF597D60),
                                size: 20,
                              ),
                              onPressed: () => Navigator.pop(context),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
            ),

            // Bottom Action Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFFE5E2DC),
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0xFF6B8F71).withOpacity(0.075),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MULAI DARI',
                              style: TextStyle(
                                color: Color(0xFF424842),
                                fontSize: 12,
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              spacing: 2,
                              children: [
                                Text(
                                  currencyFormat.format(hargaPerJam),
                                  style: const TextStyle(
                                    color: Color(0xFF416448),
                                    fontSize: 24,
                                    fontFamily: 'Lexend',
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                                const Flexible(
                                  child: Text(
                                    '/jam',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color(0xFF424842),
                                      fontSize: 12,
                                      fontFamily: 'Lexend',
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () async {
                            if (_selectedTimes.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pilih jam mainnya dulu bre!'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  lapangan: widget.lapangan,
                                  selectedDate: _selectedDate,
                                  selectedTimes: _selectedTimes,
                                ),
                              ),
                            );
                            // Refresh booked times after returning from payment
                            if (mounted) {
                              await _loadBookedTimes();
                              // Clear selected times
                              setState(() {
                                _selectedTimes.clear();
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFF4A261),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadows: [
                                BoxShadow(
                                  color: const Color(0xFF7E4F58).withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                  spreadRadius: -4,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF7E4F58).withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 10),
                                  spreadRadius: -3,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Pilih Jadwal',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
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
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error building detail screen: $e');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Terjadi kesalahan saat memuat lapangan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
