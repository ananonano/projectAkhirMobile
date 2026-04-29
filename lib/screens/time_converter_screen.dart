import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeConverterScreen extends StatefulWidget {
  const TimeConverterScreen({super.key});

  @override
  State<TimeConverterScreen> createState() => _TimeConverterScreenState();
}

class _TimeConverterScreenState extends State<TimeConverterScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _fromZone = 'WIB';
  String _toZone = 'WITA';
  String _result = "--:--";

  // Offset zona waktu terhadap UTC/GMT
  final Map<String, int> _timeOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London (GMT)': 0,
    'Tokyo (JST)': 9,
    'New York (EST)': -5,
  };

  void _convertTime() {
    // 1. Ambil jam dan menit dari picker
    final now = DateTime.now();
    final dtFrom = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);

    // 2. Hitung selisih jam antar zona
    int offsetFrom = _timeOffsets[_fromZone]!;
    int offsetTo = _timeOffsets[_toZone]!;
    int diff = offsetTo - offsetFrom;

    // 3. Tambahkan selisih ke waktu asal
    final dtTo = dtFrom.add(Duration(hours: diff));
    
    setState(() {
      _result = DateFormat('HH:mm').format(dtTo);
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      _convertTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konversi Waktu Dunia'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Tombol Pilih Waktu
            ListTile(
              title: const Text("Waktu Asal"),
              subtitle: Text(_selectedTime.format(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Dropdown Pilih Zona
            Row(
              children: [
                Expanded(child: _buildDropdown("Dari", _fromZone, (val) => setState(() => _fromZone = val!))),
                const Icon(Icons.arrow_forward, color: Colors.orange),
                Expanded(child: _buildDropdown("Ke", _toZone, (val) => setState(() => _toZone = val!))),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Box Hasil
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  const Text("Waktu di Lokasi Tujuan:"),
                  const SizedBox(height: 10),
                  Text(_result, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.orange)),
                  Text(_toZone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: _timeOffsets.keys.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
          onChanged: (val) {
            onChanged(val);
            _convertTime();
          },
        ),
      ],
    );
  }
}