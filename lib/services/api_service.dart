import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';
import '../models/models.dart';

class ApiService {
  static late String baseUrl;
  static String? _token;

  // Timeout de todas las llamadas HTTP (API_TIMEOUT del .env, 30s por defecto)
  static Duration get _timeout => Duration(seconds: Config.apiTimeout);

  // ── Caché en memoria (niveles y lecciones cambian solo desde el admin) ──
  static List<Nivel>? _nivelesCache;
  static final Map<String, List<Leccion>> _leccionesCache = {};

  static void invalidateCache() {
    _nivelesCache = null;
    _leccionesCache.clear();
  }

  // Inicializar con URL del .env
  static void initialize() {
    baseUrl = Config.apiUrl;
  }

  static Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // AUTH ENDPOINTS
  static Future<Map<String, dynamic>> login(String email, String contrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'contrasena': contrasena}),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['datos']['token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('usuario', jsonEncode(data['datos']['usuario']));
      
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['mensaje']);
    }
  }

  // Login/registro con Google: manda el idToken obtenido de GoogleAuthService.
  static Future<Map<String, dynamic>> loginGoogle(String idToken,
      {String? codigoOrganizacion}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        if (codigoOrganizacion != null && codigoOrganizacion.trim().isNotEmpty)
          'codigo_organizacion': codigoOrganizacion.trim(),
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['datos']['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('usuario', jsonEncode(data['datos']['usuario']));

      return data;
    } else {
      throw Exception(jsonDecode(response.body)['mensaje']);
    }
  }

  static Future<Map<String, dynamic>> registro(
      String nombre, String email, String contrasena,
      {String? codigoOrganizacion}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'contrasena': contrasena,
        if (codigoOrganizacion != null && codigoOrganizacion.trim().isNotEmpty)
          'codigo_organizacion': codigoOrganizacion.trim(),
      }),
    ).timeout(_timeout);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _token = data['datos']['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('usuario', jsonEncode(data['datos']['usuario']));

      return data;
    } else {
      final body = jsonDecode(response.body);
      final errores = body['errores'] as List?;
      if (errores != null && errores.isNotEmpty) {
        final mensajes = errores.map((e) => e['mensaje']).join('\n');
        throw Exception(mensajes);
      }
      throw Exception(body['mensaje'] ?? 'Error al registrarse');
    }
  }

  // Obtener el usuario actual con puntos/medallas/racha actualizados
  static Future<Usuario> getUsuarioActual() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Usuario.fromJson(data['datos']);
    }
    throw Exception('Error al obtener el usuario');
  }

  static Future<bool> verificarToken() async {
    if (_token == null) return false;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      ).timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    _token = null;
    invalidateCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  // Actualizar el propio perfil (contraseña vacía = no cambiarla;
  // foto: '' la quita, null no la toca)
  static Future<Usuario> actualizarPerfil(
      {String? nombre, String? contrasena, String? foto}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/student/perfil'),
      headers: _headers,
      body: jsonEncode({
        if (nombre != null && nombre.isNotEmpty) 'nombre': nombre,
        if (contrasena != null && contrasena.isNotEmpty) 'contrasena': contrasena,
        if (foto != null) 'foto': foto,
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return Usuario.fromJson(jsonDecode(response.body)['datos']);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['mensaje'] ?? 'Error al actualizar el perfil');
  }

  // NIVELES ENDPOINTS
  static Future<List<Nivel>> getNiveles({bool forceRefresh = false}) async {
    if (!forceRefresh && _nivelesCache != null) return _nivelesCache!;

    final response = await http.get(
      Uri.parse('$baseUrl/student/niveles?limite=100'),
      headers: _headers,
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> nivelesJson = data['datos']['datos'];
      _nivelesCache = nivelesJson.map((n) => Nivel.fromJson(n)).toList();
      return _nivelesCache!;
    } else {
      throw Exception('Error al cargar niveles');
    }
  }

  // LECCIONES ENDPOINTS
  static Future<List<Leccion>> getLecciones(String nivelId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _leccionesCache.containsKey(nivelId)) {
      return _leccionesCache[nivelId]!;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/student/niveles/$nivelId/estructura'),
      headers: _headers,
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> temas = data['datos']['temas'] ?? [];
      final List<Map<String, dynamic>> lecciones = [];
      for (final tema in temas) {
        final temaNombre = (tema['nombre'] as String?) ?? '';
        for (final leccion in (tema['lecciones'] as List? ?? [])) {
          final l = Map<String, dynamic>.from(leccion as Map);
          l['_tema_nombre'] = temaNombre;
          // Personalización de la mascota definida en el tema
          l['_tema_mascota'] = tema['mascota'];
          l['_tema_mensaje'] = tema['mensaje_mascota'];
          lecciones.add(l);
        }
      }
      final resultado = lecciones.map((l) => Leccion.fromJson(l)).toList();
      _leccionesCache[nivelId] = resultado;
      return resultado;
    } else {
      throw Exception('Error al cargar lecciones');
    }
  }

  static Future<Leccion> getLeccion(String leccionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/lecciones/$leccionId'),
      headers: _headers,
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Leccion.fromJson(data['datos']);
    } else {
      throw Exception('Error al cargar lección');
    }
  }

  // EJERCICIOS ENDPOINTS
  static Future<List<Ejercicio>> getEjercicios(String leccionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/lecciones/$leccionId/iniciar'),
      headers: _headers,
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> ejerciciosJson = data['datos']['ejercicios'] ?? [];
      return ejerciciosJson.map((e) => Ejercicio.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar ejercicios');
    }
  }

  // PROGRESO ENDPOINTS
  static Future<ProgresoResumen> getProgresoResumen() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/progreso/resumen'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProgresoResumen.fromJson(data['datos']);
    }
    throw Exception('Error al cargar progreso');
  }

  static Future<Map<String, dynamic>> completarLeccion(String leccionId, int porcentaje) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/student/lecciones/$leccionId/completar'),
        headers: _headers,
        body: jsonEncode({'porcentaje': porcentaje}),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['datos'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'desbloqueado': false};
  }

  static Future<Map<String, dynamic>> completarNivel(String nivelId, int porcentaje) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/student/niveles/$nivelId/completar'),
        headers: _headers,
        body: jsonEncode({'porcentaje': porcentaje}),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['datos'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'desbloqueado': false};
  }

  // alcance: 'global' (toda la app) u 'organizacion' (solo mi clase/org)
  static Future<List<EstudianteRanking>> getRanking(
      {String alcance = 'global'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/ranking?alcance=$alcance'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> lista = data['datos'] as List? ?? [];
      return lista.map((e) => EstudianteRanking.fromJson(e)).toList();
    }
    throw Exception('Error al cargar el ranking');
  }

  // ADMIN ENDPOINTS
  static Future<List<EstudianteRanking>> getEstudiantes({String orden = 'desc'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/usuarios?orden=$orden&limite=100'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> lista = data['datos']['datos'];
      return lista.map((e) => EstudianteRanking.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar estudiantes');
    }
  }

  static Future<void> darMedalla(String userId, String tipo, String descripcion) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/usuarios/$userId/medalla'),
      headers: _headers,
      body: jsonEncode({'tipo': tipo, 'descripcion': descripcion}),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al dar medalla');
    }
  }

  static Future<void> crearUsuarioAdmin({
    required String nombre,
    required String email,
    required String contrasena,
    required String rol,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/usuarios'),
      headers: _headers,
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'contrasena': contrasena,
        'rol': rol,
      }),
    ).timeout(_timeout);
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      final errores = body['errores'] as List?;
      if (errores != null && errores.isNotEmpty) {
        throw Exception(errores.map((e) => e['mensaje']).join('\n'));
      }
      throw Exception(body['mensaje'] ?? 'Error al crear usuario');
    }
  }

  static Future<void> actualizarUsuarioAdmin(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/usuarios/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al actualizar usuario');
    }
  }

  static Future<void> eliminarUsuario(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/usuarios/$id'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al eliminar usuario');
    }
  }

  static Future<List<Map<String, dynamic>>> getTemasAdmin() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/temas?limite=100'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['datos']['datos']);
    } else {
      throw Exception('Error al cargar temas');
    }
  }

  static Future<List<Map<String, dynamic>>> getLeccionesAdmin() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/lecciones?limite=100'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['datos']['datos']);
    } else {
      throw Exception('Error al cargar lecciones');
    }
  }

  static Future<void> crearLeccion({
    required String nombre,
    required String descripcion,
    required String contenido,
    required String temaId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/lecciones'),
      headers: _headers,
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'contenido': contenido,
        'tema_id': temaId,
      }),
    ).timeout(_timeout);
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      final errores = body['errores'] as List?;
      if (errores != null && errores.isNotEmpty) {
        throw Exception(errores.map((e) => e['mensaje']).join('\n'));
      }
      throw Exception(body['mensaje'] ?? 'Error al crear lección');
    }
    invalidateCache();
  }

  static Future<void> crearEjercicio({
    required String pregunta,
    required String tipo,
    required List<String> opciones,
    required String respuestaCorrecta,
    required String explicacion,
    required int puntos,
    required String leccionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/ejercicios'),
      headers: _headers,
      body: jsonEncode({
        'pregunta': pregunta,
        'tipo': tipo,
        'opciones': opciones,
        'respuesta_correcta': respuestaCorrecta,
        'explicacion': explicacion,
        'puntos': puntos,
        'leccion_id': leccionId,
      }),
    ).timeout(_timeout);
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      final errores = body['errores'] as List?;
      if (errores != null && errores.isNotEmpty) {
        throw Exception(errores.map((e) => e['mensaje']).join('\n'));
      }
      throw Exception(body['mensaje'] ?? 'Error al crear ejercicio');
    }
  }

  // Califica la respuesta en el servidor. Devuelve
  // {esCorrecta, respuesta_correcta, explicacion, ...}
  static Future<Map<String, dynamic>> submitEjercicio(
      String ejercicioId, String respuesta) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/ejercicios/$ejercicioId/responder'),
      headers: _headers,
      body: jsonEncode({'respuesta': respuesta}),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['datos'] as Map<String, dynamic>;
    } else {
      throw Exception('Error al enviar respuesta');
    }
  }

  // ── Organizaciones ────────────────────────────────────────────────────────

  // Solicitud pública desde el login: "¿Eres una organización?"
  static Future<String> enviarSolicitudOrganizacion({
    required String nombreOrganizacion,
    required String email,
    required String sector,
    String mensaje = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/public/solicitudes-organizacion'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre_organizacion': nombreOrganizacion,
        'email': email,
        'sector': sector,
        'mensaje': mensaje,
      }),
    ).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return body['mensaje'] as String? ?? 'Solicitud enviada';
    }
    final errores = body['errores'] as List?;
    if (errores != null && errores.isNotEmpty) {
      throw Exception(errores.map((e) => e['mensaje']).join('\n'));
    }
    throw Exception(body['mensaje'] ?? 'No se pudo enviar la solicitud');
  }

  // ── ADMIN: organizaciones ──
  static Future<List<Organizacion>> getOrganizaciones() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/organizaciones'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      final datos = jsonDecode(response.body)['datos'] as List;
      return datos.map((o) => Organizacion.fromJson(o)).toList();
    }
    throw Exception('Error al cargar organizaciones');
  }

  static Future<Organizacion> crearOrganizacion(
      String nombre, String sector, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/organizaciones'),
      headers: _headers,
      body: jsonEncode({'nombre': nombre, 'sector': sector, 'email': email}),
    ).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return Organizacion.fromJson(body['datos']);
    }
    throw Exception(body['mensaje'] ?? 'Error al crear la organización');
  }

  static Future<void> actualizarOrganizacion(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/organizaciones/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al actualizar la organización');
    }
  }

  static Future<Organizacion> regenerarCodigoOrganizacion(String id,
      {String tipo = 'estudiante'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/organizaciones/$id/regenerar-codigo'),
      headers: _headers,
      body: jsonEncode({'tipo': tipo}),
    ).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Organizacion.fromJson(body['datos']);
    }
    throw Exception(body['mensaje'] ?? 'Error al regenerar el código');
  }

  // Validar un código de invitación (público): a qué org pertenece y si es
  // de estudiante o de docente
  static Future<InfoInvitacion> validarCodigoOrganizacion(
      String codigo) async {
    final response = await http.get(
      Uri.parse('$baseUrl/public/codigo/${Uri.encodeComponent(codigo.trim())}'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return InfoInvitacion.fromJson(body['datos']);
    }
    throw Exception(body['mensaje'] ?? 'Código inválido');
  }

  static Future<Map<String, dynamic>> eliminarOrganizacion(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/organizaciones/$id'),
      headers: _headers,
    ).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      invalidateCache();
      return body['datos'] as Map<String, dynamic>? ?? {};
    }
    throw Exception(body['mensaje'] ?? 'Error al eliminar la organización');
  }

  // Asignar usuario a organización (y opcionalmente cambiar su rol)
  static Future<void> asignarUsuarioOrganizacion(String userId,
      {String? organizacionId, String? rol}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/usuarios/$userId/organizacion'),
      headers: _headers,
      body: jsonEncode({
        'organizacion_id': organizacionId,
        if (rol != null) 'rol': rol,
      }),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al asignar la organización');
    }
  }

  // ── ADMIN: solicitudes de organizaciones ──
  static Future<List<SolicitudOrganizacion>> getSolicitudesOrganizacion() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/solicitudes'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      final datos = jsonDecode(response.body)['datos'] as List;
      return datos.map((s) => SolicitudOrganizacion.fromJson(s)).toList();
    }
    throw Exception('Error al cargar solicitudes');
  }

  // Devuelve {solicitud, correo_enviado, correo_motivo} para que el admin
  // sepa si el correo con la decisión salió o falta configurarlo
  static Future<Map<String, dynamic>> actualizarSolicitudOrganizacion(
      String id, String estado) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/solicitudes/$id'),
      headers: _headers,
      body: jsonEncode({'estado': estado}),
    ).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['mensaje'] ?? 'Error al actualizar la solicitud');
    }
    return body['datos'] as Map<String, dynamic>? ?? {};
  }

  static Future<void> eliminarSolicitudOrganizacion(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/solicitudes/$id'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al eliminar la solicitud');
    }
  }

  // ── ORGANIZADOR: mi organización ──
  static Future<Organizacion> getMiOrganizacion() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/mi-organizacion'),
      headers: _headers,
    ).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Organizacion.fromJson(body['datos']);
    }
    throw Exception(body['mensaje'] ?? 'Error al cargar tu organización');
  }

  static Future<void> actualizarMiOrganizacion(
      {bool? mostrarMensajesMascota, String? foto}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/mi-organizacion'),
      headers: _headers,
      body: jsonEncode({
        if (mostrarMensajesMascota != null)
          'mostrar_mensajes_mascota': mostrarMensajesMascota,
        if (foto != null) 'foto': foto,
      }),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al actualizar la configuración');
    }
  }

  // ── Racha ─────────────────────────────────────────────────────────────────

  // Reanudar la racha perdida por un solo día (máx. 3 veces al mes).
  // Devuelve {racha, reanudaciones_restantes}.
  static Future<Map<String, dynamic>> reanudarRacha() async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/racha/reanudar'),
      headers: _headers,
    ).timeout(_timeout);

    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return body['datos'] as Map<String, dynamic>;
    }
    throw Exception(body['mensaje'] ?? 'No se pudo reanudar la racha');
  }

  // ── ADMIN: Niveles ────────────────────────────────────────────────────────

  static Future<void> crearNivel(
      String nombre, String descripcion, int orden, String dificultad) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/niveles'),
      headers: _headers,
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'orden': orden,
        'numero': orden,
        'dificultad': dificultad,
      }),
    ).timeout(_timeout);
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      final errores = body['errores'] as List?;
      if (errores != null && errores.isNotEmpty) {
        throw Exception(errores.map((e) => e['mensaje']).join('\n'));
      }
      throw Exception(body['mensaje'] ?? 'Error al crear nivel');
    }
    invalidateCache();
  }

  static Future<void> actualizarNivel(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/niveles/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al actualizar nivel');
    }
    invalidateCache();
  }

  // Aplica el orden específico definido por el admin: [{id, orden}]
  static Future<void> reordenarNiveles(
      List<Map<String, dynamic>> orden) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/niveles/reordenar'),
      headers: _headers,
      body: jsonEncode({'orden': orden}),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al reordenar niveles');
    }
    invalidateCache();
  }

  // Devuelve los conteos de lo eliminado en cascada
  static Future<Map<String, dynamic>> eliminarNivel(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/niveles/$id'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al eliminar nivel');
    }
    invalidateCache();
    return jsonDecode(response.body)['datos'] as Map<String, dynamic>? ?? {};
  }

  // ── ADMIN: Temas ──────────────────────────────────────────────────────────

  static Future<void> crearTema(
      String nombre, String descripcion, String nivelId, int orden) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/temas'),
      headers: _headers,
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'nivel_id': nivelId,
        'orden': orden,
      }),
    ).timeout(_timeout);
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      final errores = body['errores'] as List?;
      if (errores != null && errores.isNotEmpty) {
        throw Exception(errores.map((e) => e['mensaje']).join('\n'));
      }
      throw Exception(body['mensaje'] ?? 'Error al crear tema');
    }
    invalidateCache();
  }

  static Future<void> actualizarTema(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/temas/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al actualizar tema');
    }
    invalidateCache();
  }

  // Devuelve los conteos de lo eliminado en cascada
  static Future<Map<String, dynamic>> eliminarTema(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/temas/$id'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al eliminar tema');
    }
    invalidateCache();
    return jsonDecode(response.body)['datos'] as Map<String, dynamic>? ?? {};
  }

  // ── ADMIN: Lecciones (update / delete) ───────────────────────────────────

  static Future<void> actualizarLeccion(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/lecciones/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al actualizar lección');
    }
    invalidateCache();
  }

  // Devuelve los conteos de lo eliminado en cascada
  static Future<Map<String, dynamic>> eliminarLeccion(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/lecciones/$id'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al eliminar lección');
    }
    invalidateCache();
    return jsonDecode(response.body)['datos'] as Map<String, dynamic>? ?? {};
  }

  // ── ADMIN: Ejercicios ─────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getEjerciciosAdmin(
      {String? leccionId}) async {
    final query = leccionId != null ? '?leccion_id=$leccionId&limite=200' : '?limite=200';
    final response = await http.get(
      Uri.parse('$baseUrl/admin/ejercicios$query'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['datos']['datos']);
    } else {
      throw Exception('Error al cargar ejercicios');
    }
  }

  static Future<void> actualizarEjercicio(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/ejercicios/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al actualizar ejercicio');
    }
  }

  static Future<void> eliminarEjercicio(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/ejercicios/$id'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['mensaje'] ?? 'Error al eliminar ejercicio');
    }
  }
}
