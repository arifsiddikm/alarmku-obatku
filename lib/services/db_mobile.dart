import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medicine.dart';

class DbImpl {
  static Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'alarmku.db');
    _db = await openDatabase(path, version: 1, onCreate: _create);
    return _db!;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        phone TEXT,
        avatar TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        notes TEXT DEFAULT '',
        time TEXT NOT NULL,
        days TEXT NOT NULL DEFAULT '',
        is_repeat INTEGER NOT NULL DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1,
        sound_key TEXT NOT NULL DEFAULT 'default',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> init() async {
    await _database;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await _database;
    final r = await db.query('users',
        where: 'email = ?', whereArgs: [email.toLowerCase().trim()]);
    return r.isEmpty ? null : User.fromMap(r.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await _database;
    final r = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : User.fromMap(r.first);
  }

  Future<User> insertUser(User user) async {
    final db = await _database;
    final map = user.toMap()..remove('id');
    final id = await db.insert('users', map);
    return user..id = id;
  }

  Future<int> updateUser(User user) async {
    final db = await _database;
    return db.update('users', user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }

  Future<Medicine> insertMedicine(Medicine medicine) async {
    final db = await _database;
    final map = medicine.toMap()..remove('id');
    final id = await db.insert('medicines', map);
    return medicine..id = id;
  }

  Future<List<Medicine>> getMedicinesByUser(int userId) async {
    final db = await _database;
    final r = await db.query('medicines',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'time ASC');
    return r.map((m) => Medicine.fromMap(m)).toList();
  }

  Future<int> updateMedicine(Medicine medicine) async {
    final db = await _database;
    return db.update('medicines', medicine.toMap(),
        where: 'id = ?', whereArgs: [medicine.id]);
  }

  Future<int> deleteMedicine(int id) async {
    final db = await _database;
    return db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleMedicineActive(int id, bool isActive) async {
    final db = await _database;
    return db.update('medicines', {'is_active': isActive ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }
}
