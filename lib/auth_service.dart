import 'dart:math';

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

class UserSession {
  const UserSession({
    required this.token,
    required this.username,
    required this.expiresAt,
  });

  final String token;
  final String username;
  final DateTime expiresAt;

  String get displayName => username == 'edison' ? 'Edison' : 'Nicolas';
}

class AuthService {
  AuthService({SessionStorage? storage, DateTime Function()? now})
      : _storage = storage ?? SecureSessionStorage(),
        _now = now ?? DateTime.now;

  static const sessionDuration = Duration(minutes: 5);
  static const _tokenKey = 'session_token';
  static const _expiryKey = 'session_expires_at';
  static const _usernameKey = 'session_username';

  // Cuentas locales para probar el acceso sin servidor.
  static const _testAccounts = {
    'edison': 'Edison123',
    'nicolas': 'Nicolas123',
  };

  final SessionStorage _storage;
  final DateTime Function() _now;

  Future<UserSession?> restoreSession() async {
    final token = await _storage.read(_tokenKey);
    final username = await _storage.read(_usernameKey);
    final expiresAt = DateTime.tryParse(await _storage.read(_expiryKey) ?? '');

    if (token == null ||
        token.length != 64 ||
        username == null ||
        !_testAccounts.containsKey(username) ||
        expiresAt == null ||
        !expiresAt.isAfter(_now())) {
      await logout();
      return null;
    }

    return UserSession(token: token, username: username, expiresAt: expiresAt);
  }

  Future<UserSession?> login(String username, String password) async {
    final account = username.trim().toLowerCase();
    if (password.length < 6 || _testAccounts[account] != password) {
      return null;
    }

    final expiresAt = _now().add(sessionDuration);
    final random = Random.secure();
    final token = List.generate(32, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    try {
      await _storage.write(_tokenKey, token);
      await _storage.write(_usernameKey, account);
      await _storage.write(_expiryKey, expiresAt.toIso8601String());
    } catch (_) {
      try {
        await logout();
      } catch (_) {
        // La restauración también rechazará una sesión incompleta.
      }
      rethrow;
    }

    return UserSession(token: token, username: account, expiresAt: expiresAt);
  }

  Future<void> logout() async {
    await _storage.delete(_tokenKey);
    await _storage.delete(_usernameKey);
    await _storage.delete(_expiryKey);
  }
}
