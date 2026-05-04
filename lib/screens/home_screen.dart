import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/lapangan_controller.dart';
import '../models/lapangan_model.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';
import '../repositories/review_repository.dart';
import '../database/database.dart';
import 'detail_lapangan_screen.dart';
import 'root.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LapanganController _controller = LapanganController();
  final ReviewRepository _reviewRepository = ReviewRepository();
  final RecommendationService _recommendationService = RecommendationService();
  
  String? _sportType;
  final _locationController = TextEditingController();
  List<LapanganModel> _lapangans = [];
  List<LapanganModel> _recommendedLapangans = [];
  bool _isLoading = true;
  bool _isLoadingRecommendations = true;
  
  // Store ratings for each lapangan
  Map<int, double> _ratings = {};
  Map<int, int> _reviewCounts = {};
  Map<int, int> _bookingCounts = {}; // Store booking counts for popularity
  
  // Filter state
  double? _filterPriceMin;
  double? _filterPriceMax;
  List<String> _filterCategories = []; // Selected sport types
  double? _filterMinRating; // Minimum rating filter (1, 2, 3, 4, 5)
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();
  
  // Sort state
  String? _sortBy; // 'rating_high', 'rating_low', 'price_high', 'price_low', 'popular', 'newest'

  final List<Map<String, dynamic>> _sportTypes = [
    {'key': 'FUTSAL', 'label': 'Futsal'},
    {'key': 'BASKETBALL', 'label': 'Basket'},
    {'key': 'BADMINTON', 'label': 'Badmin'},
    {'key': 'MINI_SOCCER', 'label': 'Minsoc'},
    {'key': 'TENNIS', 'label': 'Tennis'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLapangans();
    _fetchRecommendations();
    
    // Listen to refresh notifier for lapangan list
    homeScreenRefreshNotifier.addListener(_onRefreshRequested);
    
    // Listen to refresh notifier for recommendations (only after booking)
    recommendationsRefreshNotifier.addListener(_onRecommendationsRefreshRequested);
  }
  
  void _onRefreshRequested() {
    // Refresh lapangan data when notified
    print('[HomeScreen] Refresh requested, reloading lapangan...');
    _fetchLapangans(type: _sportType, location: _locationController.text);
    // Don't refresh recommendations - they stay cached
  }
  
  void _onRecommendationsRefreshRequested() {
    // Refresh recommendations only when explicitly requested (after booking)
    print('[HomeScreen] Recommendations refresh requested');
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    homeScreenRefreshNotifier.removeListener(_onRefreshRequested);
    recommendationsRefreshNotifier.removeListener(_onRecommendationsRefreshRequested);
    super.dispose();
  }

  Future<void> _fetchLapangans({String? type, String? location}) async {
    setState(() => _isLoading = true);
    final data = await _controller.searchLapangans(jenis: type, location: location);
    
    // Load ratings and booking counts for each lapangan
    Map<int, double> ratings = {};
    Map<int, int> reviewCounts = {};
    Map<int, int> bookingCounts = {};
    
    for (var lapangan in data) {
      if (lapangan.id != null) {
        final avgRating = await _reviewRepository.getAverageRating(lapangan.id!);
        final count = await _reviewRepository.getReviewCount(lapangan.id!);
        ratings[lapangan.id!] = avgRating;
        reviewCounts[lapangan.id!] = count;
        
        // Get booking count for this lapangan
        final bookingCount = await _getBookingCount(lapangan.id!);
        bookingCounts[lapangan.id!] = bookingCount;
      }
    }
    
    // Apply filters
    List<LapanganModel> filteredData = _applyFilters(data, ratings, bookingCounts);
    
    setState(() {
      _lapangans = filteredData;
      _ratings = ratings;
      _reviewCounts = reviewCounts;
      _bookingCounts = bookingCounts;
      _isLoading = false;
    });
  }
  
  Future<int> _getBookingCount(int lapanganId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bookings WHERE lapangan_id = ?',
        [lapanganId],
      );
      
      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
    } catch (e) {
      print('[HomeScreen] Error getting booking count: $e');
    }
    return 0;
  }
  
  List<LapanganModel> _applyFilters(List<LapanganModel> data, Map<int, double> ratings, Map<int, int> bookingCounts) {
    List<LapanganModel> filtered = List.from(data);
    
    // Filter by categories
    if (_filterCategories.isNotEmpty) {
      filtered = filtered.where((lapangan) {
        return _filterCategories.contains(lapangan.jenis.toUpperCase());
      }).toList();
    }
    
    // Filter by price range
    if (_filterPriceMin != null) {
      filtered = filtered.where((lapangan) => lapangan.harga >= _filterPriceMin!).toList();
    }
    if (_filterPriceMax != null) {
      filtered = filtered.where((lapangan) => lapangan.harga <= _filterPriceMax!).toList();
    }
    
    // Filter by minimum rating
    if (_filterMinRating != null) {
      filtered = filtered.where((lapangan) {
        final rating = ratings[lapangan.id] ?? 0.0;
        return rating >= _filterMinRating!;
      }).toList();
    }
    
    // Apply sorting
    if (_sortBy == 'rating_high') {
      filtered.sort((a, b) {
        final ratingA = ratings[a.id] ?? 0.0;
        final ratingB = ratings[b.id] ?? 0.0;
        return ratingB.compareTo(ratingA); // Descending
      });
    } else if (_sortBy == 'rating_low') {
      filtered.sort((a, b) {
        final ratingA = ratings[a.id] ?? 0.0;
        final ratingB = ratings[b.id] ?? 0.0;
        return ratingA.compareTo(ratingB); // Ascending
      });
    } else if (_sortBy == 'price_high') {
      filtered.sort((a, b) => b.harga.compareTo(a.harga)); // Descending
    } else if (_sortBy == 'price_low') {
      filtered.sort((a, b) => a.harga.compareTo(b.harga)); // Ascending
    } else if (_sortBy == 'popular') {
      // Sort by booking count (most booked = most popular)
      filtered.sort((a, b) {
        final countA = bookingCounts[a.id] ?? 0;
        final countB = bookingCounts[b.id] ?? 0;
        return countB.compareTo(countA); // Descending
      });
    } else if (_sortBy == 'newest') {
      // Sort by ID (higher ID = newer)
      filtered.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0)); // Descending
    }
    
    return filtered;
  }

  Future<void> _fetchRecommendations() async {
    print('[HomeScreen] Starting _fetchRecommendations');
    setState(() => _isLoadingRecommendations = true);
    
    try {
      // Get user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      
      print('[HomeScreen] User ID: $userId');
      
      if (userId == 0) {
        print('[HomeScreen] No user ID found');
        setState(() => _isLoadingRecommendations = false);
        return;
      }
      
      // Get user location (optional)
      Position? userLocation;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          userLocation = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).timeout(const Duration(seconds: 3));
          print('[HomeScreen] Got user location: ${userLocation.latitude}, ${userLocation.longitude}');
        }
      } catch (e) {
        print('[HomeScreen] Could not get location: $e');
      }
      
      // Get recommendations with timeout
      print('[HomeScreen] Calling getRecommendedFields...');
      final recommended = await _recommendationService.getRecommendedFields(
        userId: userId,
        userLocation: userLocation,
        limit: 5,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('[HomeScreen] Timeout getting recommendations');
          return <LapanganModel>[];
        },
      );
      
      print('[HomeScreen] Got ${recommended.length} recommendations');
      
      // Load ratings for recommended fields
      for (var lapangan in recommended) {
        if (lapangan.id != null) {
          final avgRating = await _reviewRepository.getAverageRating(lapangan.id!);
          final count = await _reviewRepository.getReviewCount(lapangan.id!);
          _ratings[lapangan.id!] = avgRating;
          _reviewCounts[lapangan.id!] = count;
        }
      }
      
      setState(() {
        _recommendedLapangans = recommended;
        _isLoadingRecommendations = false;
      });
      
      print('[HomeScreen] Recommendations loaded successfully');
    } catch (e, stackTrace) {
      print('[HomeScreen] Error fetching recommendations: $e');
      print('[HomeScreen] Stack trace: $stackTrace');
      setState(() => _isLoadingRecommendations = false);
    }
  }

  void _handleSearch() =>
      _fetchLapangans(type: _sportType, location: _locationController.text);

  void _showFilterBottomSheet() {
    // Temporary state for the bottom sheet
    List<String> tempFilterCategories = List.from(_filterCategories);
    double? tempFilterMinRating = _filterMinRating;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Lapangan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Minimum Rating Filter
                  const Text(
                    'Rating Minimum',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1.0, 2.0, 3.0, 4.0, 5.0].map((rating) {
                      final isSelected = tempFilterMinRating == rating;
                      final displayText = rating == 5.0 ? '5' : '≥ ${rating.toInt()}';
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempFilterMinRating = isSelected ? null : rating;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: isSelected ? AppColors.primary : Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                displayText,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Price Range Filter
                  const Text(
                    'Rentang Harga',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceMinController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Min',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('—', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _priceMaxController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Max',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Category Filter
                  const Text(
                    'Kategori Olahraga',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sportTypes.map((sport) {
                      final isSelected = tempFilterCategories.contains(sport['key']);
                      return FilterChip(
                        label: Text(sport['label']),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              tempFilterCategories.add(sport['key']);
                            } else {
                              tempFilterCategories.remove(sport['key']);
                            }
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Reset filters
                            setModalState(() {
                              tempFilterMinRating = null;
                              tempFilterCategories.clear();
                            });
                            _priceMinController.clear();
                            _priceMaxController.clear();
                            
                            setState(() {
                              _filterMinRating = null;
                              _filterPriceMin = null;
                              _filterPriceMax = null;
                              _filterCategories.clear();
                            });
                            
                            _fetchLapangans(type: _sportType, location: _locationController.text);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            // Apply filters
                            setState(() {
                              _filterMinRating = tempFilterMinRating;
                              _filterCategories = List.from(tempFilterCategories);
                              
                              // Parse price inputs
                              final minText = _priceMinController.text.trim();
                              final maxText = _priceMaxController.text.trim();
                              _filterPriceMin = minText.isNotEmpty ? double.tryParse(minText) : null;
                              _filterPriceMax = maxText.isNotEmpty ? double.tryParse(maxText) : null;
                            });
                            
                            _fetchLapangans(type: _sportType, location: _locationController.text);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Terapkan Filter',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Urutkan Berdasarkan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Sort options
                  _buildSortOption('Rating Tertinggi', 'rating_high'),
                  _buildSortOption('Rating Terendah', 'rating_low'),
                  _buildSortOption('Harga Tertinggi', 'price_high'),
                  _buildSortOption('Harga Terendah', 'price_low'),
                  _buildSortOption('Lapangan Terlaris', 'popular'),
                  _buildSortOption('Lapangan Terbaru', 'newest'),
                  
                  const SizedBox(height: 12),
                  
                  // Reset button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _sortBy = null);
                        _fetchLapangans(type: _sportType, location: _locationController.text);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reset Urutan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() => _sortBy = value);
        _fetchLapangans(type: _sportType, location: _locationController.text);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
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
            // --- FIXED HEADER WITH TITLE AND SEARCH (NOT SCROLLABLE) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Lapang.In',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search bar and filter/sort buttons
                  Row(
                    children: [
                      // Search bar
                      Expanded(
                        child: Container(
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
                            decoration: const InputDecoration(
                              hintText: 'Cari venue atau cabang olahraga...',
                              hintStyle: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: AppColors.textSecondary, size: 20),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onSubmitted: (_) => _handleSearch(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Filter button
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
                        child: IconButton(
                          icon: const Icon(Icons.tune_rounded,
                              color: AppColors.primary, size: 20),
                          onPressed: _showFilterBottomSheet,
                          tooltip: 'Filter',
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Sort button
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
                        child: IconButton(
                          icon: const Icon(Icons.import_export_rounded,
                              color: AppColors.primary, size: 20),
                          onPressed: _showSortBottomSheet,
                          tooltip: 'Urutkan',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- SCROLLABLE CONTENT (Categories + Recommendations + List) ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : CustomScrollView(
                      slivers: [
                        // Sport Categories Section
                        SliverToBoxAdapter(
                          child: Container(
                            width: double.infinity,
                            color: AppColors.background,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: SizedBox(
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
                          ),
                        ),

                        // Recommendation Section (Always show)
                        SliverToBoxAdapter(
                          child: Container(
                            width: double.infinity,
                            color: AppColors.background,
                            padding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 20, bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Rekomendasi untuk Kamu',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _isLoadingRecommendations
                                    ? const SizedBox(
                                        height: 200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : _recommendedLapangans.isEmpty
                                        ? SizedBox(
                                            height: 200,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.auto_awesome_outlined,
                                                    size: 48,
                                                    color: AppColors.textSecondary.withOpacity(0.4),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Booking lapangan untuk rekomendasi personal',
                                                    style: TextStyle(
                                                      color: AppColors.textSecondary.withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : SizedBox(
                                            height: 200,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: _recommendedLapangans.length,
                                              itemBuilder: (context, index) {
                                                final lapangan = _recommendedLapangans[index];
                                                return _buildRecommendationCard(lapangan);
                                              },
                                            ),
                                          ),
                              ],
                            ),
                          ),
                        ),

                        // List Lapangan
                        _lapangans.isEmpty
                            ? SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off_rounded,
                                          size: 56,
                                          color: AppColors.textSecondary.withOpacity(0.4)),
                                      const SizedBox(height: 12),
                                      const Text('Lapangan tidak ditemukan',
                                          style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildFieldCard(_lapangans[index], fmt),
                                    childCount: _lapangans.length,
                                  ),
                                ),
                              ),
                      ],
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
        return Icons.sports_tennis_rounded; // Changed to tennis icon
      case 'TENNIS':
        return Icons.sports_baseball_rounded; // Changed to baseball icon
      case 'MINI_SOCCER':
        return Icons.sports_soccer_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

  Widget _buildFieldCard(LapanganModel lapangan, NumberFormat fmt) {
    final img = lapangan.firstImage;
    return GestureDetector(
      onTap: () async {
        // Navigate to detail and wait for result
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetailLapanganScreen(lapangan: lapangan.toMap()),
          ),
        );
        // Refresh ratings when coming back from detail screen
        _fetchLapangans(type: _sportType, location: _locationController.text);
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
                              _ratings[lapangan.id] != null
                                  ? '${_ratings[lapangan.id]!.toStringAsFixed(1)} (${_reviewCounts[lapangan.id] ?? 0})'
                                  : '0.0 (0)',
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

  Widget _buildRecommendationCard(LapanganModel lapangan) {
    final img = lapangan.firstImage;
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailLapanganScreen(lapangan: lapangan.toMap()),
          ),
        );
        // Don't refresh recommendations - keep them cached
        // Recommendations stay the same after returning from detail
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with AI badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: img.isEmpty
                        ? Container(
                            color: AppColors.inputFill,
                            child: const Center(
                              child: Icon(Icons.image_not_supported_rounded,
                                  size: 36, color: AppColors.textSecondary),
                            ),
                          )
                        : _buildImage(img, height: 120),
                  ),
                ),
                // AI Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Cocok',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          lapangan.id != null && _ratings[lapangan.id!] != null && _ratings[lapangan.id!]! > 0
                              ? '${_ratings[lapangan.id!]!.toStringAsFixed(1)} (${_reviewCounts[lapangan.id!] ?? 0})'
                              : '0.0 (0)',
                          style: const TextStyle(
                            fontSize: 10,
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
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lapangan.namaLapangan,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getSportIcon(lapangan.jenis),
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lapangan.jenis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        fmt.format(lapangan.harga),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
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
