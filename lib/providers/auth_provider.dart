import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  Usuario? _usuario;
  bool _isAuthenticated = false;
  bool _cargando = true;
  String _error = '';
  bool _registroExitoso = false;

  Usuario? get usuario => _usuario;
  bool get isAuthenticated => _isAuthenticated;
  bool get cargando => _cargando;
  String get error => _error;
  bool get registroExitoso => _registroExitoso;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    _cargando = true;
    // Siempre arrancar desde login — limpiar sesión guardada
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
    ApiService.clearToken();
    _usuario = null;
    _isAuthenticated = false;
    _cargando = false;
    notifyListeners();
  }

  Future<void> login(String email, String contrasena) async {
    _cargando = true;
    _error = '';
    try {
      final response = await ApiService.login(email, contrasena);
      _usuario = Usuario.fromJson(response['datos']['usuario']);
      _isAuthenticated = true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isAuthenticated = false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> registro(String nombre, String email, String contrasena) async {
    _cargando = true;
    _error = '';
    _registroExitoso = false;
    try {
      await ApiService.registro(nombre, email, contrasena);
      _registroExitoso = true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _usuario = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
