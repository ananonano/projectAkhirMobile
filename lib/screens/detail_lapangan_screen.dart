import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/booking_controller.dart';
import '../repositories/review_repository.dart';
import '../repositories/lapangan_image_repository.dart';
import '../models/review_model.dart';
import 'payment_screen.dart';
import 'edit_lapangan_images_screen.dart';

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
              primary: Color(0xFFF64E42),
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
                          color: const Color(0xFFF64E42),
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
                        color: Color(0xFFF64E42),
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
                style: TextStyle(color: Color(0xFFF64E42)),
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
      int userId = 1; // TODO: Get from current logged-in user
      
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
    } catch (e) {
      print('[ReviewScreen] Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
          color: const Color(0xFFF64E42),
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
                  backgroundImage: NetworkImage(review.userImage!),
                  radius: 18,
                  onBackgroundImageError: (_, __) {},
                )
              else
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF64E42).withOpacity(0.2),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFFF64E42),
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
                    color: const Color(0xFFF64E42).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Color(0xFFF64E42),
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Rating',
                        style: TextStyle(
                          color: Color(0xFFF64E42),
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
                color: Color(0xFFF64E42),
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

  Widget _buildFasilitasChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFF64E42)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
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

      // PERBAIKAN: Parsing harga ke int untuk mencegah "white screen" karena mismatch tipe data
      int hargaPerJam = int.tryParse(widget.lapangan['harga']?.toString() ?? '0') ?? 0;
      int totalHarga = _selectedTimes.isEmpty
          ? hargaPerJam
          : (hargaPerJam * _selectedTimes.length);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 380,
                  child: hasImages
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: _imagePaths.length,
                          onPageChanged: (index) =>
                              setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) =>
                              _buildImageProvider(_imagePaths[index]),
                        )
                      : _buildPlaceholder(),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Edit Images Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditLapanganImagesScreen(
                            lapanganId: widget.lapangan['id'] ?? 0,
                            lapanganName: widget.lapangan['nama_lapangan'] ?? 'Lapangan',
                          ),
                        ),
                      ).then((_) => _loadImagesFromDatabase());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                if (hasImages && _imagePaths.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_imagePaths.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: _currentImageIndex == index ? 24 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? const Color(0xFFF64E42)
                                : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF64E42).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (widget.lapangan['jenis'] ?? 'LAINNYA')
                          .toString()
                          .replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Color(0xFFF64E42),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.lapangan['nama_lapangan'] ?? 'Nama Lapangan',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.lapangan['address'] ?? 'Alamat tidak tersedia',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFFF64E42),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Jam Operasional: ${widget.lapangan['jam_buka'] ?? '08:00'} - ${widget.lapangan['jam_tutup'] ?? '22:00'}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 24),
                  const Text(
                    'Fasilitas Tersedia',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildFasilitasChip(Icons.wc_rounded, 'Toilet Bersih'),
                      _buildFasilitasChip(
                        Icons.local_parking_rounded,
                        'Parkir Luas',
                      ),
                      _buildFasilitasChip(Icons.wifi_rounded, 'Free WiFi'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 24),
                  const Text(
                    'Pilih Jadwal Main',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),
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
                          color: Color(0xFFF64E42),
                          size: 22,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                                  ? const Color(0xFFF64E42)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFF64E42)
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
                  const SizedBox(height: 24),
                  const Text(
                    'Jam Tersedia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                          color: Color(0xFFF64E42),
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
                                        ? const Color(0xFFF64E42)
                                        : Colors.white),
                              border: Border.all(
                                color: isDisabled
                                    ? Colors.transparent
                                    : (isSelected
                                          ? const Color(0xFFF64E42)
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
            ),
            _buildReviewsSection(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTimes.isEmpty ? 'Harga Mulai' : 'Total Harga',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(totalHarga),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF64E42),
                        ),
                      ),
                      if (_selectedTimes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4.0, left: 2.0),
                          child: Text(
                            '/jam',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Flexible(
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedTimes.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pilih jam mainnya dulu bre!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          lapangan: widget.lapangan,
                          selectedDate: _selectedDate,
                          selectedTimes: _selectedTimes,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF64E42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              ),
            ],
          ),
        ),
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