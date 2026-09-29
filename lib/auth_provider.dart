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

enum AuthStatus {
  checkingSession,
  unauthenticated,
  authenticating,
  authenticated,
  error,
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
  AuthStatus _status = AuthStatus.checkingSession;
  String? _errorMessage;
  String? _userName;
  bool _retryingLogout = false;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get errorMessage => _errorMessage;
  String get userName => _userName ?? '';

  Future<void> checkSession() async {
    _retryingLogout = false;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _status = AuthStatus.checkingSession;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await _storage.read(_tokenKey);
      final username = await _storage.read(_usernameKey);
      final expiresAt = DateTime.tryParse(await _storage.read(_expiryKey) ?? '');

      if (token == null ||
          username == null ||
          !_testAccounts.containsKey(username) ||
          expiresAt == null ||
          !expiresAt.isAfter(_now())) {
        await _clearStoredSession();
        _userName = null;
        _status = AuthStatus.unauthenticated;
      } else {
        _userName = username == 'edison' ? 'Edison' : 'Nicolas';
        _status = AuthStatus.authenticated;
        _scheduleExpiry(expiresAt);
      }
    } catch (_) {
      _userName = null;
      _status = AuthStatus.error;
      _errorMessage = 'No se pudo comprobar la sesión. Inténtalo de nuevo.';
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    if (_status == AuthStatus.authenticating ||
        _status == AuthStatus.checkingSession ||
        _status == AuthStatus.authenticated) {
      return false;
    }

    _errorMessage = null;
    final account = username.trim().toLowerCase();
    if (password.length < 6 || _testAccounts[account] != password) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Usuario o contraseña incorrectos';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final expiresAt = _now().add(sessionDuration);
      final random = Random.secure();
      final token = List.generate(32, (_) => random.nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

      await _storage.write(_tokenKey, token);
      await _storage.write(_usernameKey, account);
      await _storage.write(_expiryKey, expiresAt.toIso8601String());

      _userName = account == 'edison' ? 'Edison' : 'Nicolas';
      _status = AuthStatus.authenticated;
      _scheduleExpiry(expiresAt);
      notifyListeners();
      return true;
    } catch (_) {
      try {
        await _clearStoredSession();
      } catch (_) {
        // El siguiente arranque también rechazará cualquier sesión incompleta.
      }
      _userName = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'No se pudo iniciar sesión. Inténtalo de nuevo.';
      notifyListeners();
      return false;
    }
  }

  void _scheduleExpiry(DateTime expiresAt) {
    _expiryTimer?.cancel();
    _expiryTimer = Timer(expiresAt.difference(_now()), logout);
  }

  Future<void> logout() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _status = AuthStatus.checkingSession;
    _errorMessage = null;
    notifyListeners();
    try {
      await _clearStoredSession();
      _retryingLogout = false;
      _status = AuthStatus.unauthenticated;
    } catch (_) {
      _retryingLogout = true;
      _status = AuthStatus.error;
      _errorMessage = 'No se pudo cerrar la sesión. Inténtalo de nuevo.';
    }
    _userName = null;
    notifyListeners();
  }

  Future<void> retry() => _retryingLogout ? logout() : checkSession();

  Future<void> _clearStoredSession() async {
    await _storage.delete(_tokenKey);
    await _storage.delete(_usernameKey);
    await _storage.delete(_expiryKey);
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
