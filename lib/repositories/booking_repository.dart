import '../database/database.dart';
import '../models/booking_model.dart';

/// Semua operasi database yang berhubungan dengan tabel `bookings`
class BookingRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Ambil booking milik user tertentu saja
  Future<List<BookingModel>> getBookingsByUser(int userId) async {
    final maps = await _db.getBookings(userId: userId);
    return maps.map((map) => BookingModel.fromMap(map)).toList();
  }

  // Ambil jam yang sudah dipesan untuk lapangan + tanggal tertentu
  Future<List<String>> getBookedTimes(int lapanganId, String tanggal) async {
    return _db.getBookedTimes(lapanganId, tanggal);
  }

  // Simpan booking baru ke database
  Future<int> insertBooking(BookingModel booking) async {
    return _db.insertBooking(booking.toMap());
  }
}
