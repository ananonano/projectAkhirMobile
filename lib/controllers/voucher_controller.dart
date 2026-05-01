import '../models/voucher_model.dart';
import '../repositories/voucher_repository.dart';

class VoucherController {
  final VoucherRepository _repo = VoucherRepository();

  // Get user's vouchers
  Future<List<VoucherModel>> getUserVouchers(String username) async {
    return _repo.getUserVouchers(username);
  }

  // Get unused vouchers for booking/payment
  Future<List<VoucherModel>> getUnusedVouchers(String username) async {
    return _repo.getUnusedVouchers(username);
  }

  // Award voucher from dodge ball score
  // Returns voucher created (if any), or null if no voucher earned
  Future<VoucherModel?> awardVoucherFromDodgeBall(String username, int score) async {
    // Check if score is at least 1000
    if (score < 1000) return null;

    // Calculate discount percentage (1000 = 1%, 2000 = 2%, etc)
    int percentDiscount = (score / 1000).floor();

    // Cap at 10% max for single game
    if (percentDiscount > 10) percentDiscount = 10;

    // Check if already has voucher from same score
    bool hasExisting = await _repo.hasVoucherFromScore(username, score);
    if (hasExisting) return null;

    // Create new voucher
    final voucher = VoucherModel(
      username: username,
      percentDiscount: percentDiscount,
      earnedScore: score,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _repo.createVoucher(voucher);
    return voucher;
  }

  // Use voucher for booking
  Future<void> useVoucher(int voucherId) async {
    await _repo.useVoucher(voucherId);
  }

  // Get voucher by ID
  Future<VoucherModel?> getVoucher(int id) async {
    return _repo.getVoucherById(id);
  }

  // Delete voucher (admin only)
  Future<void> deleteVoucher(int id) async {
    await _repo.deleteVoucher(id);
  }

  // Get all vouchers (admin management)
  Future<List<VoucherModel>> getAllVouchers() async {
    return _repo.getAllVouchers();
  }

  // Calculate discount amount
  int calculateDiscount(int percentDiscount, int totalAmount) {
    return (totalAmount * percentDiscount / 100).toInt();
  }
}
