import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/booking_controller.dart';
import 'payment_screen.dart';

class DetailLapanganScreen extends StatefulWidget {
  final Map<String, dynamic> lapangan;

  const DetailLapanganScreen({super.key, required this.lapangan});

  @override
  State<DetailLapanganScreen> createState() => _DetailLapanganScreenState();
}

class _DetailLapanganScreenState extends State<DetailLapanganScreen> {
  // --- STATE SLIDER GAMBAR ---
  int _currentImageIndex = 0;
  List<String> _imagePaths = [];
  final PageController _pageController = PageController();

  final BookingController _bookingController = BookingController();

  // --- STATE BOOKING (JADWAL & JAM) ---
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedTimes = [];
  late List<String> _availableTimes;
  List<String> _bookedTimes = []; // Jam yang udah dipesen orang lain
  bool _isLoadingJadwal = false;

  @override
  void initState() {
    super.initState();
    _parseImages();
    // Bikin list jam dari 08:00 sampai 22:00
    _availableTimes = List.generate(
      15,
      (index) => '${(index + 8).toString().padLeft(2, '0')}:00',
    );
    _fetchBookedTimes();
  }

  void _parseImages() {
    String rawImages = widget.lapangan['image'] ?? '';
    if (rawImages.isNotEmpty) {
      _imagePaths = rawImages.split(',').map((e) => e.trim()).toList();
    }
  }

  Future<void> _fetchBookedTimes() async {
    setState(() => _isLoadingJadwal = true);
    final booked = await _bookingController.getBookedTimes(
      widget.lapangan['id'],
      _selectedDate,
    );
    setState(() {
      _bookedTimes = booked;
      _isLoadingJadwal = false;
      _selectedTimes.clear();
    });
  }

  Widget _buildImageProvider(String path) {
    // 1. Kalau path-nya link internet (Google, imgur, dll)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    // 2. Kalau path-nya dari folder bawaan aplikasi (assets)
    else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    // 3. Kalau path-nya dari galeri HP (Upload via Admin)
    else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Gambar tidak tersedia',
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFasilitasChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFF64E42)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasImages = _imagePaths.isNotEmpty;
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Hitung total harga dinamis berdasarkan jam yang dipilih
    int hargaPerJam = widget.lapangan['harga'] ?? 0;
    int totalHarga = _selectedTimes.isEmpty
        ? hargaPerJam
        : (hargaPerJam * _selectedTimes.length);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120), // Ruang buat BottomBar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. SLIDER GAMBAR
            // ==========================================
            Stack(
              children: [
                SizedBox(
                  height: 380,
                  child: hasImages
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: _imagePaths.length,
                          onPageChanged: (index) =>
                              setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) =>
                              _buildImageProvider(_imagePaths[index]),
                        )
                      : _buildPlaceholder(),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                if (hasImages && _imagePaths.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_imagePaths.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: _currentImageIndex == index ? 24 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? const Color(0xFFF64E42)
                                : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),

            // ==========================================
            // 2. INFO LAPANGAN & DESKRIPSI
            // ==========================================
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF64E42).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (widget.lapangan['jenis'] ?? 'LAINNYA')
                          .toString()
                          .replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Color(0xFFF64E42),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.lapangan['nama_lapangan'] ?? 'Nama Lapangan',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.lapangan['address'] ?? 'Alamat tidak tersedia',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 24),
                  const Text(
                    'Fasilitas Tersedia',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFasilitasChip(Icons.wc_rounded, 'Toilet Bersih'),
                        _buildFasilitasChip(
                          Icons.local_parking_rounded,
                          'Parkir Luas',
                        ),
                        _buildFasilitasChip(Icons.wifi_rounded, 'Free WiFi'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 3. FITUR PILIH TANGGAL & JAM
                  // ==========================================
                  const Text(
                    'Pilih Jadwal Main',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),

                  // PILIH TANGGAL
                  const Text(
                    'Tanggal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 31, // Kasih opsi 31 hari ke depan
                      itemBuilder: (context, index) {
                        DateTime date = DateTime.now().add(
                          Duration(days: index),
                        );
                        bool isSelected =
                            _selectedDate.day == date.day &&
                            _selectedDate.month == date.month;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                              _selectedTimes
                                  .clear(); // Reset jam kalau ganti hari
                            });
                            _fetchBookedTimes(); // Panggil ini tiap ganti tanggal
                          },
                          child: Container(
                            width: 65,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF64E42)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFF64E42)
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE').format(date),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd').format(date),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PILIH JAM MAIN
                  const Text(
                    'Jam Tersedia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableTimes.map((time) {
                      bool isBooked = _bookedTimes.contains(
                        time,
                      ); // Cek apakah sudah dipesan
                      bool isSelected = _selectedTimes.contains(time);

                      return GestureDetector(
                        onTap: isBooked
                            ? null
                            : () {
                                // Kalau udah dibooking, GAK BISA DIKLIK
                                setState(() {
                                  if (isSelected) {
                                    _selectedTimes.remove(time);
                                  } else {
                                    _selectedTimes.add(time);
                                  }
                                });
                              },
                        child: Container(
                          width:
                              (MediaQuery.of(context).size.width - 68) /
                              3, // Bagi 3 kolom
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            // WARNA BERBEDA KALAU SUDAH DIBOOKING
                            color: isBooked
                                ? Colors.grey[200] // Warna abu-abu kalau penuh
                                : (isSelected
                                      ? const Color(0xFFF64E42)
                                      : Colors.white),
                            border: Border.all(
                              color: isBooked
                                  ? Colors.transparent
                                  : (isSelected
                                        ? const Color(0xFFF64E42)
                                        : Colors.grey.shade300),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              time,
                              style: TextStyle(
                                // TEKS CORET KALAU SUDAH DIBOOKING
                                color: isBooked
                                    ? Colors.grey[400]
                                    : (isSelected
                                          ? Colors.white
                                          : Colors.black87),
                                fontWeight: FontWeight.bold,
                                decoration: isBooked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ==========================================
      // 4. BOTTOM BAR (TOMBOL BOOK NOW)
      // ==========================================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Info Total Harga
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTimes.isEmpty ? 'Harga Mulai' : 'Total Harga',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(totalHarga),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF64E42),
                        ),
                      ),
                      if (_selectedTimes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4.0, left: 2.0),
                          child: Text(
                            '/jam',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Tombol Booking Asli
              ElevatedButton(
                onPressed: () {
                  if (_selectedTimes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pilih jam mainnya dulu bre!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // Kalau jam udah dipilih, lempar ke halaman bayar
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        lapangan: widget.lapangan,
                        selectedDate: _selectedDate,
                        selectedTimes: _selectedTimes,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF64E42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
