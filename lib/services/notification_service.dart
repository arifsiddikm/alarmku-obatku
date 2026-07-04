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

  static const _channelId = 'alarmku_v2';
  static const _channelName = 'Pengingat Minum Obat';

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('[AlarmKu] Notif tapped: ${details.payload}');
        },
      );

      // Buat channel Android dengan importance MAX
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Notifikasi jadwal minum obat AlarmKu',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );

      _initialized = true;
      debugPrint('[AlarmKu] NotificationService initialized OK');
    } catch (e) {
      debugPrint('[AlarmKu] Notif init error: $e');
    }
  }

  // Request semua permission yang dibutuhkan
  Future<Map<String, bool>> requestAllPermissions() async {
    if (kIsWeb) return {'notification': true};

    final results = <String, bool>{};

    try {
      // 1. Notifikasi (Android 13+)
      final notifStatus = await Permission.notification.request();
      results['notification'] = notifStatus.isGranted;
      debugPrint('[AlarmKu] Notification permission: ${notifStatus.name}');

      // 2. Exact Alarm (Android 12+)
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final exactAlarm =
          await androidPlugin?.requestExactAlarmsPermission() ?? false;
      results['exact_alarm'] = exactAlarm;
      debugPrint('[AlarmKu] Exact alarm permission: $exactAlarm');
    } catch (e) {
      debugPrint('[AlarmKu] Permission request error: $e');
    }

    return results;
  }

  Future<bool> checkPermission() async {
    if (kIsWeb) return true;
    try {
      final granted = await Permission.notification.isGranted;
      debugPrint('[AlarmKu] Notification granted: $granted');
      return granted;
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

      debugPrint(
          '[AlarmKu] Scheduling: ${medicine.name} at ${medicine.time} days=${medicine.days} repeat=${medicine.isRepeat}');

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notifikasi jadwal minum obat',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          autoCancel: true,
        ),
      );

      if (medicine.isRepeat && medicine.days.isNotEmpty) {
        for (final day in medicine.days) {
          final scheduled = _nextDayTime(day, hour, minute);
          final notifId = _notifId(medicine.id!, day);
          debugPrint(
              '[AlarmKu] Schedule id=$notifId day=$day at $scheduled');
          await _plugin.zonedSchedule(
            notifId,
            '💊 Waktunya minum obat!',
            '${medicine.name} — ${medicine.dosage}',
            scheduled,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      } else {
        // Sekali — jam terdekat hari ini atau besok
        final now = tz.TZDateTime.now(tz.local);
        tz.TZDateTime scheduled =
            tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        if (scheduled.isBefore(now.add(const Duration(seconds: 5)))) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        final notifId = _notifId(medicine.id!, 0);
        debugPrint('[AlarmKu] Schedule sekali id=$notifId at $scheduled');
        await _plugin.zonedSchedule(
          notifId,
          '💊 Waktunya minum obat!',
          '${medicine.name} — ${medicine.dosage}',
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      debugPrint('[AlarmKu] Schedule ${medicine.name} SUCCESS');
    } catch (e) {
      debugPrint('[AlarmKu] Schedule error: $e');
    }
  }

  // Test notif langsung muncul — untuk debug
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    try {
      await _plugin.show(
        9999,
        '✅ Test AlarmKu',
        'Notifikasi berfungsi dengan baik!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      debugPrint('[AlarmKu] Test notification sent');
    } catch (e) {
      debugPrint('[AlarmKu] Test notif error: $e');
    }
  }

  Future<void> cancelForMedicine(Medicine medicine) async {
    if (kIsWeb || medicine.id == null) return;
    try {
      for (int d = 0; d <= 7; d++) {
        await _plugin.cancel(_notifId(medicine.id!, d));
      }
      debugPrint('[AlarmKu] Cancelled notif for ${medicine.name}');
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
      debugPrint('[AlarmKu] All notifications cancelled');
    } catch (_) {}
  }

  // List semua notif yang sedang terjadwal
  Future<void> debugListPending() async {
    if (kIsWeb) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('[AlarmKu] Pending notifications: ${pending.length}');
      for (final n in pending) {
        debugPrint('[AlarmKu]   → id=${n.id} title=${n.title} body=${n.body}');
      }
    } catch (e) {
      debugPrint('[AlarmKu] debugListPending error: $e');
    }
  }

  tz.TZDateTime _nextDayTime(int day, int hour, int minute) {
    tz.TZDateTime dt = tz.TZDateTime.now(tz.local);
    dt = tz.TZDateTime(tz.local, dt.year, dt.month, dt.day, hour, minute);
    int tries = 0;
    while ((dt.weekday != day ||
            dt.isBefore(tz.TZDateTime.now(tz.local).add(
              const Duration(seconds: 5),
            ))) &&
        tries < 8) {
      dt = dt.add(const Duration(days: 1));
      tries++;
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
