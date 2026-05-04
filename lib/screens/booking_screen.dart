import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/booking_controller.dart';
import '../database/database.dart';
import '../models/booking_model.dart';
import '../repositories/review_repository.dart';
import '../theme/app_theme.dart';
import 'detail_lapangan_screen.dart';
import 'receipt_screen.dart';
import 'root.dart'; // Import untuk akses bookingScreenRefreshNotifier

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingController _controller = BookingController();
  int _selectedTabIndex = 0; // 0 = Upcoming, 1 = History
  int _refreshKey = 0; // Key untuk trigger rebuild FutureBuilder

  @override
  void initState() {
    super.initState();
    // Listen to booking refresh notifier
    bookingScreenRefreshNotifier.addListener(_onBookingRefreshRequested);
  }

  @override
  void dispose() {
    bookingScreenRefreshNotifier.removeListener(_onBookingRefreshRequested);
    super.dispose();
  }

  void _onBookingRefreshRequested() {
    print('[BookingScreen] Refresh requested, rebuilding...');
    if (mounted) {
      setState(() {
        _refreshKey++; // Increment key to trigger FutureBuilder rebuild
      });
    }
  }

  Future<List<BookingModel>> _getMyBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    final username = prefs.getString('username') ?? '';
    
    print('[BookingScreen] Getting bookings for userId: $userId, username: $username');
    
    final bookings = await _controller.getMyBookings(userId);
    
    print('[BookingScreen] Found ${bookings.length} bookings');
    for (var booking in bookings) {
      print('[BookingScreen] Booking ID: ${booking.id}, User ID: ${booking.userId}, Lapangan: ${booking.namaLapangan}');
    }
    
    return bookings;
  }

  List<BookingModel> _filterBookings(List<BookingModel> bookings) {
    if (_selectedTabIndex == 0) {
      // Upcoming - belum selesai dan tidak dibatalkan
      return bookings.where((b) {
        final isSelesai = _controller.isBookingSelesai(b.tanggal, b.jam);
        return !isSelesai && b.status != 'cancelled';
      }).toList();
    } else {
      // History - selesai atau dibatalkan
      return bookings.where((b) {
        final isSelesai = _controller.isBookingSelesai(b.tanggal, b.jam);
        return isSelesai || b.status == 'cancelled';
      }).toList();
    }
  }

  // Helper method to combine consecutive booking times into ranges
  List<String> _combineConsecutiveTimes(String jamString) {
    List<String> times = jamString.split(',').map((e) => e.trim()).toList();
    if (times.isEmpty || times.first == '-') return ['-'];

    // Extract hours from times (e.g., "09:00" -> 9)
    List<int> hours = [];
    for (String time in times) {
      try {
        int hour = int.parse(time.split(':')[0]);
        hours.add(hour);
      } catch (e) {
        continue;
      }
    }

    if (hours.isEmpty) return times;

    // Sort hours to handle consecutive ones
    hours.sort();

    List<String> ranges = [];
    int rangeStart = hours[0];
    int rangeEnd = hours[0];

    for (int i = 1; i < hours.length; i++) {
      if (hours[i] == rangeEnd + 1) {
        // Consecutive hour
        rangeEnd = hours[i];
      } else {
        // Not consecutive, save current range and start new one
        if (rangeStart == rangeEnd) {
          ranges.add('${rangeStart.toString().padLeft(2, '0')}:00');
        } else {
          ranges.add('${rangeStart.toString().padLeft(2, '0')}:00-${(rangeEnd + 1).toString().padLeft(2, '0')}:00');
        }
        rangeStart = hours[i];
        rangeEnd = hours[i];
      }
    }

    // Add the last range
    if (rangeStart == rangeEnd) {
      ranges.add('${rangeStart.toString().padLeft(2, '0')}:00');
    } else {
      ranges.add('${rangeStart.toString().padLeft(2, '0')}:00-${(rangeEnd + 1).toString().padLeft(2, '0')}:00');
    }

    return ranges;
  }

  // Helper method to convert booking date and times to List<DateTime>
  List<DateTime> _getBookingDateTimes(String tanggal, String jam) {
    print('[BookingScreen] _getBookingDateTimes called');
    print('[BookingScreen] tanggal: $tanggal');
    print('[BookingScreen] jam: $jam');
    
    try {
      // Parse tanggal (format: "dd MMM yyyy")
      final dateFormat = DateFormat('dd MMM yyyy');
      final bookingDate = dateFormat.parse(tanggal);
      
      // Parse jam (format: "08:00, 09:00, 10:00")
      final times = jam.split(',').map((e) => e.trim()).toList();
      
      List<DateTime> dateTimes = [];
      for (String timeStr in times) {
        if (timeStr == '-' || timeStr.isEmpty) continue;
        
        try {
          final timeParts = timeStr.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          
          dateTimes.add(DateTime(
            bookingDate.year,
            bookingDate.month,
            bookingDate.day,
            hour,
            minute,
          ));
        } catch (e) {
          print('[BookingScreen] Error parsing time "$timeStr": $e');
          continue;
        }
      }
      
      final result = dateTimes.isEmpty ? [bookingDate] : dateTimes;
      print('[BookingScreen] Result: $result');
      return result;
    } catch (e) {
      print('[BookingScreen] Error parsing booking date times: $e');
      return [];
    }
  }

  Future<void> _handleReview(BookingModel booking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      
      if (userId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User tidak ditemukan')),
        );
        return;
      }

      // Check if lapanganId is valid
      final lapanganId = booking.lapanganId;
      if (lapanganId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID Lapangan tidak valid')),
          );
        }
        return;
      }

      // Load lapangan data
      final db = await DatabaseHelper.instance.database;
      final lapanganResult = await db.query(
        'lapangans',
        where: 'id = ?',
        whereArgs: [lapanganId],
      );

      if (lapanganResult.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lapangan tidak ditemukan')),
          );
        }
        return;
      }

      final lapanganData = lapanganResult.first;

      // Check if user already reviewed this lapangan
      final reviewRepo = ReviewRepository();
      final existingReview = await reviewRepo.getUserReviewForLapangan(
        userId,
        lapanganId,
      );

      // Navigate to detail lapangan screen with auto-open review
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailLapanganScreen(
              lapangan: lapanganData,
              openReviewOnLoad: true,
              existingReview: existingReview,
            ),
          ),
        );
        
        // Refresh bookings after returning
        setState(() {});
      }
    } catch (e) {
      print('[BookingScreen] Error handling review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Check if booking can be rescheduled (H-2 hours from earliest booking time)
  bool _canReschedule(BookingModel booking) {
    try {
      // Parse booking date
      final bookingDate = DateFormat('dd MMM yyyy').parse(booking.tanggal);
      
      // Get all booking times
      final times = booking.jam.split(',').map((e) => e.trim()).toList();
      if (times.isEmpty) return false;
      
      // Find earliest time
      int earliestHour = 24;
      for (String time in times) {
        try {
          int hour = int.parse(time.split(':')[0]);
          if (hour < earliestHour) {
            earliestHour = hour;
          }
        } catch (e) {
          continue;
        }
      }
      
      if (earliestHour == 24) return false;
      
      // Create DateTime for earliest booking time
      final earliestBookingTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        earliestHour,
        0,
      );
      
      // Calculate deadline (H-2 hours)
      final deadline = earliestBookingTime.subtract(const Duration(hours: 2));
      
      // Check if current time is before deadline
      final now = DateTime.now();
      return now.isBefore(deadline);
    } catch (e) {
      print('[BookingScreen] Error checking reschedule eligibility: $e');
      return false;
    }
  }

  // Get reschedule deadline message
  String _getRescheduleDeadline(BookingModel booking) {
    try {
      final bookingDate = DateFormat('dd MMM yyyy').parse(booking.tanggal);
      final times = booking.jam.split(',').map((e) => e.trim()).toList();
      
      int earliestHour = 24;
      for (String time in times) {
        try {
          int hour = int.parse(time.split(':')[0]);
          if (hour < earliestHour) {
            earliestHour = hour;
          }
        } catch (e) {
          continue;
        }
      }
      
      if (earliestHour == 24) return '';
      
      final earliestBookingTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        earliestHour,
        0,
      );
      
      final deadline = earliestBookingTime.subtract(const Duration(hours: 2));
      return DateFormat('dd MMM yyyy HH:mm').format(deadline);
    } catch (e) {
      return '';
    }
  }

  // Show reschedule dialog
  void _showRescheduleDialog(BookingModel booking) {
    if (!_canReschedule(booking)) {
      final deadline = _getRescheduleDeadline(booking);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tidak Dapat Reschedule'),
          content: Text(
            'Maaf, waktu reschedule sudah lewat.\n\n'
            'Reschedule hanya dapat dilakukan minimal 2 jam sebelum waktu booking terdekat.\n\n'
            'Deadline reschedule: $deadline',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Show reschedule bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RescheduleBottomSheet(booking: booking),
    ).then((result) {
      if (result == true) {
        // Refresh bookings after reschedule
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        title: const Text(
          'Riwayat Booking',
          style: TextStyle(
            color: Color(0xFF1A1C1A),
            fontSize: 18,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<List<BookingModel>>(
        key: ValueKey(_refreshKey), // Key untuk trigger rebuild saat refresh
        future: _getMyBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Booking lapangan pertamamu sekarang!',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          final allBookings = snapshot.data!;
          final filteredBookings = _filterBookings(allBookings);

          return Column(
            children: [
              // Tab Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFEEEEEA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabButton(0, 'Upcoming'),
                      _buildTabButton(1, 'History'),
                    ],
                  ),
                ),
              ),
              // Bookings List
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedTabIndex == 0
                                  ? Icons.schedule_rounded
                                  : Icons.history_rounded,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedTabIndex == 0
                                  ? 'Tidak ada booking yang akan datang'
                                  : 'Tidak ada riwayat booking',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final item = filteredBookings[index];
                          final isSelesai =
                              _controller.isBookingSelesai(item.tanggal, item.jam);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == filteredBookings.length - 1 ? 0 : 24,
                            ),
                            child: _buildBookingCard(item, isSelesai),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: ShapeDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            shadows: isSelected
                ? [
                    const BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF416448)
                    : const Color(0xFF424842),
                fontSize: 14,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w600,
                height: 1.40,
                letterSpacing: 0.28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel item, bool isSelesai) {
    final isCancelled = item.status == 'cancelled';
    final isUpcoming = !isSelesai && !isCancelled;
    final bookingCode = 'BKG${item.id?.toString().padLeft(5, '0') ?? '00000'}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            color: Color(0xFFC2C8BF),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        shadows: [
          BoxShadow(
            color: const Color(0x0C000000),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                // Header with status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          // Booking Code
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E8E4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bookingCode,
                              style: const TextStyle(
                                color: Color(0xFF416448),
                                fontSize: 11,
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.namaLapangan,
                            style: const TextStyle(
                              color: Color(0xFF1A1C1A),
                              fontSize: 16,
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 6,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: const Color(0xFF78716C),
                              ),
                              Text(
                                item.tanggal,
                                style: const TextStyle(
                                  color: Color(0xFF78716C),
                                  fontSize: 12,
                                  fontFamily: 'Lexend',
                                ),
                              ),
                            ],
                          ),
                          // Display booking times vertically
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _combineConsecutiveTimes(item.jam)
                                .map((jam) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 6,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: const Color(0xFF78716C),
                                      ),
                                      Text(
                                        jam,
                                        style: const TextStyle(
                                          color: Color(0xFF78716C),
                                          fontSize: 12,
                                          fontFamily: 'Lexend',
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: isCancelled
                            ? const Color(0xFFFFDAD6)
                            : isSelesai
                                ? const Color(0xFFE2E3DE)
                                : const Color(0xFFC5ECC9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      child: Text(
                        isCancelled
                            ? 'Cancelled'
                            : isSelesai
                                ? 'Completed'
                                : 'Upcoming',
                        style: TextStyle(
                          color: isCancelled
                              ? const Color(0xFFD84040)
                              : isSelesai
                                  ? const Color(0xFF78716C)
                                  : const Color(0xFF416448),
                          fontSize: 11,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w600,
                          height: 1.40,
                        ),
                      ),
                    ),
                  ],
                ),
                // Divider
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFE8E8E4),
                ),
                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Bayar',
                      style: TextStyle(
                        color: Color(0xFF78716C),
                        fontSize: 12,
                        fontFamily: 'Lexend',
                      ),
                    ),
                    Text(
                      'Rp ${NumberFormat("#,###").format(item.totalHargaInt)}',
                      style: TextStyle(
                        color: isCancelled
                            ? const Color(0xFFD84040)
                            : isSelesai
                                ? const Color(0xFF78716C)
                                : const Color(0xFF416448),
                        fontSize: 18,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w600,
                        height: 1.30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: isUpcoming
                  ? [
                      // Reschedule button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showRescheduleDialog(item),
                          child: Container(
                            height: 48,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  width: 1,
                                  color: Color(0xFF416448),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Reschedule',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF416448),
                                  fontSize: 16,
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // View Ticket button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptScreen(
                                bookingId: item.id,
                                namaLapangan: item.namaLapangan,
                                tanggal: item.tanggal,
                                jam: item.jam,
                                totalDibayar: item.totalHargaInt.toDouble(),
                                mataUang: 'IDR',
                                metodeBayar: item.paymentMethod ?? 'QRIS',
                                isFromHistory: true,
                                status: item.status,
                                transactionDateTime: item.createdAt != null 
                                  ? DateTime.tryParse(item.createdAt!)
                                  : null,
                                bookingDateTimes: _getBookingDateTimes(item.tanggal, item.jam),
                              ),
                            ),
                          ),
                          child: Container(
                            height: 48,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFF4A261),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadows: [
                                BoxShadow(
                                  color: const Color(0xFF7E4F58).withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                  spreadRadius: -2,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF7E4F58).withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                  spreadRadius: -1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'View Ticket',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]
                  : [
                      // For history: Review and View Ticket
                      if (!isCancelled)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleReview(item),
                            child: Container(
                              height: 48,
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1,
                                    color: Color(0xFF416448),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Review',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF416448),
                                    fontSize: 16,
                                    fontFamily: 'Lexend',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptScreen(
                                bookingId: item.id,
                                namaLapangan: item.namaLapangan,
                                tanggal: item.tanggal,
                                jam: item.jam,
                                totalDibayar: item.totalHargaInt.toDouble(),
                                mataUang: 'IDR',
                                metodeBayar: item.paymentMethod ?? 'QRIS',
                                isFromHistory: true,
                                status: item.status,
                                transactionDateTime: item.createdAt != null 
                                  ? DateTime.tryParse(item.createdAt!)
                                  : null,
                                bookingDateTimes: _getBookingDateTimes(item.tanggal, item.jam),
                              ),
                            ),
                          ),
                          child: Container(
                            height: 48,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFF4A261),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadows: [
                                BoxShadow(
                                  color: const Color(0xFF7E4F58).withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                  spreadRadius: -2,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF7E4F58).withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                  spreadRadius: -1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'View Ticket',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}


// Reschedule Bottom Sheet Widget
class RescheduleBottomSheet extends StatefulWidget {
  final BookingModel booking;

  const RescheduleBottomSheet({super.key, required this.booking});

  @override
  State<RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  final BookingController _controller = BookingController();
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedTimes = [];
  List<String> _availableTimes = [];
  List<String> _bookedTimes = []; // Track booked times separately
  bool _isLoading = false;
  late int _maxSelectableSlots; // Jumlah jam yang bisa dipilih (sama dengan booking asli)

  @override
  void initState() {
    super.initState();
    // Set initial date to tomorrow
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    
    // Hitung jumlah jam dari booking asli
    final originalTimes = widget.booking.jam.split(',').map((e) => e.trim()).toList();
    _maxSelectableSlots = originalTimes.length;
    
    _generateAvailableTimes();
    _loadBookedTimes();
  }

  void _generateAvailableTimes() {
    _availableTimes = [];
    for (int hour = 8; hour < 22; hour++) {
      _availableTimes.add('${hour.toString().padLeft(2, '0')}:00');
    }
  }

  Future<void> _loadBookedTimes() async {
    setState(() => _isLoading = true);
    try {
      final lapanganId = widget.booking.lapanganId ?? 0;
      if (lapanganId == 0) {
        setState(() => _isLoading = false);
        return;
      }
      final booked = await _controller.getBookedTimes(lapanganId, _selectedDate);
      
      setState(() {
        // Store booked times instead of removing them
        _bookedTimes = booked;
        _selectedTimes.clear();
        _isLoading = false;
      });
    } catch (e) {
      print('[Reschedule] Error loading booked times: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
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
      await _loadBookedTimes();
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
      return hour <= now.hour;
    } catch (e) {
      return false;
    }
  }

  Future<void> _confirmReschedule() async {
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 jam booking')),
      );
      return;
    }

    // Validasi: jumlah jam harus sama dengan booking asli
    if (_selectedTimes.length != _maxSelectableSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anda harus memilih $_maxSelectableSlots jam (sama dengan booking asli)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Reschedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Booking Lama:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Tanggal: ${widget.booking.tanggal}'),
            Text('Jam: ${widget.booking.jam}'),
            const SizedBox(height: 16),
            const Text('Booking Baru:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Tanggal: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
            Text('Jam: ${_selectedTimes.join(', ')}'),
            const SizedBox(height: 16),
            const Text(
              'Apakah Anda yakin ingin reschedule booking ini?',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Ya, Reschedule', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Perform reschedule
    setState(() => _isLoading = true);
    try {
      await _controller.rescheduleBooking(
        widget.booking.id!,
        DateFormat('dd MMM yyyy').format(_selectedDate),
        _selectedTimes.join(', '),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil di-reschedule!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh parent
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reschedule Booking',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Current booking info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Saat Ini:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.booking.namaLapangan,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.booking.tanggal} • ${widget.booking.jam}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Date picker
              const Text(
                'Pilih Tanggal Baru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Time picker
              const Text(
                'Pilih Jam Baru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Info: jumlah jam yang harus dipilih
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pilih $_maxSelectableSlots jam (sama dengan booking asli)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTimes.map((time) {
                    final isSelected = _selectedTimes.contains(time);
                    final isPassed = _isTimePassed(time);
                    final isBooked = _bookedTimes.contains(time); // Check if booked
                    final canSelect = _selectedTimes.length < _maxSelectableSlots || isSelected;
                    
                    // Disable if: passed, booked, or limit reached
                    final isDisabled = isPassed || isBooked || (!canSelect && !isSelected);
                    
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
                                _selectedTimes.sort();
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? Colors.grey[200]
                              : isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                          border: Border.all(
                            color: isDisabled
                                ? Colors.grey[300]!
                                : isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isDisabled
                                ? Colors.grey
                                : isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              
              if (_selectedTimes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, 
                        color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dipilih: ${_selectedTimes.length}/$_maxSelectableSlots jam (${_selectedTimes.join(', ')})',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmReschedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Konfirmasi Reschedule',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
