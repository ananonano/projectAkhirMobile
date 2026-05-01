import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/currency_controller.dart';
import '../theme/app_theme.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _amountController = TextEditingController();
  final _controller = CurrencyController();
  double _result = 0;
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';

  void _convert() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() => _result = _controller.convert(amount, _fromCurrency, _toCurrency));
  }

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convert();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat("#,##0.####");

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Konversi Mata Uang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Konversi Mata Uang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('10 mata uang tersedia', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Amount input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              onChanged: (_) => _convert(),
            ),

            const SizedBox(height: 20),

            // From / To with swap
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Column(
                children: [
                  _currencyDropdown('Dari', _fromCurrency, (val) {
                    setState(() => _fromCurrency = val!);
                    _convert();
                  }),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _swap,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 22),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _currencyDropdown('Ke', _toCurrency, (val) {
                    setState(() => _toCurrency = val!);
                    _convert();
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Result
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text('Hasil Konversi', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(
                    '${fmt.format(_result)} $_toCurrency',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '1 $_fromCurrency = ${fmt.format(_controller.convert(1, _fromCurrency, _toCurrency))} $_toCurrency',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyDropdown(String label, String value, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: _controller.allCurrencies.map((code) =>
              DropdownMenuItem(value: code, child: Text(code, style: const TextStyle(fontWeight: FontWeight.w700)))
            ).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
