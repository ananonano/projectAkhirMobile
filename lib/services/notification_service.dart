import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Service untuk mengelola notifikasi lokal
/// Dipakai setelah booking berhasil untuk kirim reminder sebelum main
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Inisialisasi plugin — dipanggil sekali di main.dart
  Future<void> init() async {
    if (_isInitialized) return;

    // Inisialisasi timezone database
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // Default WIB

    // Konfigurasi Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Konfigurasi iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _isInitialized = true;
  }

  // Minta izin notifikasi (Android 13+)
  Future<bool> requestPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  // Kirim notifikasi langsung (immediate) — dipakai saat booking berhasil
  Future<void> showBookingConfirmation({
    required String namaLapangan,
    required String tanggal,
    required String jam,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'booking_channel',
      'Booking Lapangan',
      channelDescription: 'Notifikasi konfirmasi dan reminder booking lapangan',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      0, // ID notifikasi
      '✅ Booking Berhasil!',
      '$namaLapangan • $tanggal pukul $jam',
      notifDetails,
    );
  }

  // Jadwalkan notifikasi reminder 1 jam sebelum main
  Future<void> scheduleBookingReminder({
    required int bookingId,
    required String namaLapangan,
    required String tanggal,   // format: "dd MMM yyyy"
    required String jamMulai,  // format: "HH:mm"
  }) async {
    await _ensureInitialized();

    // Parse waktu booking
    final scheduledTime = _parseBookingTime(tanggal, jamMulai);
    if (scheduledTime == null) return;

    // Reminder 1 jam sebelum
    final reminderTime = scheduledTime.subtract(const Duration(hours: 1));
    final now = DateTime.now();

    // Kalau waktu reminder sudah lewat, skip scheduling
    if (reminderTime.isBefore(now)) return;

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminder Booking',
      channelDescription: 'Pengingat 1 jam sebelum jadwal main',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      bookingId, // Pakai bookingId sebagai ID notifikasi biar unik
      '⏰ Reminder: 1 Jam Lagi Main!',
      '$namaLapangan siap menunggumu pukul $jamMulai',
      tz.TZDateTime.from(reminderTime, tz.local),
      notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,

    );
  }

  // Batalkan notifikasi berdasarkan ID
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  // Batalkan semua notifikasi
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // Helper: parse string tanggal + jam jadi DateTime
  DateTime? _parseBookingTime(String tanggal, String jamMulai) {
    try {
      // Format tanggal: "01 May 2026", jam: "09:00"
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
        'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
        'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };

      final parts = tanggal.split(' ');
      final day = int.parse(parts[0]);
      final month = months[parts[1]] ?? 1;
      final year = int.parse(parts[2]);

      final timeParts = jamMulai.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await init();
  }
}
