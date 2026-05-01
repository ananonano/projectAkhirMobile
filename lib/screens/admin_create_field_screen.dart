import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../database/database.dart';
import 'map_picker_screen.dart';

class AdminCreateFieldScreen extends StatefulWidget {
  const AdminCreateFieldScreen({super.key});

  @override
  State<AdminCreateFieldScreen> createState() => _AdminCreateFieldScreenState();
}

class _AdminCreateFieldScreenState extends State<AdminCreateFieldScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  // Dua controller baru buat ngelengkapin database
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _jenisOlahraga = 'FUTSAL'; // Sesuai kapitalisasi di Prisma lu
  final List<String> _pilihanJenis = [
    'FUTSAL',
    'BASKETBALL',
    'BADMINTON',
    'MINI_SOCCER',
    'TENNIS',
  ];

  Future<void> _bukaPeta() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _latController.text = result.latitude.toString();
        _lngController.text = result.longitude.toString();
      });
    }
  }

  Future<void> _simpanLapangan() async {
    String nama = _namaController.text.trim();
    String hargaStr = _hargaController.text.trim();
    String latStr = _latController.text.trim();
    String lngStr = _lngController.text.trim();
    String address = _addressController.text.trim();
    String description = _descController.text.trim();

    // Validasi biar admin nggak ngosongin form
    if (nama.isEmpty ||
        hargaStr.isEmpty ||
        latStr.isEmpty ||
        lngStr.isEmpty ||
        address.isEmpty ||
        description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom wajib diisi bre!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int harga = int.tryParse(hargaStr) ?? 0;
    double lat = double.tryParse(latStr) ?? 0.0;
    double lng = double.tryParse(lngStr) ?? 0.0;

    // EKSEKUSI DATABASE: 7 Positional Parameters lengkap!
    await DatabaseHelper.instance.insertLapangan(
      nama,
      _jenisOlahraga,
      harga,
      lat,
      lng,
      description,
      address,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mantap! Lapangan baru berhasil ditambah.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tambah Lapangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF64E42),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nama Lapangan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                hintText: 'Misal: Gor Futsal Seturan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Jenis Olahraga',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _jenisOlahraga,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: _pilihanJenis.map((String jenis) {
                return DropdownMenuItem(
                  value: jenis,
                  child: Text(jenis.replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _jenisOlahraga = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'Harga per Jam (Rp)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Misal: 150000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),

            // --- INPUT BARU: ALAMAT LENGKAP ---
            const Text(
              'Alamat Lengkap',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Misal: Jl. Babarsari No.2...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- INPUT BARU: DESKRIPSI ---
            const Text(
              'Deskripsi Lapangan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Misal: Lantai vinyl standar internasional...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Koordinat Lokasi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: _bukaPeta,
                  icon: const Icon(Icons.map, color: Color(0xFFF64E42)),
                  label: const Text(
                    'Pilih dari Peta',
                    style: TextStyle(
                      color: Color(0xFFF64E42),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _simpanLapangan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF64E42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Simpan Lapangan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
