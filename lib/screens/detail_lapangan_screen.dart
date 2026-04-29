import 'package:flutter/material.dart';
import '../database/database.dart'; // Pastikan path helper database lu bener

class DetailLapanganScreen extends StatelessWidget {
  final Map<String, dynamic> lapangan;

  const DetailLapanganScreen({super.key, required this.lapangan});

  Future<void> _prosesBooking(BuildContext context) async {
    final db = await DatabaseHelper.instance.database;
    
    // Kita masukkan data ke tabel 'lapangans' (atau tabel booking lu)
    await db.insert('lapangans', {
      'nama': lapangan['nama'],
      'harga': lapangan['harga'],
      // Tambahin field lain kalau tabel lu punya, misal: 'tanggal': DateTime.now().toString()
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil Booking ${lapangan['nama']}! Cek di My Booking bre.')),
      );
      Navigator.pop(context); // Balik ke Map
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lapangan['nama']), backgroundColor: Colors.blueAccent),
      body: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 100, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lapangan['nama'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Harga: Rp ${lapangan['harga']}/jam', style: const TextStyle(fontSize: 18, color: Colors.green)),
                const SizedBox(height: 20),
                const Text('Fasilitas:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• Lampu Penerangan\n• Ruang Ganti\n• Parkir Luas'),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _prosesBooking(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    child: const Text('BOOKING SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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