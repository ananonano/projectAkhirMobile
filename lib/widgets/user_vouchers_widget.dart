import 'package:flutter/material.dart';
import '../controllers/voucher_controller.dart';
import '../models/voucher_model.dart';
import '../theme/app_theme.dart';

class UserVouchersWidget extends StatefulWidget {
  final String username;

  const UserVouchersWidget({super.key, required this.username});

  @override
  State<UserVouchersWidget> createState() => _UserVouchersWidgetState();
}

class _UserVouchersWidgetState extends State<UserVouchersWidget> {
  final VoucherController _controller = VoucherController();
  List<VoucherModel> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      print('[UserVouchers] Loading vouchers for: ${widget.username}');
      final vouchers = await _controller.getUserVouchers(widget.username);
      print('[UserVouchers] Loaded ${vouchers.length} vouchers');
      if (mounted) {
        setState(() => _vouchers = vouchers);
      }
    } catch (e) {
      print('[UserVouchers] Error loading: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_vouchers.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_offer_rounded, size: 48, color: AppColors.primary.withOpacity(0.3)),
                const SizedBox(height: 12),
                const Text(
                  'Belum ada voucher',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mainkan Dodge Ball untuk mendapatkan voucher!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vouchers.length,
            itemBuilder: (context, index) {
              final voucher = _vouchers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
                  border: Border.all(
                    color: voucher.isUsed ? Colors.grey.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.primary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${voucher.percentDiscount}%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                'OFF',
                                style: TextStyle(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Score: ${voucher.earnedScore}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: voucher.isUsed ? Colors.grey.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    voucher.isUsed ? '✓ Terpakai' : 'Tersedia',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: voucher.isUsed ? Colors.grey : Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Didapat: ${voucher.createdAt.split('T')[0]}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                            if (voucher.usedAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Digunakan: ${voucher.usedAt!.split('T')[0]}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
