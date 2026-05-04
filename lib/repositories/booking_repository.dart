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

  /// Get all bookings for revenue calculations (Phase 3)
  /// Joins with lapangans to include gambar field and users to include username
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final db = await _db.database;
      // Join bookings with lapangans and users to get gambar and username
      final bookings = await db.rawQuery('''
        SELECT 
          b.id, 
          b.user_id, 
          b.lapangan_id, 
          b.nama_lapangan, 
          b.tanggal, 
          b.jam, 
          b.total_harga, 
          b.status, 
          b.created_at,
          l.image as gambar,
          u.username as username
        FROM bookings b
        LEFT JOIN lapangans l ON b.lapangan_id = l.id
        LEFT JOIN users u ON b.user_id = u.id
      ''');
      print('[BookingRepo] Loaded ${bookings.length} bookings');
      return bookings;
    } catch (e) {
      print('[BookingRepo] Error getting all bookings: $e');
      return [];
    }
  }

  /// Cancel a booking by ID (Phase 3)
  Future<void> cancelBooking(int bookingId) async {
    try {
      final db = await _db.database;
      await db.update(
        'bookings',
        {'status': 'cancelled'},
        where: 'id = ?',
        whereArgs: [bookingId],
      );
      print('[BookingRepo] Booking $bookingId cancelled successfully');
    } catch (e) {
      print('[BookingRepo] Error cancelling booking: $e');
      throw e;
    }
  }

  /// Update booking status (Phase 3)
  Future<void> updateBookingStatus(int bookingId, String newStatus) async {
    try {
      final db = await _db.database;
      await db.update(
        'bookings',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [bookingId],
      );
      print('[BookingRepo] Booking $bookingId status updated to: $newStatus');
    } catch (e) {
      print('[BookingRepo] Error updating booking status: $e');
      throw e;
    }
  }

  /// Get total revenue from completed bookings (Phase 3)
  Future<int> getTotalRevenue() async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'bookings',
        columns: ['total_harga'],
        where: 'status = ?',
        whereArgs: ['completed'],
      );
      
      int total = 0;
      for (var row in result) {
        final harga = int.tryParse(row['total_harga'].toString()) ?? 0;
        total += harga;
      }
      print('[BookingRepo] Total revenue calculated: $total');
      return total;
    } catch (e) {
      print('[BookingRepo] Error calculating total revenue: $e');
      return 0;
    }
  }

  /// Get count of completed bookings (Phase 3)
  Future<int> getCompletedBookingCount() async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bookings WHERE status = ?',
        ['completed'],
      );
      final count = (result.first['count'] as int?) ?? 0;
      print('[BookingRepo] Completed bookings count: $count');
      return count;
    } catch (e) {
      print('[BookingRepo] Error getting completed bookings count: $e');
      return 0;
    }
  }

  /// Get count of active fields (distinct lapangan_id from bookings) (Phase 3)
  Future<int> getActiveFieldsCount() async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery(
        'SELECT COUNT(DISTINCT lapangan_id) as count FROM bookings WHERE status = ?',
        ['completed'],
      );
      final count = (result.first['count'] as int?) ?? 0;
      print('[BookingRepo] Active fields count: $count');
      return count;
    } catch (e) {
      print('[BookingRepo] Error getting active fields count: $e');
      return 0;
    }
  }

  /// Get revenue breakdown: app fee vs partner revenue (Phase 3)
  Future<Map<String, dynamic>> getRevenueBreakdown() async {
    try {
      final totalRevenue = await getTotalRevenue();
      final appFee = (totalRevenue * 0.1).toInt(); // 10% for app
      final partnerRevenue = totalRevenue - appFee; // 90% for partner

      return {
        'totalRevenue': totalRevenue,
        'appFee': appFee,
        'partnerRevenue': partnerRevenue,
        'appFeePercentage': 10,
        'partnerPercentage': 90,
      };
    } catch (e) {
      print('[BookingRepo] Error calculating revenue breakdown: $e');
      return {
        'totalRevenue': 0,
        'appFee': 0,
        'partnerRevenue': 0,
      };
    }
  }

  /// Get detailed revenue report per lapangan (Phase 3)
  Future<List<Map<String, dynamic>>> getRevenuePerLapangan() async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery('''
        SELECT 
          l.id,
          l.nama_lapangan,
          COUNT(b.id) as total_bookings,
          SUM(CAST(b.total_harga AS INTEGER)) as total_revenue
        FROM bookings b
        LEFT JOIN lapangans l ON b.lapangan_id = l.id
        WHERE b.status = ?
        GROUP BY l.id, l.nama_lapangan
        ORDER BY total_revenue DESC
      ''', ['completed']);
      
      print('[BookingRepo] Revenue per lapangan loaded: ${result.length} items');
      return result;
    } catch (e) {
      print('[BookingRepo] Error getting revenue per lapangan: $e');
      return [];
    }
  }

  /// Reschedule booking to new date and time
  Future<void> rescheduleBooking(int bookingId, String newTanggal, String newJam) async {
    try {
      final db = await _db.database;
      await db.update(
        'bookings',
        {
          'tanggal': newTanggal,
          'jam': newJam,
        },
        where: 'id = ?',
        whereArgs: [bookingId],
      );
      print('[BookingRepo] Booking $bookingId rescheduled to $newTanggal at $newJam');
    } catch (e) {
      print('[BookingRepo] Error rescheduling booking: $e');
      rethrow;
    }
  }
}
