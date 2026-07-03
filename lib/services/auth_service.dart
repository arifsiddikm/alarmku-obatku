import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  static const _keyUserId = 'logged_user_id';

  // Fallback in-memory session untuk web
  int? _webSessionUserId;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<({bool success, String message, User? user})> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final existing = await DatabaseService.instance
          .getUserByEmail(email.trim().toLowerCase());
      if (existing != null) {
        return (success: false, message: 'Email sudah terdaftar', user: null);
      }

      final user = User(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: _hashPassword(password),
        phone: phone?.trim(),
        createdAt: DateTime.now(),
      );

      final saved = await DatabaseService.instance.insertUser(user);
      await _saveSession(saved.id!);
      return (success: true, message: 'Registrasi berhasil', user: saved);
    } catch (e) {
      debugPrint('Register error: $e');
      return (success: false, message: 'Terjadi kesalahan', user: null);
    }
  }

  Future<({bool success, String message, User? user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await DatabaseService.instance
          .getUserByEmail(email.trim().toLowerCase());
      if (user == null) {
        return (success: false, message: 'Email tidak ditemukan', user: null);
      }

      if (user.passwordHash != _hashPassword(password)) {
        return (success: false, message: 'Password salah', user: null);
      }

      await _saveSession(user.id!);
      return (success: true, message: 'Login berhasil', user: user);
    } catch (e) {
      debugPrint('Login error: $e');
      return (success: false, message: 'Terjadi kesalahan', user: null);
    }
  }

  Future<void> logout() async {
    _webSessionUserId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<void> _saveSession(int userId) async {
    _webSessionUserId = userId; // selalu simpan in-memory
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUserId, userId);
    } catch (e) {
      debugPrint('SaveSession error: $e');
      // in-memory fallback sudah tersimpan di atas
    }
  }

  Future<int?> getLoggedUserId() async {
    // Cek in-memory dulu (untuk web / kalau prefs gagal)
    if (_webSessionUserId != null) return _webSessionUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyUserId);
    } catch (e) {
      debugPrint('GetLoggedUserId error: $e');
      return null;
    }
  }

  Future<User?> getLoggedUser() async {
    try {
      final id = await getLoggedUserId();
      if (id == null) return null;
      return DatabaseService.instance.getUserById(id);
    } catch (e) {
      debugPrint('GetLoggedUser error: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final id = await getLoggedUserId();
      return id != null;
    } catch (e) {
      return false;
    }
  }
}
