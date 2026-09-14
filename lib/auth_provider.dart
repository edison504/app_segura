import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  
  bool _isAuthenticated = false;
  String? _userToken;
  final String _userName = "Carlos"; // Información personalizada

  bool get isAuthenticated => _isAuthenticated;
  String get userName => _userName;

  // 1. Verificar si hay una sesión activa al abrir la app
  Future<void> checkSession() async {
    _userToken = await _secureStorage.read(key: 'session_token');
    _isAuthenticated = _userToken != null;
    notifyListeners();
  }

  // 2. Simular Login y guardar el token de forma segura
  Future<bool> login(String username, String password) async {
    if (username.isNotEmpty && password.isNotEmpty) {
      _userToken = "token_seguro_xyz123";
      await _secureStorage.write(key: 'session_token', value: _userToken);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // 3. Cerrar sesión y limpiar credenciales (liberación de recursos)
  Future<void> logout() async {
    await _secureStorage.delete(key: 'session_token');
    _userToken = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}