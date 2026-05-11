import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/currency_controller.dart';
import '../controllers/voucher_controller.dart';
import '../models/voucher_model.dart';
import '../widgets/voucher_selector.dart';
import '../theme/app_theme.dart';
import 'receipt_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> lapangan;
  final DateTime selectedDate;
  final List<String> selectedTimes;

  const PaymentScreen({
    super.key,
    required this.lapangan,
    required this.selectedDate,
    required this.selectedTimes,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _authController = AuthController();
  final _bookingController = BookingController();
  final _currencyController = CurrencyController();
  final _voucherController = VoucherController();
  final _auth = LocalAuthentication();

  String _selectedCurrency = 'IDR';
  String _paymentMethod = 'QRIS / E-Wallet (Lokal)';
  List<VoucherModel> _availableVouchers = [];
  VoucherModel? _selectedVoucher;
  String _username = '';
  bool _isLoadingVouchers = true;

  @override
  void initState() {
    super.initState();
    _loadUserVouchers();
  }

  Future<void> _loadUserVouchers() async {
    try {
      final username = await _authController.getSessionUsername();
      final vouchers = await _voucherController.getUnusedVouchers(username);
      if (mounted) {
        setState(() {
          _username = username;
          _availableVouchers = vouchers;
          _isLoadingVouchers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading vouchers: $e');
      if (mounted) {
        setState(() => _isLoadingVouchers = false);
      }
    }
  }

  void _updateCurrency(String code) {
    setState(() {
      _selectedCurrency = code;
      if (_currencyController.isQrisSupported(code)) {
        _paymentMethod = code == 'IDR' ? 'QRIS / E-Wallet (Lokal)' : 'QRIS Antarnegara';
      } else {
        _paymentMethod = 'International Credit Card';
      }
    });
  }

  Future<void> _handlePaymentWithAuth() async {
    final isBioEnabled = await _authController.isBiometricEnabled(
      await _authController.getSessionUsername(),
    );
    if (!isBioEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Aktifkan Biometrik di Profil untuk bertransaksi!', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Konfirmasi pembayaran sewa lapangan dengan sidik jari',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (didAuthenticate) {
        _prosesBayar();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pembayaran dibatalkan: Autentikasi gagal.', style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error biometric payment: $e");
    }
  }

  Future<void> _prosesBayar() async {
    final int hargaPerJam = widget.lapangan['harga'] ?? 0;
    final userId = await _authController.getSessionUserId();
    try {
      await _bookingController.createBooking(
        userId: userId,
        lapanganId: widget.lapangan['id'],
        namaLapangan: widget.lapangan['nama_lapangan'],
        tanggal: widget.selectedDate,
        selectedTimes: widget.selectedTimes,
        hargaPerJam: hargaPerJam,
      );
      
      // Mark voucher as used if selected
      if (_selectedVoucher != null && _selectedVoucher!.id != null) {
        await _voucherController.useVoucher(_selectedVoucher!.id!);
      }
      
      final int totalHargaIDR = hargaPerJam * widget.selectedTimes.length;
      final double discountAmount = _selectedVoucher != null
          ? totalHargaIDR * (_selectedVoucher!.percentDiscount / 100)
          : 0;
      final int finalHargaIDR = (totalHargaIDR - discountAmount).toInt();
      
      final payment = _currencyController.calculatePayment(finalHargaIDR, _selectedCurrency);
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            namaLapangan: widget.lapangan['nama_lapangan'],
            tanggal: DateFormat('dd MMM yyyy').format(widget.selectedDate),
            jam: widget.selectedTimes.join(', '),
            totalDibayar: payment['totalConverted']!,
            mataUang: _selectedCurrency,
            metodeBayar: _paymentMethod,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal Bayar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int hargaPerJamIDR = int.tryParse(widget.lapangan['harga']?.toString() ?? '0') ?? 0;
    final int totalHargaIDR = hargaPerJamIDR * widget.selectedTimes.length;
    
    // Calculate discount from selected voucher
    final double discountAmount = _selectedVoucher != null
        ? totalHargaIDR * (_selectedVoucher!.percentDiscount / 100)
        : 0;
    final int finalHargaBeforeTax = (totalHargaIDR - discountAmount).toInt();
    
    final payment = _currencyController.calculatePayment(finalHargaBeforeTax, _selectedCurrency);
    final double pajakIDR = payment['tax']!;
    final double totalFinalIDR = payment['totalIDR']!;
    final double totalFinalKonversi = payment['totalConverted']!;
    final double currentTaxRate = payment['taxRate']!;
    final bool isQrisAvailable = _currencyController.isQrisSupported(_selectedCurrency);
    final fmt = NumberFormat("#,###");

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _sectionTitle('Detail Pesanan'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.lapangan['nama_lapangan'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  _orderRow(Icons.calendar_month_rounded, DateFormat('dd MMM yyyy').format(widget.selectedDate)),
                  const SizedBox(height: 8),
                  _orderRow(Icons.access_time_rounded, widget.selectedTimes.join(', ')),
                  const SizedBox(height: 8),
                  _orderRow(Icons.timer_rounded, '${widget.selectedTimes.length} jam'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Voucher Selector
            if (!_isLoadingVouchers && _availableVouchers.isNotEmpty) ...[
              _sectionTitle('Promo & Diskon'),
              const SizedBox(height: 10),
              VoucherSelector(
                availableVouchers: _availableVouchers,
                onVoucherSelected: (voucher) {
                  setState(() => _selectedVoucher = voucher);
                },
              ),
              const SizedBox(height: 20),
            ],

            // Currency
            _sectionTitle('Mata Uang Tagihan'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCurrency,
                  icon: const Icon(Icons.expand_more_rounded, color: AppColors.primary),
                  items: _currencyController.paymentCurrencies.map((e) =>
                    DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w700)))
                  ).toList(),
                  onChanged: (v) => _updateCurrency(v!),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment Method
            Row(
              children: [
                _sectionTitle('Metode Pembayaran'),
                if (isQrisAvailable) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(50)),
                    child: const Text('QRIS Ready', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                if (isQrisAvailable) ...[
                  _paymentMethodCard(
                    icon: Icons.qr_code_scanner_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: _selectedCurrency == 'IDR' ? 'QRIS / E-Wallet' : 'QRIS Cross-Border',
                    subtitle: _selectedCurrency == 'IDR' ? 'GoPay, OVO, Dana, ShopeePay' : 'Scan via aplikasi Bank/E-Wallet lokal',
                    value: _selectedCurrency == 'IDR' ? 'QRIS / E-Wallet (Lokal)' : 'QRIS Antarnegara',
                  ),
                  const SizedBox(height: 8),
                ],
                _paymentMethodCard(
                  icon: Icons.credit_card_rounded,
                  iconColor: Colors.orange,
                  title: 'Credit / Debit Card',
                  subtitle: 'Visa, Mastercard, AMEX, JCB',
                  value: 'International Credit Card',
                ),
                const SizedBox(height: 8),
                _paymentMethodCard(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  title: 'PayPal',
                  subtitle: 'Global Secure Payment',
                  value: 'PayPal',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Price Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  _priceRow('Harga Lapangan', 'Rp ${fmt.format(totalHargaIDR)}', false),
                  if (_selectedVoucher != null) ...[
                    const SizedBox(height: 8),
                    _priceRow(
                      'Diskon Voucher (${_selectedVoucher!.percentDiscount}%)',
                      '- Rp ${fmt.format(discountAmount.toInt())}',
                      true,
                      color: AppColors.success,
                    ),
                  ],
                  if (currentTaxRate > 0) ...[
                    const SizedBox(height: 8),
                    _priceRow('Biaya Layanan (${(currentTaxRate * 100).toStringAsFixed(1)}%)', '+ Rp ${fmt.format(pajakIDR)}', true),
                  ],
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL BAYAR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                      Text(
                        _selectedCurrency == 'IDR'
                            ? 'Rp ${fmt.format(totalFinalIDR)}'
                            : '$_selectedCurrency ${totalFinalKonversi.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _handlePaymentWithAuth,
              icon: const Icon(Icons.fingerprint_rounded, size: 22),
              label: const Text('Bayar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary));

  Widget _orderRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
    ],
  );

  Widget _paymentMethodCard({required IconData icon, required Color iconColor, required String title, required String subtitle, required String value}) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, bool isRed, {Color? color}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: color ?? (isRed ? Colors.red : AppColors.textSecondary), fontSize: 13)),
      Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color ?? (isRed ? Colors.red : AppColors.textPrimary), fontSize: 13)),
    ],
  );
}
