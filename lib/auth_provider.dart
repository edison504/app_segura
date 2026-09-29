import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SessionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSessionStorage implements SessionStorage {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class AuthProvider with ChangeNotifier {
  AuthProvider({SessionStorage? storage, DateTime Function()? now})
      : _storage = storage ?? SecureSessionStorage(),
        _now = now ?? DateTime.now;

  static const sessionDuration = Duration(minutes: 5);
  static const _tokenKey = 'session_token';
  static const _expiryKey = 'session_expires_at';
  static const _usernameKey = 'session_username';

  // Cuentas locales exclusivamente para probar el flujo de autenticación.
  static const _testAccounts = {
    'edison': 'Edison123',
    'nicolas': 'Nicolas123',
  };

  final SessionStorage _storage;
  final DateTime Function() _now;
  Timer? _expiryTimer;
  bool _isAuthenticated = false;
  String? _userName;

  bool get isAuthenticated => _isAuthenticated;
  String get userName => _userName ?? '';

  Future<void> checkSession() async {
    final token = await _storage.read(_tokenKey);
    final username = await _storage.read(_usernameKey);
    final expiresAt = DateTime.tryParse(await _storage.read(_expiryKey) ?? '');

    if (token == null ||
        username == null ||
        !_testAccounts.containsKey(username) ||
        expiresAt == null ||
        !expiresAt.isAfter(_now())) {
      await logout();
      return;
    }

    _userName = username == 'edison' ? 'Edison' : 'Nicolas';
    _isAuthenticated = true;
    _scheduleExpiry(expiresAt);
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    final account = username.trim().toLowerCase();
    if (password.length < 6 || _testAccounts[account] != password) {
      return false;
    }

    final expiresAt = _now().add(sessionDuration);
    final random = Random.secure();
    final token = List.generate(32, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    await _storage.write(_tokenKey, token);
    await _storage.write(_usernameKey, account);
    await _storage.write(_expiryKey, expiresAt.toIso8601String());

    _userName = account == 'edison' ? 'Edison' : 'Nicolas';
    _isAuthenticated = true;
    _scheduleExpiry(expiresAt);
    notifyListeners();
    return true;
  }

  void _scheduleExpiry(DateTime expiresAt) {
    _expiryTimer?.cancel();
    _expiryTimer = Timer(expiresAt.difference(_now()), logout);
  }

  Future<void> logout() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    await _storage.delete(_tokenKey);
    await _storage.delete(_usernameKey);
    await _storage.delete(_expiryKey);
    _userName = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
