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
            // --- HEADER WITH TITLE AND SEARCH ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Cari Lapangan Terdekat',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search bar with border
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Cari venue atau cabang olahraga...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textSecondary, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune_rounded,
                              color: AppColors.primary, size: 20),
                          onPressed: _handleSearch,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onSubmitted: (_) => _handleSearch(),
                    ),
                  ),
                ],
              ),
            ),

            // --- SPORT CATEGORIES SECTION ---
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sportTypes.length,
                      itemBuilder: (context, index) {
                        final sport = _sportTypes[index];
                        final isSelected = _sportType == sport['key'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _sportType = sport['key']);
                            _fetchLapangans(
                              type: sport['key'],
                              location: _locationController.text,
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: index == _sportTypes.length - 1 ? 0 : 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: ShapeDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        color: AppColors.border,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    shadows: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      )
                                    ],
                                  ),
                                  child: Icon(
                                    _getSportIcon(sport['key']),
                                    size: 28,
                                    color: isSelected ? Colors.white : AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    sport['label'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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

  IconData _getSportIcon(String sportKey) {
    switch (sportKey) {
      case 'FUTSAL':
        return Icons.sports_soccer_rounded;
      case 'BASKETBALL':
        return Icons.sports_basketball_rounded;
      case 'BADMINTON':
        return Icons.sports_rounded;
      case 'TENNIS':
        return Icons.sports_tennis_rounded;
      case 'MINI_SOCCER':
        return Icons.sports_soccer_rounded;
      default:
        return Icons.sports_rounded;
    }
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
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  children: [
                    img.isEmpty
                        ? Container(
                            color: AppColors.inputFill,
                            child: const Center(
                              child: Icon(Icons.image_not_supported_rounded,
                                  size: 36, color: AppColors.textSecondary),
                            ),
                          )
                        : _buildImage(img, height: 140),
                    // Rating badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: Color(0xFFF4A261)),
                            const SizedBox(width: 2),
                            Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lapangan.namaLapangan,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                lapangan.address ?? 'Lokasi tidak diatur',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mulai dari',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              fmt.format(lapangan.harga),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              '/jam',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Pesan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
