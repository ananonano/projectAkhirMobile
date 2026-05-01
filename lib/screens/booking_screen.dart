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

  Future<List<BookingModel>> _getMyBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    return _controller.getMyBookings(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Booking'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _getMyBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
                    child: const Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Booking lapangan pertamamu sekarang!', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final item = bookings[index];
              final isSelesai = _controller.isBookingSelesai(item.tanggal, item.jam);
              return _buildBookingCard(item, isSelesai);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel item, bool isSelesai) {
    final isCancelled = item.status == 'cancelled';
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
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
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isCancelled ? Border.all(color: Colors.red.withOpacity(0.3), width: 1.5) : null,
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Column(
          children: [
            // Status bar top
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCancelled
                    ? Colors.red.withOpacity(0.08)
                    : isSelesai
                        ? AppColors.inputFill
                        : AppColors.success.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.namaLapangan,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isCancelled
                          ? Colors.red
                          : isSelesai
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.red.withOpacity(0.15)
                          : isSelesai
                              ? AppColors.textSecondary.withOpacity(0.15)
                              : AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCancelled
                              ? Icons.cancel_rounded
                              : isSelesai
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.schedule_rounded,
                          size: 12,
                          color: isCancelled
                              ? Colors.red
                              : isSelesai
                                  ? AppColors.textSecondary
                                  : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCancelled
                              ? 'Dibatalkan'
                              : isSelesai
                                  ? 'Selesai'
                                  : 'Akan Datang',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCancelled
                                ? Colors.red
                                : isSelesai
                                    ? AppColors.textSecondary
                                    : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Detail
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _infoChip(Icons.calendar_today_rounded, item.tanggal),
                      const SizedBox(width: 12),
                      Expanded(child: _infoChip(Icons.access_time_rounded, item.jam)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Bayar', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        'Rp ${NumberFormat("#,###").format(item.totalHargaInt)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isCancelled
                              ? Colors.red
                              : isSelesai
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (isCancelled) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_rounded, size: 14, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Booking ini telah dibatalkan oleh admin',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
