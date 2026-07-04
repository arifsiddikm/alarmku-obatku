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

  static const _channelId = 'alarmku_v3';
  static const _channelName = 'Pengingat Minum Obat';

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      // Hardcode Asia/Jakarta — WIB UTC+7
      // Auto-detect sering salah di beberapa device Android
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      debugPrint('[AlarmKu] Timezone set: Asia/Jakarta UTC+7');

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('[AlarmKu] Notif tapped: ${details.payload}');
        },
      );

      // Buat channel per sound key
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Channel default (sistem)
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

      // Channel per nada dering
      for (final sound in ['gentle', 'urgent', 'classic', 'digital']) {
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            '${_channelId}_$sound',
            '$_channelName ($sound)',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(sound),
            enableVibration: true,
            showBadge: true,
          ),
        );
      }

      _initialized = true;
      debugPrint('[AlarmKu] NotificationService initialized OK');
    } catch (e) {
      debugPrint('[AlarmKu] Notif init error: $e');
    }
  }

  Future<Map<String, bool>> requestAllPermissions() async {
    if (kIsWeb) return {'notification': true};
    final results = <String, bool>{};
    try {
      final notifStatus = await Permission.notification.request();
      results['notification'] = notifStatus.isGranted;
      debugPrint('[AlarmKu] Notification permission: ${notifStatus.name}');

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final exactAlarm =
          await androidPlugin?.requestExactAlarmsPermission() ?? false;
      results['exact_alarm'] = exactAlarm;
      debugPrint('[AlarmKu] Exact alarm: $exactAlarm');
    } catch (e) {
      debugPrint('[AlarmKu] Permission error: $e');
    }
    return results;
  }

  Future<bool> checkPermission() async {
    if (kIsWeb) return true;
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _buildDetails(String soundKey) {
    if (soundKey == 'default') {
      return const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
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
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        '${_channelId}_$soundKey',
        '$_channelName ($soundKey)',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundKey),
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        autoCancel: true,
      ),
    );
  }

  Future<void> scheduleForMedicine(Medicine medicine) async {
    if (kIsWeb || !medicine.isActive || medicine.id == null) return;

    try {
      await cancelForMedicine(medicine);

      final timeParts = medicine.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final details = _buildDetails(medicine.soundKey);

      // Pakai DateTime.now() sebagai referensi waktu lokal
      final nowDt = DateTime.now();
      debugPrint('[AlarmKu] Scheduling ${medicine.name} at ${medicine.time} '
          'days=${medicine.days} repeat=${medicine.isRepeat} sound=${medicine.soundKey} now=$nowDt');

      if (medicine.isRepeat && medicine.days.isNotEmpty) {
        for (final day in medicine.days) {
          final notifId = _notifId(medicine.id!, day);

          // Hitung waktu target pakai DateTime biasa
          DateTime target = DateTime(nowDt.year, nowDt.month, nowDt.day, hour, minute);

          // Geser ke hari yang benar
          int tries = 0;
          while (tries < 8) {
            if (target.weekday == day && target.isAfter(nowDt)) {
              break;
            }
            target = target.add(const Duration(days: 1));
            tries++;
          }

          final isToday = target.day == nowDt.day && target.month == nowDt.month;
          final tzTarget = tz.TZDateTime(tz.local, target.year, target.month, target.day, target.hour, target.minute);

          debugPrint('[AlarmKu] → id=$notifId day=$day target=$target isToday=$isToday');

          if (isToday) {
            // Hari ini — trigger sekali, tanpa repeat component
            await _plugin.zonedSchedule(
              notifId,
              '💊 Waktunya minum obat!',
              '${medicine.name} — ${medicine.dosage}',
              tzTarget,
              details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: medicine.id.toString(),
            );
          } else {
            // Hari lain — repeat mingguan
            await _plugin.zonedSchedule(
              notifId,
              '💊 Waktunya minum obat!',
              '${medicine.name} — ${medicine.dosage}',
              tzTarget,
              details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: medicine.id.toString(),
            );
          }
        }
      } else {
        // Mode sekali
        DateTime target = DateTime(nowDt.year, nowDt.month, nowDt.day, hour, minute);

        // Kalau sudah lewat (bukan belum), geser ke besok
        if (target.isBefore(nowDt)) {
          target = target.add(const Duration(days: 1));
        }

        debugPrint('[AlarmKu] nowDt=$nowDt target=$target isBefore=${target.isBefore(nowDt)}');

        final tzTarget = tz.TZDateTime(tz.local, target.year, target.month, target.day, target.hour, target.minute);
        final notifId = _notifId(medicine.id!, 0);

        debugPrint('[AlarmKu] → sekali id=$notifId target=$target tzTarget=$tzTarget');

        await _plugin.zonedSchedule(
          notifId,
          '💊 Waktunya minum obat!',
          '${medicine.name} — ${medicine.dosage}',
          tzTarget,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: medicine.id.toString(),
        );
      }

      debugPrint('[AlarmKu] Schedule ${medicine.name} SUCCESS');
    } catch (e) {
      debugPrint('[AlarmKu] Schedule error: $e');
    }
  }

  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    try {
      await _plugin.show(
        9999,
        '✅ Test AlarmKu',
        'Notifikasi berfungsi! Alarm obat akan muncul tepat waktu.',
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
      debugPrint('[AlarmKu] Test notification sent OK');
    } catch (e) {
      debugPrint('[AlarmKu] Test notif error: $e');
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    try {
      final id = DateTime.now().millisecondsSinceEpoch % 100000;
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
      debugPrint('[AlarmKu] Immediate notif sent: $title');
    } catch (e) {
      debugPrint('[AlarmKu] Immediate notif error: $e');
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

  Future<void> debugListPending() async {
    if (kIsWeb) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('[AlarmKu] Pending: ${pending.length}');
      for (final n in pending) {
        debugPrint('[AlarmKu]   id=${n.id} | ${n.title} | ${n.body}');
      }
    } catch (e) {
      debugPrint('[AlarmKu] debugListPending error: $e');
    }
  }

  tz.TZDateTime _nextDayTime(int day, int hour, int minute) {
    tz.TZDateTime dt = tz.TZDateTime.now(tz.local);
    dt = tz.TZDateTime(tz.local, dt.year, dt.month, dt.day, hour, minute);
    int tries = 0;
    while (tries < 8) {
      if (dt.weekday == day &&
          dt.isAfter(tz.TZDateTime.now(tz.local).add(
            const Duration(seconds: 30),
          ))) {
        break;
      }
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
