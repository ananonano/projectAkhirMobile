import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectakhir/repositories/review_repository.dart';
import 'package:projectakhir/theme/app_theme.dart';
import '../widgets/admin_drawer.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final ReviewRepository _reviewRepo = ReviewRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadReviews() {
    setState(() {
      _reviewsFuture = _reviewRepo.getAllRecentReviews(limit: 1000); // Load all reviews
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAF5),
      drawer: AdminDrawer(
        activeMenu: AdminMenuIndex.dashboard,
        scaffoldKey: _scaffoldKey,
      ),
      body: Stack(
        children: [
          // Konten utama dengan padding atas untuk header + search bar
          Padding(
            padding: const EdgeInsets.only(top: 150), // Increased for search bar
            child: RefreshIndicator(
              onRefresh: () async {
                _loadReviews();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _reviewsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allReviewsData = snapshot.data ?? [];
                  
                  // Create mutable copy and sort by ID descending (newest first)
                  final allReviews = List<Map<String, dynamic>>.from(allReviewsData);
                  allReviews.sort((a, b) {
                    final idA = a['id'] ?? 0;
                    final idB = b['id'] ?? 0;
                    return idB.compareTo(idA); // Descending order
                  });
                  
                  // Filter reviews based on search query
                  final reviews = allReviews.where((review) {
                    if (_searchQuery.isEmpty) return true;
                    
                    final userName = (review['user_name'] ?? '').toString().toLowerCase();
                    final lapanganName = (review['lapangan_name'] ?? '').toString().toLowerCase();
                    final comment = (review['comment'] ?? '').toString().toLowerCase();
                    final rating = (review['rating'] ?? '').toString();
                    final createdAt = (review['created_at'] ?? '').toString().toLowerCase();
                    
                    return userName.contains(_searchQuery) ||
                           lapanganName.contains(_searchQuery) ||
                           comment.contains(_searchQuery) ||
                           rating.contains(_searchQuery) ||
                           createdAt.contains(_searchQuery);
                  }).toList();

                  if (reviews.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty 
                                ? Icons.search_off_rounded 
                                : Icons.rate_review_rounded,
                            size: 60, 
                            color: Colors.grey[300]
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? 'Tidak ada hasil untuk "$_searchQuery"'
                                : 'Belum ada review',
                            style: TextStyle(
                              color: Colors.grey[600], 
                              fontSize: 14,
                              fontFamily: 'Lexend',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == reviews.length - 1 ? 0 : 16,
                        ),
                        child: _ReviewCard(review: review),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Fixed Header Bar dengan hamburger menu
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBar(
              title: 'Semua Review',
              scaffoldKey: _scaffoldKey,
            ),
          ),
          
          // Search Bar
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFFFAFAF5),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE8E8E4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0C000000),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari user, lapangan, rating, komentar...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontFamily: 'Lexend',
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Lexend',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] ?? 0;
    final userName = review['user_name'] ?? 'User';
    final lapanganName = review['lapangan_name'] ?? 'Lapangan';
    final comment = review['comment'] ?? 'No comment';
    final createdAt = review['created_at'] ?? '';
    
    // Format date if available
    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
      } catch (e) {
        formattedDate = createdAt;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC2C8BF),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User name and Rating stars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Color(0xFF1A1C1A),
                        fontSize: 14,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lapanganName,
                      style: const TextStyle(
                        color: Color(0xFF78716C),
                        fontSize: 12,
                        fontFamily: 'Lexend',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Rating stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < rating ? const Color(0xFFFFA726) : const Color(0xFFE0E0E0),
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFE8E8E4),
          ),
          const SizedBox(height: 12),
          // Comment
          Text(
            comment,
            style: const TextStyle(
              color: Color(0xFF1A1C1A),
              fontSize: 13,
              fontFamily: 'Lexend',
              height: 1.5,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontFamily: 'Lexend',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
