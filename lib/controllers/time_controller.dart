import 'package:intl/intl.dart';

/// Mengelola logika konversi zona waktu
/// Dipakai oleh TimeConverterScreen dan ProfileScreen
class TimeController {
  // Offset UTC per zona waktu (dalam jam)
  static const Map<String, int> timeZoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London (GMT)': 0,
    'Tokyo (JST)': 9,
    'New York (EST)': -5,
  };

  // Offset yang ditampilkan di ProfileScreen (subset)
  static const Map<String, int> profileTimeZones = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  // Konversi waktu dari satu zona ke zona lain
  String convertTime(int hour, int minute, String fromZone, String toZone) {
    final offsetFrom = timeZoneOffsets[fromZone] ?? 7;
    final offsetTo = timeZoneOffsets[toZone] ?? 7;
    final diff = offsetTo - offsetFrom;

    final now = DateTime.now();
    final dtFrom = DateTime(now.year, now.month, now.day, hour, minute);
    final dtTo = dtFrom.add(Duration(hours: diff));

    return DateFormat('HH:mm').format(dtTo);
  }

  // Ambil waktu sekarang dalam zona tertentu (untuk jam real-time di ProfileScreen)
  String getCurrentTimeInZone(String zone, {Map<String, int>? customOffsets}) {
    final offsets = customOffsets ?? profileTimeZones;
    final offset = offsets[zone] ?? 7;
    final zoneTime = DateTime.now().toUtc().add(Duration(hours: offset));
    return DateFormat('HH:mm:ss').format(zoneTime);
  }

  // Daftar zona waktu untuk TimeConverterScreen
  List<String> get allZones => timeZoneOffsets.keys.toList();

  // Daftar zona waktu untuk ProfileScreen
  List<String> get profileZones => profileTimeZones.keys.toList();
}
