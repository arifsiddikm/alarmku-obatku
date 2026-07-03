import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/medicine.dart';

// Web: pakai in-memory storage
// Mobile/Desktop: pakai sqflite
import 'db_mobile.dart' if (dart.library.html) 'db_web.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  final _impl = DbImpl();

  Future<void> init() => _impl.init();

  Future<User?> getUserByEmail(String email) => _impl.getUserByEmail(email);
  Future<User?> getUserById(int id) => _impl.getUserById(id);
  Future<User> insertUser(User user) => _impl.insertUser(user);
  Future<int> updateUser(User user) => _impl.updateUser(user);

  Future<Medicine> insertMedicine(Medicine medicine) => _impl.insertMedicine(medicine);
  Future<List<Medicine>> getMedicinesByUser(int userId) => _impl.getMedicinesByUser(userId);
  Future<int> updateMedicine(Medicine medicine) => _impl.updateMedicine(medicine);
  Future<int> deleteMedicine(int id) => _impl.deleteMedicine(id);
  Future<int> toggleMedicineActive(int id, bool isActive) => _impl.toggleMedicineActive(id, isActive);
}
