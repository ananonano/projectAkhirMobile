import 'package:flutter/material.dart';
import '../controllers/time_controller.dart';
import '../theme/app_theme.dart';

class TimeConverterScreen extends StatefulWidget {
  const TimeConverterScreen({super.key});

  @override
  State<TimeConverterScreen> createState() => _TimeConverterScreenState();
}

class _TimeConverterScreenState extends State<TimeConverterScreen> {
  final _controller = TimeController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _fromZone = 'WIB';
  String _toZone = 'London (GMT)';
  String _result = "--:--";

  void _convertTime() {
    setState(() {
      _result = _controller.convertTime(_selectedTime.hour, _selectedTime.minute, _fromZone, _toZone);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) {
      setState(() => _selectedTime = picked);
      _convertTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Konversi Zona Waktu')),
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
                    child: const Icon(Icons.public_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Konversi Zona Waktu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('WIB, WITA, WIT, London & lebih', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Time picker
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Waktu Asal', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Zone selectors
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Column(
                children: [
                  _zoneDropdown('Dari', _fromZone, (val) {
                    setState(() => _fromZone = val!);
                    _convertTime();
                  }),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_downward_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(height: 8),
                  _zoneDropdown('Ke', _toZone, (val) {
                    setState(() => _toZone = val!);
                    _convertTime();
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
                  const Text('Waktu di Tujuan', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(_result, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppColors.primary, fontFamily: 'Courier')),
                  const SizedBox(height: 4),
                  Text(_toZone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _convertTime,
                icon: const Icon(Icons.sync_rounded, size: 20),
                label: const Text('Konversi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoneDropdown(String label, String value, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: _controller.allZones.map((z) =>
              DropdownMenuItem(value: z, child: Text(z, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))
            ).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
