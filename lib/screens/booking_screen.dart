import 'package:flutter/material.dart';
import '../database/database.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  // Fungsi narik data dari SQLite
  Future<void> _fetchBookings() async {
    final db = await DatabaseHelper.instance.database;
    // Sebagai contoh awal, kita tarik data list lapangan yang ada di database
    final data = await db.query('lapangans');
    setState(() {
      _bookings = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Riwayat Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ? const Center(child: Text('Belum ada riwayat pesanan nih bre.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: Colors.blueAccent,
                        size: 30,
                      ),
                    ),
                    // TAMBAHKAN '??' DI SINI BRE
                    title: Text(
                      booking['nama']?.toString() ?? 'Nama Lapangan Kosong',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Tarif: Rp ${booking['harga']?.toString() ?? '0'}/jam',
                      ),
                    ),
                    trailing: const Chip(
                      label: Text(
                        'Selesai',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
