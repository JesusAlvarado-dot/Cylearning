import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';
import '../models/models.dart';

class ApiService {
  static late String baseUrl;
  static String? _token;

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
    );

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
      String nombre, String email, String contrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'contrasena': contrasena,
      }),
    );

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

  static Future<bool> verificarToken() async {
    if (_token == null) return false;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  // NIVELES ENDPOINTS
  static Future<List<Nivel>> getNiveles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/niveles'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> nivelesJson = data['datos']['datos'];
      return nivelesJson.map((n) => Nivel.fromJson(n)).toList();
    } else {
      throw Exception('Error al cargar niveles');
    }
  }

  // LECCIONES ENDPOINTS
  static Future<List<Leccion>> getLecciones(String nivelId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/niveles/$nivelId/estructura'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> temas = data['datos']['temas'] ?? [];
      final List<Map<String, dynamic>> lecciones = [];
      for (final tema in temas) {
        final temaNombre = (tema['nombre'] as String?) ?? '';
        for (final leccion in (tema['lecciones'] as List? ?? [])) {
          final l = Map<String, dynamic>.from(leccion as Map);
          l['_tema_nombre'] = temaNombre;
          lecciones.add(l);
        }
      }
      return lecciones.map((l) => Leccion.fromJson(l)).toList();
    } else {
      throw Exception('Error al cargar lecciones');
    }
  }

  static Future<Leccion> getLeccion(String leccionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/lecciones/$leccionId'),
      headers: _headers,
    );

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
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> ejerciciosJson = data['datos']['ejercicios'] ?? [];
      return ejerciciosJson.map((e) => Ejercicio.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar ejercicios');
    }
  }

  // ADMIN ENDPOINTS
  static Future<List<EstudianteRanking>> getEstudiantes({String orden = 'desc'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/usuarios?orden=$orden&limite=100'),
      headers: _headers,
    );
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
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al dar medalla');
    }
  }

  static Future<List<Map<String, dynamic>>> getTemasAdmin() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/temas?limite=100'),
      headers: _headers,
    );
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
    );
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
    );
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      final errores = body['errores'] as List?;
      if (errores != null && errores.isNotEmpty) {
        throw Exception(errores.map((e) => e['mensaje']).join('\n'));
      }
      throw Exception(body['mensaje'] ?? 'Error al crear lección');
    }
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
    );
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      final errores = body['errores'] as List?;
      if (errores != null && errores.isNotEmpty) {
        throw Exception(errores.map((e) => e['mensaje']).join('\n'));
      }
      throw Exception(body['mensaje'] ?? 'Error al crear ejercicio');
    }
  }

  static Future<Map<String, dynamic>> submitEjercicio(
      String ejercicioId, int respuesta) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/ejercicios/$ejercicioId/responder'),
      headers: _headers,
      body: jsonEncode({'respuesta': respuesta}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al enviar respuesta');
    }
  }
}
