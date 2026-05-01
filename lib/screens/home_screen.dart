import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../controllers/lapangan_controller.dart';
import '../models/lapangan_model.dart';
import '../theme/app_theme.dart';
import 'detail_lapangan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LapanganController _controller = LapanganController();
  String? _sportType;
  final _locationController = TextEditingController();
  List<LapanganModel> _lapangans = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _sportTypes = [
    {'key': 'FUTSAL', 'label': 'Futsal'},
    {'key': 'BASKETBALL', 'label': 'Basket'},
    {'key': 'BADMINTON', 'label': 'Badminton'},
    {'key': 'MINI_SOCCER', 'label': 'Mini Soccer'},
    {'key': 'TENNIS', 'label': 'Tennis'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLapangans();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLapangans({String? type, String? location}) async {
    setState(() => _isLoading = true);
    final data = await _controller.searchLapangans(jenis: type, location: location);
    setState(() {
      _lapangans = data;
      _isLoading = false;
    });
  }

  void _handleSearch() =>
      _fetchLapangans(type: _sportType, location: _locationController.text);

  Widget _buildImage(String imagePath, {double height = 180}) {
    Widget img;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      img = Image.network(imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (_, __, ___) => _placeholder(height));
    } else if (imagePath.startsWith('assets/')) {
      img = Image.asset(imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (_, __, ___) => _placeholder(height));
    } else {
      img = Image.file(File(imagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (_, __, ___) => _placeholder(height));
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(height: height, child: img),
    );
  }

  Widget _placeholder(double height) => Container(
        height: height,
        color: AppColors.inputFill,
        child: const Center(
          child: Icon(Icons.image_not_supported_rounded,
              size: 40, color: AppColors.textSecondary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // --- HERO HEADER (fixed, tidak scroll) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temukan Lapangan,',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'Mulai Permainan! 🏆',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Booking lapangan olahraga favoritmu dengan mudah',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // Search bar inline di header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Cari berdasarkan lokasi...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune_rounded,
                              color: AppColors.primary),
                          onPressed: _handleSearch,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      onSubmitted: (_) => _handleSearch(),
                    ),
                  ),
                ],
              ),
            ),

            // --- FILTER CHIPS ---
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _sportTypes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildChip('Semua', null, _sportType == null);
                    }
                    final sport = _sportTypes[index - 1];
                    return _buildChip(
                        sport['label'], sport['key'], _sportType == sport['key']);
                  },
                ),
              ),
            ),

            // --- LIST LAPANGAN (scrollable) ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : _lapangans.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 56,
                                  color:
                                      AppColors.textSecondary.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              const Text('Lapangan tidak ditemukan',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _lapangans.length,
                          itemBuilder: (context, index) =>
                              _buildFieldCard(_lapangans[index], fmt),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String? key, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _sportType = key);
        _fetchLapangans(type: key, location: _locationController.text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.inputFill,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard(LapanganModel lapangan, NumberFormat fmt) {
    final img = lapangan.firstImage;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetailLapanganScreen(lapangan: lapangan.toMap()),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 12,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            Stack(
              children: [
                img.isEmpty ? _placeholder(180) : _buildImage(img),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(lapangan.jenisLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lapangan.namaLapangan,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                            lapangan.address ?? 'Alamat belum diatur',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mulai dari',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          Text(fmt.format(lapangan.harga),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                          const Text('/jam',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text('Book Now',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
