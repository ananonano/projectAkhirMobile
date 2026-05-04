import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import '../services/recommendation_service.dart';
import '../screens/root.dart'; // Import for recommendationsRefreshNotifier

/// Mengelola logika bisnis seputar booking lapangan
class BookingController {
  final BookingRepository _repo = BookingRepository();
  final RecommendationService _recommendationService = RecommendationService();

  // Ambil riwayat booking milik user yang sedang login
  Future<List<BookingModel>> getMyBookings(int userId) async {
    return _repo.getBookingsByUser(userId);
  }

  // Ambil jam yang sudah dipesan untuk lapangan + tanggal tertentu
  Future<List<String>> getBookedTimes(int lapanganId, DateTime date) async {
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    return _repo.getBookedTimes(lapanganId, formattedDate);
  }

  // Buat booking baru setelah pembayaran berhasil
  Future<int> createBooking({
    required int userId,
    required int lapanganId,
    required String namaLapangan,
    required DateTime tanggal,
    required List<String> selectedTimes,
    required int hargaPerJam,
    String? paymentMethod,
  }) async {
    final totalHarga = hargaPerJam * selectedTimes.length;
    final booking = BookingModel(
      userId: userId,
      lapanganId: lapanganId,
      namaLapangan: namaLapangan,
      tanggal: DateFormat('dd MMM yyyy').format(tanggal),
      jam: selectedTimes.join(', '),
      totalHarga: totalHarga.toString(),
      paymentMethod: paymentMethod ?? 'QRIS',
    );
    
    final bookingId = await _repo.insertBooking(booking);
    
    // Update user preferences after successful booking (ML learning)
    try {
      await _recommendationService.updateUserPreferences(userId);
      print('[BookingController] User preferences updated after booking');
      
      // Trigger recommendations refresh in home screen
      recommendationsRefreshNotifier.value++;
      print('[BookingController] Triggered recommendations refresh');
      
      // Trigger profile stats refresh
      profileStatsRefreshNotifier.value++;
      print('[BookingController] Triggered profile stats refresh');
    } catch (e) {
      print('[BookingController] Error updating preferences: $e');
    }
    
    return bookingId;
  }

  // Cek apakah jadwal booking sudah lewat (untuk label "Selesai" / "Akan Datang")
  bool isBookingSelesai(String tanggal, String jam) {
    try {
      final jamList = jam.split(', ');
      final jamTerakhir = jamList.last.trim();
      final dateTimeString = '$tanggal $jamTerakhir';
      final bookingEndTime = DateFormat('dd MMM yyyy HH:mm').parse(dateTimeString);
      return bookingEndTime.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  // Reschedule booking to new date and time
  Future<void> rescheduleBooking(int bookingId, String newTanggal, String newJam) async {
    await _repo.rescheduleBooking(bookingId, newTanggal, newJam);
    
    // Trigger profile stats refresh after reschedule
    profileStatsRefreshNotifier.value++;
    print('[BookingController] Triggered profile stats refresh after reschedule');
  }
}
