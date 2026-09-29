import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_service.dart';

enum AuthStatus {
  checkingSession,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  AuthProvider({AuthService? service, DateTime Function()? now})
      : _service = service ?? AuthService(now: now),
        _now = now ?? DateTime.now;

  final AuthService _service;
  final DateTime Function() _now;
  Timer? _expiryTimer;
  AuthStatus _status = AuthStatus.checkingSession;
  String? _errorMessage;
  UserSession? _session;
  bool _retryingLogout = false;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get errorMessage => _errorMessage;
  String get userName => _session?.displayName ?? '';

  // Nunca expone el token completo ni muestra datos en builds de producción.
  String? get debugTokenPreview => kDebugMode && isAuthenticated
      ? '${_session!.token.substring(0, 8)}…'
      : null;
  DateTime? get sessionExpiresAt =>
      isAuthenticated ? _session?.expiresAt : null;

  Future<void> checkSession() async {
    _retryingLogout = false;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _status = AuthStatus.checkingSession;
    _errorMessage = null;
    notifyListeners();
    try {
      _session = await _service.restoreSession();
      if (_session == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.authenticated;
        _scheduleExpiry(_session!.expiresAt);
      }
    } catch (_) {
      _session = null;
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
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      _session = await _service.login(username, password);
      if (_session == null) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Usuario o contraseña incorrectos';
        notifyListeners();
        return false;
      }

      _status = AuthStatus.authenticated;
      _scheduleExpiry(_session!.expiresAt);
      notifyListeners();
      return true;
    } catch (_) {
      _session = null;
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
      await _service.logout();
      _retryingLogout = false;
      _status = AuthStatus.unauthenticated;
    } catch (_) {
      _retryingLogout = true;
      _status = AuthStatus.error;
      _errorMessage = 'No se pudo cerrar la sesión. Inténtalo de nuevo.';
    }
    _session = null;
    notifyListeners();
  }

  Future<void> retry() => _retryingLogout ? logout() : checkSession();

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
