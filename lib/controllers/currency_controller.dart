/// Mengelola logika konversi mata uang
/// Dipakai oleh CurrencyConverterScreen dan PaymentScreen
class CurrencyController {
  // Nilai kurs: harga 1 unit mata uang tersebut dalam IDR
  static const Map<String, double> rates = {
    'IDR': 1.0,
    'USD': 16250.0,
    'SGD': 11950.0,
    'EUR': 17400.0,
    'JPY': 105.0,
    'GBP': 20300.0,
    'AUD': 10600.0,
    'CNY': 2250.0,
    'KRW': 11.8,
    'MYR': 3420.0,
    'THB': 435.0,
    'PHP': 285.0,
  };

  // Biaya layanan internasional per mata uang (0.0 = tidak ada biaya)
  static const Map<String, double> taxRates = {
    'IDR': 0.0,
    'USD': 0.025,
    'SGD': 0.015,
    'EUR': 0.025,
    'JPY': 0.015,
    'GBP': 0.025,
    'AUD': 0.02,
    'CNY': 0.02,
    'KRW': 0.015,
    'MYR': 0.015,
    'THB': 0.015,
    'PHP': 0.06,
  };

  // Mata uang yang support QRIS cross-border
  static const List<String> qrisSupportedCurrencies = ['IDR', 'SGD', 'THB'];

  // Konversi nominal dari satu mata uang ke mata uang lain
  double convert(double amount, String fromCurrency, String toCurrency) {
    final fromRate = rates[fromCurrency] ?? 1.0;
    final toRate = rates[toCurrency] ?? 1.0;
    return (amount * fromRate) / toRate;
  }

  // Hitung total harga booking dalam mata uang tertentu (termasuk biaya layanan)
  Map<String, double> calculatePayment(int baseAmountIDR, String currency) {
    final taxRate = taxRates[currency] ?? 0.0;
    final tax = baseAmountIDR * taxRate;
    final totalIDR = baseAmountIDR + tax;
    final exchangeRate = 1.0 / (rates[currency] ?? 1.0);
    final totalConverted = totalIDR * exchangeRate;

    return {
      'baseAmount': baseAmountIDR.toDouble(),
      'tax': tax,
      'totalIDR': totalIDR,
      'exchangeRate': exchangeRate,
      'totalConverted': totalConverted,
      'taxRate': taxRate,
    };
  }

  // Cek apakah mata uang support QRIS
  bool isQrisSupported(String currency) {
    return qrisSupportedCurrencies.contains(currency);
  }

  // Daftar mata uang yang tersedia untuk PaymentScreen
  List<String> get paymentCurrencies => ['IDR', 'USD', 'SGD', 'THB', 'PHP'];

  // Daftar semua mata uang untuk CurrencyConverterScreen
  List<String> get allCurrencies => rates.keys.toList();
}
