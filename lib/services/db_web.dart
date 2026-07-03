import '../models/medicine.dart';

// Implementasi in-memory untuk web (Chrome)
// Data hilang kalau refresh, tapi cukup buat testing UI

class DbImpl {
  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _medicines = [];
  int _userIdSeq = 1;
  int _medIdSeq = 1;

  Future<void> init() async {
    // No-op untuk web
  }

  Future<User?> getUserByEmail(String email) async {
    final e = email.toLowerCase().trim();
    final found = _users.where((u) => u['email'] == e).toList();
    return found.isEmpty ? null : User.fromMap(found.first);
  }

  Future<User?> getUserById(int id) async {
    final found = _users.where((u) => u['id'] == id).toList();
    return found.isEmpty ? null : User.fromMap(found.first);
  }

  Future<User> insertUser(User user) async {
    final id = _userIdSeq++;
    final map = user.toMap();
    map['id'] = id;
    _users.add(map);
    return user..id = id;
  }

  Future<int> updateUser(User user) async {
    final idx = _users.indexWhere((u) => u['id'] == user.id);
    if (idx < 0) return 0;
    _users[idx] = user.toMap();
    return 1;
  }

  Future<Medicine> insertMedicine(Medicine medicine) async {
    final id = _medIdSeq++;
    final map = medicine.toMap();
    map['id'] = id;
    _medicines.add(map);
    return medicine..id = id;
  }

  Future<List<Medicine>> getMedicinesByUser(int userId) async {
    final result = _medicines
        .where((m) => m['user_id'] == userId)
        .map((m) => Medicine.fromMap(m))
        .toList();
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  Future<int> updateMedicine(Medicine medicine) async {
    final idx = _medicines.indexWhere((m) => m['id'] == medicine.id);
    if (idx < 0) return 0;
    _medicines[idx] = medicine.toMap();
    return 1;
  }

  Future<int> deleteMedicine(int id) async {
    final before = _medicines.length;
    _medicines.removeWhere((m) => m['id'] == id);
    return _medicines.length < before ? 1 : 0;
  }

  Future<int> toggleMedicineActive(int id, bool isActive) async {
    final idx = _medicines.indexWhere((m) => m['id'] == id);
    if (idx < 0) return 0;
    _medicines[idx]['is_active'] = isActive ? 1 : 0;
    return 1;
  }
}
