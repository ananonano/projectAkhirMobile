import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';

/// Mengelola logika bisnis seputar booking lapangan
class BookingController {
  final BookingRepository _repo = BookingRepository();

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
  }) async {
    final totalHarga = hargaPerJam * selectedTimes.length;
    final booking = BookingModel(
      userId: userId,
      lapanganId: lapanganId,
      namaLapangan: namaLapangan,
      tanggal: DateFormat('dd MMM yyyy').format(tanggal),
      jam: selectedTimes.join(', '),
      totalHarga: totalHarga.toString(),
    );
    return _repo.insertBooking(booking);
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
}
