import 'package:flutter/material.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _result = 0;
  
  // State untuk dropdown "Dari" dan "Ke"
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';

  // Data 10 Mata Uang dengan nilai kurs relatif terhadap 1 IDR (Statis)
  // Tips: Angka ini adalah harga 1 mata uang tersebut dalam Rupiah
  final Map<String, double> _rates = {
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
  };

  void _convert() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    
    setState(() {
      // Logika: (Jumlah * Nilai Kurs Asal) / Nilai Kurs Tujuan
      // Contoh: (1 USD * 16250) / 11950 (SGD) = 1.35 SGD
      _result = (amount * _rates[_fromCurrency]!) / _rates[_toCurrency]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konversi Mata Uang Pro'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Input Nominal
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Masukkan Nominal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calculate),
              ),
              onChanged: (value) => _convert(), // Langsung konversi pas ngetik
            ),
            const SizedBox(height: 25),

            // Dropdown "DARI"
            _buildDropdownTile(
              label: "Dari Mata Uang:",
              value: _fromCurrency,
              onChanged: (val) {
                setState(() => _fromCurrency = val!);
                _convert();
              },
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Icon(Icons.swap_vert, size: 40, color: Colors.green),
            ),

            // Dropdown "KE"
            _buildDropdownTile(
              label: "Ke Mata Uang:",
              value: _toCurrency,
              onChanged: (val) {
                setState(() => _toCurrency = val!);
                _convert();
              },
            ),

            const SizedBox(height: 40),

            // Tampilan Hasil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  const Text('Hasil Konversi:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(
                    '${_result.toStringAsFixed(2)} $_toCurrency',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.green
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

  // Widget bantuan biar dropdown-nya rapi
  Widget _buildDropdownTile({
    required String label, 
    required String value, 
    required ValueChanged<String?> onChanged
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: _rates.keys.map((String code) {
            return DropdownMenuItem(value: code, child: Text(code));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}