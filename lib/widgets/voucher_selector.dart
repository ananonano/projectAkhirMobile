import 'package:flutter/material.dart';
import '../models/voucher_model.dart';
import '../theme/app_theme.dart';

class VoucherSelector extends StatefulWidget {
  final List<VoucherModel> availableVouchers;
  final Function(VoucherModel?) onVoucherSelected;

  const VoucherSelector({
    super.key,
    required this.availableVouchers,
    required this.onVoucherSelected,
  });

  @override
  State<VoucherSelector> createState() => _VoucherSelectorState();
}

class _VoucherSelectorState extends State<VoucherSelector> {
  VoucherModel? _selectedVoucher;

  @override
  Widget build(BuildContext context) {
    if (widget.availableVouchers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Pilih Voucher',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.availableVouchers.length,
            itemBuilder: (context, index) {
              final voucher = widget.availableVouchers[index];
              final isSelected = _selectedVoucher?.id == voucher.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVoucher = isSelected ? null : voucher;
                  });
                  widget.onVoucherSelected(_selectedVoucher);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                    border: isSelected
                        ? Border(
                            bottom: BorderSide(
                              color: index < widget.availableVouchers.length - 1 ? AppColors.border : Colors.transparent,
                            ),
                          )
                        : Border(
                            bottom: BorderSide(
                              color: index < widget.availableVouchers.length - 1 ? AppColors.border : Colors.transparent,
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${voucher.percentDiscount}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${voucher.percentDiscount}% Diskon',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Score: ${voucher.earnedScore}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 2,
                          ),
                          color: isSelected ? AppColors.primary : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
