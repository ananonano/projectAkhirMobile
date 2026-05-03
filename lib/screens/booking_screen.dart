import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/booking_controller.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';
import 'receipt_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingController _controller = BookingController();
  int _selectedTabIndex = 0; // 0 = Upcoming, 1 = History

  Future<List<BookingModel>> _getMyBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    return _controller.getMyBookings(userId);
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
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reschedule coming soon'),
                              ),
                            );
                          },
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
                                namaLapangan: item.namaLapangan,
                                tanggal: item.tanggal,
                                jam: item.jam,
                                totalDibayar: item.totalHargaInt.toDouble(),
                                mataUang: 'IDR',
                                metodeBayar: 'Telah Dibayar',
                                isFromHistory: true,
                                status: item.status,
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
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Review coming soon'),
                                ),
                              );
                            },
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
                                namaLapangan: item.namaLapangan,
                                tanggal: item.tanggal,
                                jam: item.jam,
                                totalDibayar: item.totalHargaInt.toDouble(),
                                mataUang: 'IDR',
                                metodeBayar: 'Telah Dibayar',
                                isFromHistory: true,
                                status: item.status,
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
