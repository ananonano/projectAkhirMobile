import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectakhir/repositories/booking_repository.dart';
import 'package:projectakhir/theme/app_theme.dart';
import '../widgets/admin_drawer.dart';

enum RevenueFilter { overall, monthly, daily }

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  RevenueFilter _selectedFilter = RevenueFilter.overall;
  DateTime _selectedDate = DateTime.now();

  String get _filterTitle {
    switch (_selectedFilter) {
      case RevenueFilter.overall:
        return 'Overall';
      case RevenueFilter.monthly:
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case RevenueFilter.daily:
        return DateFormat('dd MMM yyyy').format(_selectedDate);
    }
  }

  Future<void> _selectDate() async {
    if (_selectedFilter == RevenueFilter.monthly) {
      // Month picker - custom dialog
      await _showMonthPicker();
    } else if (_selectedFilter == RevenueFilter.daily) {
      // Day picker
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }
  }

  Future<void> _showMonthPicker() async {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    // Generate years from 2020 to current year
    final years = List.generate(now.year - 2019, (index) => 2020 + index);
    
    int selectedMonth = _selectedDate.month;
    int selectedYear = _selectedDate.year;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Pilih Bulan',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8E8E4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: years.reversed.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(
                          year.toString(),
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedYear = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Month grid
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = month == selectedMonth && selectedYear == _selectedDate.year;
                    
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedMonth = month;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFE8E8E4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            months[index].substring(0, 3),
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF78716C),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  color: Color(0xFF78716C),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(selectedYear, selectedMonth, 1);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAF5),
      drawer: AdminDrawer(
        activeMenu: AdminMenuIndex.revenue,
        scaffoldKey: _scaffoldKey,
      ),
      body: Stack(
        children: [
          // Konten utama dengan padding atas untuk header
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC2C8BF),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter Periode',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1C1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _FilterChip(
                                    label: 'Overall',
                                    isSelected: _selectedFilter == RevenueFilter.overall,
                                    onTap: () {
                                      setState(() {
                                        _selectedFilter = RevenueFilter.overall;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _FilterChip(
                                    label: 'Per Bulan',
                                    isSelected: _selectedFilter == RevenueFilter.monthly,
                                    onTap: () {
                                      setState(() {
                                        _selectedFilter = RevenueFilter.monthly;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _FilterChip(
                                    label: 'Per Hari',
                                    isSelected: _selectedFilter == RevenueFilter.daily,
                                    onTap: () {
                                      setState(() {
                                        _selectedFilter = RevenueFilter.daily;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedFilter != RevenueFilter.overall) ...[
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F1EC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE8E8E4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _filterTitle,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Lexend',
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1C1A),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: Color(0xFF6B8F71),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Ringkasan Total
                      Text(
                        'Ringkasan $_filterTitle',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1C1A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Total Revenue Summary
                      FutureBuilder<Map<String, dynamic>>(
                        future: _getFilteredRevenue(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            );
                          }

                          final data = snapshot.data ?? {};
                          final total = data['totalRevenue'] as int? ?? 0;
                          final appFee = data['appFee'] as int? ?? 0;
                          final partner = data['partnerRevenue'] as int? ?? 0;

                          return Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  width: 1,
                                  color: Color(0xFFC2C8BF),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x0C000000),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Pendapatan',
                                        style: TextStyle(
                                          color: Color(0xFF78716C),
                                          fontSize: 12,
                                          fontFamily: 'Lexend',
                                        ),
                                      ),
                                      Text(
                                        'Rp ${NumberFormat('#,###').format(total)}',
                                        style: const TextStyle(
                                          color: Color(0xFF1A1C1A),
                                          fontSize: 18,
                                          fontFamily: 'Lexend',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    height: 1,
                                    color: const Color(0xFFE8E8E4),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Komisi App (10%)',
                                            style: TextStyle(
                                              color: Color(0xFF78716C),
                                              fontSize: 12,
                                              fontFamily: 'Lexend',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rp ${NumberFormat('#,###').format(appFee)}',
                                            style: const TextStyle(
                                              color: Color(0xFF1A1C1A),
                                              fontSize: 16,
                                              fontFamily: 'Lexend',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Pendapatan Partner (90%)',
                                            style: TextStyle(
                                              color: Color(0xFF78716C),
                                              fontSize: 12,
                                              fontFamily: 'Lexend',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rp ${NumberFormat('#,###').format(partner)}',
                                            style: const TextStyle(
                                              color: Color(0xFF1A1C1A),
                                              fontSize: 16,
                                              fontFamily: 'Lexend',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Detail Per Lapangan
                      Text(
                        'Revenue Per Lapangan ($_filterTitle)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1C1A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getFilteredRevenuePerLapangan(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            );
                          }

                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(
                                  color: Color(0xFFD84040),
                                  fontFamily: 'Lexend',
                                ),
                              ),
                            );
                          }

                          final revenueData = snapshot.data ?? [];

                          if (revenueData.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFC2C8BF),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 48,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Belum ada data pendapatan',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontFamily: 'Lexend',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: revenueData.length,
                            itemBuilder: (context, index) {
                              final item = revenueData[index];
                              final lapanganName = item['nama_lapangan'] ?? 'Unknown';
                              final bookings = item['total_bookings'] as int? ?? 0;
                              final revenue =
                                  int.tryParse(item['total_revenue'].toString()) ?? 0;
                              final appFee = (revenue * 0.1).toInt();
                              final partnerRevenue = revenue - appFee;

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == revenueData.length - 1 ? 0 : 16,
                                ),
                                child: Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      side: const BorderSide(
                                        width: 1,
                                        color: Color(0xFFC2C8BF),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    shadows: const [
                                      BoxShadow(
                                        color: Color(0x0C000000),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    lapanganName,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontFamily: 'Lexend',
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF1A1C1A),
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '$bookings booking',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF78716C),
                                                      fontFamily: 'Lexend',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFC5ECC9),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Rp ${NumberFormat('#,###').format(revenue)}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontFamily: 'Lexend',
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF416448),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          height: 1,
                                          color: const Color(0xFFE8E8E4),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'App Fee (10%)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF78716C),
                                                    fontFamily: 'Lexend',
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Rp ${NumberFormat('#,###').format(appFee)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontFamily: 'Lexend',
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1A1C1A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  'Partner (90%)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF78716C),
                                                    fontFamily: 'Lexend',
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Rp ${NumberFormat('#,###').format(partnerRevenue)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontFamily: 'Lexend',
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1A1C1A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Fixed Header Bar dengan hamburger menu
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBar(
              title: 'Laporan Revenue',
              scaffoldKey: _scaffoldKey,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getFilteredRevenue() async {
    final allBookings = await _bookingRepo.getAllBookings();
    final filteredBookings = _filterBookings(allBookings);
    
    int totalRevenue = 0;
    for (var booking in filteredBookings) {
      final harga = int.tryParse(booking['total_harga'].toString()) ?? 0;
      totalRevenue += harga;
    }
    
    final appFee = (totalRevenue * 0.1).toInt();
    final partnerRevenue = totalRevenue - appFee;
    
    return {
      'totalRevenue': totalRevenue,
      'appFee': appFee,
      'partnerRevenue': partnerRevenue,
    };
  }

  Future<List<Map<String, dynamic>>> _getFilteredRevenuePerLapangan() async {
    final allBookings = await _bookingRepo.getAllBookings();
    final filteredBookings = _filterBookings(allBookings);
    
    // Group by lapangan
    final Map<int, Map<String, dynamic>> lapanganRevenue = {};
    
    for (var booking in filteredBookings) {
      final lapanganId = booking['lapangan_id'] as int;
      final harga = int.tryParse(booking['total_harga'].toString()) ?? 0;
      
      if (!lapanganRevenue.containsKey(lapanganId)) {
        lapanganRevenue[lapanganId] = {
          'id': lapanganId,
          'nama_lapangan': booking['nama_lapangan'],
          'total_bookings': 0,
          'total_revenue': 0,
        };
      }
      
      lapanganRevenue[lapanganId]!['total_bookings'] = 
          (lapanganRevenue[lapanganId]!['total_bookings'] as int) + 1;
      lapanganRevenue[lapanganId]!['total_revenue'] = 
          (lapanganRevenue[lapanganId]!['total_revenue'] as int) + harga;
    }
    
    final result = lapanganRevenue.values.toList();
    result.sort((a, b) => (b['total_revenue'] as int).compareTo(a['total_revenue'] as int));
    
    return result;
  }

  List<Map<String, dynamic>> _filterBookings(List<Map<String, dynamic>> bookings) {
    if (_selectedFilter == RevenueFilter.overall) {
      return bookings;
    }
    
    return bookings.where((booking) {
      final tanggalStr = booking['tanggal'] as String?;
      if (tanggalStr == null) return false;
      
      try {
        // Parse "dd MMM yyyy" format
        final bookingDate = DateFormat('dd MMM yyyy').parse(tanggalStr);
        
        if (_selectedFilter == RevenueFilter.monthly) {
          return bookingDate.year == _selectedDate.year &&
                 bookingDate.month == _selectedDate.month;
        } else if (_selectedFilter == RevenueFilter.daily) {
          return bookingDate.year == _selectedDate.year &&
                 bookingDate.month == _selectedDate.month &&
                 bookingDate.day == _selectedDate.day;
        }
      } catch (e) {
        print('[Revenue] Error parsing date: $tanggalStr - $e');
        return false;
      }
      
      return false;
    }).toList();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE8E8E4),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF78716C),
            ),
          ),
        ),
      ),
    );
  }
}
