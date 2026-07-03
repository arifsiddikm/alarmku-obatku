import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/medicine.dart';
import 'database_service.dart';

class Seeder {
  static bool _seeded = false; // flag in-memory buat web

  static String _hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<void> run() async {
    try {
      // Cek akun demo sudah ada
      final existing = await DatabaseService.instance
          .getUserByEmail('demo@alarmku.app');
      if (existing != null || _seeded) return;

      // Insert user dummy
      final user = await DatabaseService.instance.insertUser(User(
        name: 'Demo User',
        email: 'demo@alarmku.app',
        passwordHash: _hash('demo123'),
        phone: '081234567890',
        createdAt: DateTime.now(),
      ));

      final userId = user.id!;
      final now = DateTime.now().toIso8601String();

      // Insert data obat contoh
      await DatabaseService.instance.insertMedicine(Medicine(
        userId: userId,
        name: 'Paracetamol 500mg',
        dosage: '1 tablet',
        notes: 'Minum setelah makan',
        time: '08:00',
        days: [1, 2, 3, 4, 5, 6, 7],
        isRepeat: true,
        isActive: true,
        soundKey: 'default',
        createdAt: DateTime.now(),
      ));

      await DatabaseService.instance.insertMedicine(Medicine(
        userId: userId,
        name: 'Vitamin C',
        dosage: '1 tablet',
        notes: 'Boleh sebelum atau sesudah makan',
        time: '12:00',
        days: [1, 2, 3, 4, 5],
        isRepeat: true,
        isActive: true,
        soundKey: 'gentle',
        createdAt: DateTime.now(),
      ));

      await DatabaseService.instance.insertMedicine(Medicine(
        userId: userId,
        name: 'Amoxicillin 500mg',
        dosage: '1 kapsul',
        notes: 'Habiskan antibiotik',
        time: '20:00',
        days: [1, 2, 3, 4, 5, 6, 7],
        isRepeat: true,
        isActive: false,
        soundKey: 'urgent',
        createdAt: DateTime.now(),
      ));

      _seeded = true;
    } catch (e) {
      // Seeder gagal ga masalah, app tetap jalan
    }
  }
}
