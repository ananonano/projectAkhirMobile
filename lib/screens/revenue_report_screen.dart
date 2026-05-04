import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectakhir/repositories/booking_repository.dart';
import 'package:projectakhir/theme/app_theme.dart';
import '../widgets/admin_drawer.dart';

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
                  padding: const EdgeInsets.fromLTRB(20, 45, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // Ringkasan Total
                const Text(
                  'Ringkasan',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                const SizedBox(height: 12),

                // Total Revenue Summary
                FutureBuilder<Map<String, dynamic>>(
                  future: _bookingRepo.getRevenueBreakdown(),
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
                        shadows: [
                          BoxShadow(
                            color: const Color(0x0C000000),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
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
                                  spacing: 4,
                                  children: [
                                    const Text(
                                      'Komisi App (10%)',
                                      style: TextStyle(
                                        color: Color(0xFF78716C),
                                        fontSize: 12,
                                        fontFamily: 'Lexend',
                                      ),
                                    ),
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
                                  spacing: 4,
                                  children: [
                                    const Text(
                                      'Pendapatan Partner (90%)',
                                      style: TextStyle(
                                        color: Color(0xFF78716C),
                                        fontSize: 12,
                                        fontFamily: 'Lexend',
                                      ),
                                    ),
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

                const SizedBox(height: 24),

                // Detail Per Lapangan
                const Text(
                  'Revenue Per Lapangan',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                const SizedBox(height: 12),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _bookingRepo.getRevenuePerLapangan(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (snapshot.hasError || snapshot.data == null) {
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
                              shadows: [
                                BoxShadow(
                                  color: const Color(0x0C000000),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 12,
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
                                          spacing: 4,
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
                                  Container(
                                    width: double.infinity,
                                    height: 1,
                                    color: const Color(0xFFE8E8E4),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 4,
                                        children: [
                                          const Text(
                                            'App Fee (10%)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF78716C),
                                              fontFamily: 'Lexend',
                                            ),
                                          ),
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
                                        spacing: 4,
                                        children: [
                                          const Text(
                                            'Partner (90%)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF78716C),
                                              fontFamily: 'Lexend',
                                            ),
                                          ),
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
}
