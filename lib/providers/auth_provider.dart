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
  ProgresoResumen _progreso = ProgresoResumen.empty();
  int _racha = 0;

  Usuario? get usuario => _usuario;
  bool get isAuthenticated => _isAuthenticated;
  bool get cargando => _cargando;
  String get error => _error;
  bool get registroExitoso => _registroExitoso;
  ProgresoResumen get progreso => _progreso;
  int get racha => _racha;

  bool isLeccionCompletada(String id) => _progreso.leccionesCompletadas.contains(id);
  bool isNivelCompletado(String id) => _progreso.nivelesCompletados.contains(id);

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    _cargando = true;
    final prefs = await SharedPreferences.getInstance();

    // Restaurar la sesión solo si el usuario marcó "Recordarme"
    if (prefs.getBool('recordar') ?? false) {
      await ApiService.initToken();
      try {
        if (await ApiService.verificarToken()) {
          _usuario = await ApiService.getUsuarioActual();
          _racha = _usuario?.racha ?? 0;
          _isAuthenticated = true;
          await loadProgreso();
        }
      } catch (_) {}
    }

    if (!_isAuthenticated) {
      await prefs.remove('token');
      await prefs.remove('usuario');
      ApiService.clearToken();
      _usuario = null;
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> login(String email, String contrasena,
      {bool recordar = false}) async {
    _cargando = true;
    _error = '';
    try {
      final response = await ApiService.login(email, contrasena);
      _usuario = Usuario.fromJson(response['datos']['usuario']);
      _racha = _usuario?.racha ?? 0;
      _isAuthenticated = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('recordar', recordar);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isAuthenticated = false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Limpiar error y flag de registro al entrar a login/registro,
  // para que no queden estados de una visita anterior
  void limpiarEstado() {
    _error = '';
    _registroExitoso = false;
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

  Future<void> loadProgreso() async {
    try {
      _progreso = await ApiService.getProgresoResumen();
      notifyListeners();
    } catch (_) {}
  }

  // Actualizar nombre y/o contraseña; lanza excepción si el servidor rechaza
  Future<void> actualizarPerfil({String? nombre, String? contrasena}) async {
    _usuario = await ApiService.actualizarPerfil(
        nombre: nombre, contrasena: contrasena);
    notifyListeners();
  }

  // Refrescar puntos/medallas/racha desde el servidor
  Future<void> refreshUsuario() async {
    try {
      _usuario = await ApiService.getUsuarioActual();
      _racha = _usuario?.racha ?? _racha;
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> marcarLeccionCompleta(String leccionId, int porcentaje) async {
    final result = await ApiService.completarLeccion(leccionId, porcentaje);
    if (result['desbloqueado'] == true) {
      _progreso.leccionesCompletadas.add(leccionId);
      _racha = result['racha'] as int? ?? _racha;
      notifyListeners();
      await refreshUsuario();
    }
    return result;
  }

  Future<Map<String, dynamic>> marcarNivelCompleto(String nivelId, int porcentaje) async {
    final result = await ApiService.completarNivel(nivelId, porcentaje);
    if (result['desbloqueado'] == true) {
      _progreso.nivelesCompletados.add(nivelId);
      _racha = result['racha'] as int? ?? _racha;
      notifyListeners();
      await refreshUsuario();
    }
    return result;
  }

  Future<void> logout() async {
    await ApiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recordar');
    _usuario = null;
    _isAuthenticated = false;
    _progreso = ProgresoResumen.empty();
    notifyListeners();
  }
}
