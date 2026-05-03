import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectakhir/repositories/booking_repository.dart';
import 'package:projectakhir/theme/app_theme.dart';
import '../widgets/admin_drawer.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<Map<String, dynamic>>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _bookingsFuture = _bookingRepo.getAllBookings();
    });
  }

  List<String> _combineConsecutiveTimes(String jamString) {
    List<String> times = jamString.split(',').map((e) => e.trim()).toList();
    if (times.isEmpty || times.first == '-') return ['-'];

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

    hours.sort();

    List<String> ranges = [];
    int rangeStart = hours[0];
    int rangeEnd = hours[0];

    for (int i = 1; i < hours.length; i++) {
      if (hours[i] == rangeEnd + 1) {
        rangeEnd = hours[i];
      } else {
        if (rangeStart == rangeEnd) {
          ranges.add('${rangeStart.toString().padLeft(2, '0')}:00');
        } else {
          ranges.add(
              '${rangeStart.toString().padLeft(2, '0')}:00-${(rangeEnd + 1).toString().padLeft(2, '0')}:00');
        }
        rangeStart = hours[i];
        rangeEnd = hours[i];
      }
    }

    if (rangeStart == rangeEnd) {
      ranges.add('${rangeStart.toString().padLeft(2, '0')}:00');
    } else {
      ranges.add(
          '${rangeStart.toString().padLeft(2, '0')}:00-${(rangeEnd + 1).toString().padLeft(2, '0')}:00');
    }

    return ranges;
  }

  void _cancelBooking(int bookingId, String lapanganName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Booking?'),
        content: Text('Batalkan booking untuk $lapanganName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _bookingRepo.cancelBooking(bookingId);
                if (mounted) {
                  _loadBookings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking dibatalkan')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAF5),
      drawer: AdminDrawer(
        activeMenu: AdminMenuIndex.bookings,
        scaffoldKey: _scaffoldKey,
      ),
      body: Stack(
        children: [
          // Konten utama dengan padding atas untuk header
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: RefreshIndicator(
              onRefresh: () async {
                _loadBookings();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _bookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final bookings = snapshot.data ?? [];

                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available_rounded,
                              size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada booking',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final status = booking['status'] ?? 'completed';
                      final isCancelled = status == 'cancelled';

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == bookings.length - 1 ? 0 : 24,
                        ),
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                  width: 1, color: Color(0xFFC2C8BF)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with status badge
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                booking['nama_lapangan'] ??
                                                    'Unknown',
                                                style: const TextStyle(
                                                  color: Color(0xFF1A1C1A),
                                                  fontSize: 16,
                                                  fontFamily: 'Lexend',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today_rounded,
                                                    size: 13,
                                                    color: Color(0xFF78716C),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    booking['tanggal'] ?? '-',
                                                    style: const TextStyle(
                                                      color: Color(0xFF78716C),
                                                      fontSize: 12,
                                                      fontFamily: 'Lexend',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              ..._combineConsecutiveTimes(
                                                      booking['jam']
                                                              as String? ??
                                                          '-')
                                                  .map(
                                                (jam) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .access_time_rounded,
                                                        size: 13,
                                                        color:
                                                            Color(0xFF78716C),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        jam,
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0xFF78716C),
                                                          fontSize: 12,
                                                          fontFamily: 'Lexend',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: ShapeDecoration(
                                            color: isCancelled
                                                ? const Color(0xFFFFDAD6)
                                                : const Color(0xFFC5ECC9),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(9999),
                                            ),
                                          ),
                                          child: Text(
                                            isCancelled
                                                ? 'Cancelled'
                                                : 'Active',
                                            style: TextStyle(
                                              color: isCancelled
                                                  ? const Color(0xFFD84040)
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
                                    const SizedBox(height: 12),
                                    // Divider
                                    Container(
                                      width: double.infinity,
                                      height: 1,
                                      color: const Color(0xFFE8E8E4),
                                    ),
                                    const SizedBox(height: 12),
                                    // Price & User Info
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Total Bayar',
                                                style: TextStyle(
                                                  color: Color(0xFF78716C),
                                                  fontSize: 12,
                                                  fontFamily: 'Lexend',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Rp ${NumberFormat("#,###").format(int.tryParse(booking['total_harga'].toString()) ?? 0)}',
                                                style: TextStyle(
                                                  color: isCancelled
                                                      ? const Color(0xFFD84040)
                                                      : const Color(0xFF416448),
                                                  fontSize: 18,
                                                  fontFamily: 'Lexend',
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.30,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'User ID',
                                                style: TextStyle(
                                                  color: Color(0xFF78716C),
                                                  fontSize: 12,
                                                  fontFamily: 'Lexend',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '#${booking['user_id'] ?? '-'}',
                                                style: const TextStyle(
                                                  color: Color(0xFF1A1C1A),
                                                  fontSize: 14,
                                                  fontFamily: 'Lexend',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Action button
                              if (!isCancelled)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 24, right: 24, bottom: 24),
                                  child: GestureDetector(
                                    onTap: () => _cancelBooking(
                                      booking['id'],
                                      booking['nama_lapangan'] ?? 'Unknown',
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      height: 48,
                                      decoration: ShapeDecoration(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          side: const BorderSide(
                                              width: 1,
                                              color: Color(0xFFD84040)),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Batalkan Booking',
                                          style: TextStyle(
                                            color: Color(0xFFD84040),
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
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Fixed Header Bar dengan hamburger menu
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBar(
              title: 'Manajemen Booking',
              scaffoldKey: _scaffoldKey,
            ),
          ),
        ],
      ),
    );
  }
}
