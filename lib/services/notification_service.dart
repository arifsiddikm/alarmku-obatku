import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medicine.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._init();

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      // Hardcode WIB — tidak perlu flutter_timezone
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (e) {
      debugPrint('Notif init error: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkPermission() async {
    if (kIsWeb) return true;
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> scheduleForMedicine(Medicine medicine) async {
    if (kIsWeb || !medicine.isActive || medicine.id == null) return;
    try {
      await cancelForMedicine(medicine);

      final timeParts = medicine.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'alarmku_channel',
          'Pengingat Minum Obat',
          channelDescription: 'Notifikasi jadwal minum obat',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
        ),
      );

      if (medicine.isRepeat && medicine.days.isNotEmpty) {
        for (final day in medicine.days) {
          await _plugin.zonedSchedule(
            _notifId(medicine.id!, day),
            '💊 Waktunya minum obat!',
            '${medicine.name} — ${medicine.dosage}',
            _nextDayTime(day, hour, minute),
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      } else {
        final now = tz.TZDateTime.now(tz.local);
        tz.TZDateTime scheduled = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, hour, minute);
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          _notifId(medicine.id!, 0),
          '💊 Waktunya minum obat!',
          '${medicine.name} — ${medicine.dosage}',
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Schedule notif error: $e');
    }
  }

  Future<void> cancelForMedicine(Medicine medicine) async {
    if (kIsWeb || medicine.id == null) return;
    try {
      for (int d = 0; d <= 7; d++) {
        await _plugin.cancel(_notifId(medicine.id!, d));
      }
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  tz.TZDateTime _nextDayTime(int day, int hour, int minute) {
    tz.TZDateTime dt = tz.TZDateTime.now(tz.local);
    dt = tz.TZDateTime(tz.local, dt.year, dt.month, dt.day, hour, minute);
    while (dt.weekday != day || dt.isBefore(tz.TZDateTime.now(tz.local))) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  int _notifId(int medicineId, int day) => medicineId * 10 + day;

  String? countdownText(Medicine medicine) {
    if (!medicine.isActive) return null;
    final timeParts = medicine.time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, now.day, hour, minute);

    if (medicine.isRepeat && medicine.days.isNotEmpty) {
      for (int i = 0; i <= 7; i++) {
        final candidate = next.add(Duration(days: i));
        if (medicine.days.contains(candidate.weekday) &&
            candidate.isAfter(now)) {
          next = candidate;
          break;
        }
      }
    } else {
      if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    }

    final diff = next.difference(now);
    if (diff.inMinutes < 1) return 'Sebentar lagi';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lagi';
    if (diff.inDays < 1) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return m > 0 ? '${h}j ${m}m lagi' : '${h} jam lagi';
    }
    return '${diff.inDays} hari lagi';
  }
}
