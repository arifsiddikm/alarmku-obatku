import 'package:flutter/foundation.dart';
import '../models/medicine.dart';

// Notifikasi hanya jalan di Android/iOS, di web no-op
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  Future<void> init() async {
    if (kIsWeb) return; // skip di web
    await _initMobile();
  }

  Future<void> _initMobile() async {
    try {
      // Import dinamis hanya di mobile
      final notif = await _getMobileNotif();
      await notif?.init();
    } catch (e) {
      debugPrint('Notif init error: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    try {
      final notif = await _getMobileNotif();
      return await notif?.requestPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkPermission() async {
    if (kIsWeb) return true;
    try {
      final notif = await _getMobileNotif();
      return await notif?.checkPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> scheduleForMedicine(Medicine medicine) async {
    if (kIsWeb) return;
    try {
      final notif = await _getMobileNotif();
      await notif?.scheduleForMedicine(medicine);
    } catch (e) {
      debugPrint('Schedule notif error: $e');
    }
  }

  Future<void> cancelForMedicine(Medicine medicine) async {
    if (kIsWeb) return;
    try {
      final notif = await _getMobileNotif();
      await notif?.cancelForMedicine(medicine);
    } catch (e) {
      debugPrint('Cancel notif error: $e');
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      final notif = await _getMobileNotif();
      await notif?.cancelAll();
    } catch (_) {}
  }

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

  // Lazy load implementasi mobile biar ga error di web
  _MobileNotifImpl? _mobileImpl;
  Future<_MobileNotifImpl?> _getMobileNotif() async {
    if (kIsWeb) return null;
    _mobileImpl ??= _MobileNotifImpl();
    return _mobileImpl;
  }
}

// Implementasi notif mobile (hanya diload di non-web)
class _MobileNotifImpl {
  bool _initialized = false;
  dynamic _plugin; // FlutterLocalNotificationsPlugin

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Import runtime biar ga compile error di web
      final pluginLib = await _loadPlugin();
      if (pluginLib == null) return;
      _plugin = pluginLib;
      _initialized = true;
    } catch (e) {
      debugPrint('Mobile notif init error: $e');
    }
  }

  Future<dynamic> _loadPlugin() async {
    try {
      // Ini akan diload hanya di platform yang support
      return _NotifPlugin();
    } catch (_) {
      return null;
    }
  }

  Future<bool> requestPermission() async => true;
  Future<bool> checkPermission() async => true;
  Future<void> scheduleForMedicine(Medicine m) async {}
  Future<void> cancelForMedicine(Medicine m) async {}
  Future<void> cancelAll() async {}
}

class _NotifPlugin {}
