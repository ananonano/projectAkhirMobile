import 'package:intl/intl.dart';

/// Service untuk konversi zona waktu
/// Mendukung WIB, WITA, WIT, dan London (dengan DST)
class TimezoneService {
  // Offset dari UTC (dalam jam)
  static const int wibOffset = 7;  // UTC+7
  static const int witaOffset = 8; // UTC+8
  static const int witOffset = 9;  // UTC+9
  
  /// Konversi DateTime dari WIB ke zona waktu lain
  /// [wibDateTime] - waktu dalam zona WIB
  /// Returns Map dengan key: timezone name, value: DateTime
  static Map<String, DateTime> convertFromWIB(DateTime wibDateTime) {
    // Konversi WIB ke UTC dulu
    final utcDateTime = wibDateTime.subtract(const Duration(hours: wibOffset));
    
    return {
      'WIB': wibDateTime,
      'WITA': utcDateTime.add(const Duration(hours: witaOffset)),
      'WIT': utcDateTime.add(const Duration(hours: witOffset)),
      'London': _convertToLondon(utcDateTime),
    };
  }
  
  /// Konversi UTC ke London time dengan DST support
  static DateTime _convertToLondon(DateTime utcDateTime) {
    // Check if DST is active
    final isDST = _isDSTActive(utcDateTime);
    
    // London: UTC+0 (winter) atau UTC+1 (summer/DST)
    final offset = isDST ? 1 : 0;
    return utcDateTime.add(Duration(hours: offset));
  }
  
  /// Check apakah DST (Daylight Saving Time) aktif di UK
  /// DST di UK: Last Sunday of March 01:00 UTC sampai Last Sunday of October 01:00 UTC
  static bool _isDSTActive(DateTime utcDateTime) {
    final year = utcDateTime.year;
    
    // DST mulai: Last Sunday of March, 01:00 UTC
    final marchLastSunday = _getLastSundayOfMonth(year, 3);
    final dstStart = DateTime.utc(year, 3, marchLastSunday, 1, 0, 0);
    
    // DST berakhir: Last Sunday of October, 01:00 UTC
    final octoberLastSunday = _getLastSundayOfMonth(year, 10);
    final dstEnd = DateTime.utc(year, 10, octoberLastSunday, 1, 0, 0);
    
    // Check apakah tanggal berada dalam periode DST
    return utcDateTime.isAfter(dstStart) && utcDateTime.isBefore(dstEnd);
  }
  
  /// Get last Sunday of a month
  static int _getLastSundayOfMonth(int year, int month) {
    // Start from last day of month
    DateTime lastDay = DateTime.utc(year, month + 1, 0);
    
    // Go back until we find Sunday (weekday 7)
    while (lastDay.weekday != DateTime.sunday) {
      lastDay = lastDay.subtract(const Duration(days: 1));
    }
    
    return lastDay.day;
  }
  
  /// Format waktu untuk display di UI
  /// [dateTime] - DateTime object
  /// [timezone] - nama zona waktu (WIB, WITA, WIT, London)
  /// [showDate] - apakah tampilkan tanggal juga
  static String formatTime(DateTime dateTime, String timezone, {bool showDate = false}) {
    if (showDate) {
      // Format: "Senin, 15 Mei 2024 - 19:00 WIB"
      final dayName = _getDayName(dateTime.weekday);
      final monthName = _getMonthName(dateTime.month);
      final time = DateFormat('HH:mm').format(dateTime);
      return '$dayName, ${dateTime.day} $monthName ${dateTime.year} - $time $timezone';
    } else {
      // Format: "19:00 WIB"
      final time = DateFormat('HH:mm').format(dateTime);
      return '$time $timezone';
    }
  }
  
  /// Format untuk display multiple timezones
  /// Returns list of formatted strings
  static List<String> formatMultipleTimezones(DateTime wibDateTime, {bool showDate = false}) {
    final timezones = convertFromWIB(wibDateTime);
    
    return [
      formatTime(timezones['WIB']!, 'WIB', showDate: showDate),
      formatTime(timezones['WITA']!, 'WITA', showDate: showDate),
      formatTime(timezones['WIT']!, 'WIT', showDate: showDate),
      formatTime(timezones['London']!, 'London', showDate: showDate),
    ];
  }
  
  /// Get day name in Indonesian
  static String _getDayName(int weekday) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    return days[weekday - 1];
  }
  
  /// Get month name in Indonesian
  static String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }
  
  /// Check apakah ada perbedaan hari antara zona waktu
  /// Berguna untuk warning ke user
  static bool hasDayDifference(DateTime wibDateTime) {
    final timezones = convertFromWIB(wibDateTime);
    
    final wibDay = timezones['WIB']!.day;
    final londonDay = timezones['London']!.day;
    
    return wibDay != londonDay;
  }
  
  /// Get timezone info untuk display
  static String getTimezoneInfo(String timezone) {
    switch (timezone) {
      case 'WIB':
        return 'Waktu Indonesia Barat (UTC+7)';
      case 'WITA':
        return 'Waktu Indonesia Tengah (UTC+8)';
      case 'WIT':
        return 'Waktu Indonesia Timur (UTC+9)';
      case 'London':
        return 'London Time (UTC+0/+1)';
      default:
        return timezone;
    }
  }
}
