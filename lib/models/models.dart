class Medalla {
  final String tipo;
  final String descripcion;

  const Medalla({required this.tipo, required this.descripcion});

  factory Medalla.fromJson(Map<String, dynamic> json) => Medalla(
        tipo: json['tipo'] ?? '',
        descripcion: json['descripcion'] ?? '',
      );

  String get emoji {
    switch (tipo) {
      case 'oro': return '🥇';
      case 'plata': return '🥈';
      case 'bronce': return '🥉';
      case 'estrella': return '⭐';
      default: return '🏅';
    }
  }
}

class EstudianteRanking {
  final String id;
  final String nombre;
  final String email;
  final int puntosTotales;
  final List<Medalla> medallas;

  const EstudianteRanking({
    required this.id,
    required this.nombre,
    required this.email,
    required this.puntosTotales,
    required this.medallas,
  });

  factory EstudianteRanking.fromJson(Map<String, dynamic> json) {
    return EstudianteRanking(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      puntosTotales: json['puntos_totales'] as int? ?? 0,
      medallas: (json['medallas'] as List? ?? [])
          .map((m) => Medalla.fromJson(m))
          .toList(),
    );
  }
}

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final DateTime fechaRegistro;
  final int puntosTotales;
  final List<Medalla> medallas;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.fechaRegistro,
    this.puntosTotales = 0,
    this.medallas = const [],
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'student',
      fechaRegistro: DateTime.tryParse(
              json['fechaRegistro'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
      puntosTotales: json['puntos_totales'] as int? ?? 0,
      medallas: (json['medallas'] as List? ?? [])
          .map((m) => Medalla.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'puntos_totales': puntosTotales,
    };
  }
}

class Nivel {
  final String id;
  final String nombre;
  final String descripcion;
  final int orden;
  final List<String> temas;

  Nivel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.orden,
    required this.temas,
  });

  factory Nivel.fromJson(Map<String, dynamic> json) {
    return Nivel(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      orden: json['orden'] ?? 0,
      temas: List<String>.from(json['temas'] ?? []),
    );
  }
}

class Leccion {
  final String id;
  final String titulo;
  final String contenido;
  final String nivel;
  final String tema;
  final int duracion;

  Leccion({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.nivel,
    required this.tema,
    required this.duracion,
  });

  factory Leccion.fromJson(Map<String, dynamic> json) {
    final temaId = json['tema_id'];
    final tema = json['_tema_nombre'] ??
        json['tema'] ??
        (temaId is Map ? (temaId['nombre'] ?? '') : '');
    return Leccion(
      id: json['_id'] ?? '',
      titulo: json['nombre'] ?? json['titulo'] ?? '',
      contenido: json['contenido'] ?? '',
      nivel: json['nivel'] ?? '',
      tema: tema,
      duracion: json['duracion'] as int? ?? 0,
    );
  }
}

class Ejercicio {
  final String id;
  final String pregunta;
  final List<String> opciones;
  final int respuestaCorrecta;
  final String explicacion;
  final String tema;
  final int dificultad;

  Ejercicio({
    required this.id,
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
    required this.explicacion,
    required this.tema,
    required this.dificultad,
  });

  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    final opciones = List<String>.from(json['opciones'] ?? []);
    // Backend stores respuesta_correcta as a string; find its index in opciones
    final respStr = (json['respuesta_correcta'] ?? '').toString().trim().toLowerCase();
    final idx = opciones.indexWhere((o) => o.trim().toLowerCase() == respStr);
    return Ejercicio(
      id: json['_id'] ?? '',
      pregunta: json['pregunta'] ?? '',
      opciones: opciones,
      respuestaCorrecta: idx >= 0 ? idx : (json['respuestaCorrecta'] as int? ?? 0),
      explicacion: json['explicacion'] ?? '',
      tema: json['tema'] ?? '',
      dificultad: json['dificultad'] as int? ?? 1,
    );
  }
}
