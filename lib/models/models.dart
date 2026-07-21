import '../config/config.dart';

class ProgresoResumen {
  final Set<String> leccionesCompletadas;
  final Set<String> nivelesCompletados;

  ProgresoResumen({
    required this.leccionesCompletadas,
    required this.nivelesCompletados,
  });

  factory ProgresoResumen.fromJson(Map<String, dynamic> json) => ProgresoResumen(
    leccionesCompletadas: Set<String>.from(
        (json['lecciones_completadas'] as List? ?? []).map((e) => e.toString())),
    nivelesCompletados: Set<String>.from(
        (json['niveles_completados'] as List? ?? []).map((e) => e.toString())),
  );

  static ProgresoResumen empty() => ProgresoResumen(
    leccionesCompletadas: {},
    nivelesCompletados: {},
  );
}

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
      case 'justiciero': return '🦸';
      default: return '🏅';
    }
  }
}

class EstudianteRanking {
  final String id;
  final String nombre;
  final String email;
  final int puntosTotales;
  final int racha;
  final List<Medalla> medallas;
  final String foto;

  const EstudianteRanking({
    required this.id,
    required this.nombre,
    required this.email,
    required this.puntosTotales,
    this.racha = 0,
    required this.medallas,
    this.foto = '',
  });

  factory EstudianteRanking.fromJson(Map<String, dynamic> json) {
    return EstudianteRanking(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      puntosTotales: json['puntos_totales'] as int? ?? 0,
      racha: json['racha'] as int? ?? 0,
      medallas: (json['medallas'] as List? ?? [])
          .map((m) => Medalla.fromJson(m))
          .toList(),
      foto: json['foto'] ?? '',
    );
  }
}

// Datos de la organización a la que pertenece el usuario (viene poblada
// en login y /me). El sector define el tema visual de la app.
class OrganizacionInfo {
  final String id;
  final String nombre;
  final String sector; // escuela | colegio | universidad | empresa
  final String codigo;
  final bool mostrarMensajesMascota;

  const OrganizacionInfo({
    required this.id,
    required this.nombre,
    required this.sector,
    required this.codigo,
    this.mostrarMensajesMascota = true,
  });

  factory OrganizacionInfo.fromJson(Map<String, dynamic> json) =>
      OrganizacionInfo(
        id: json['_id'] ?? '',
        nombre: json['nombre'] ?? '',
        sector: json['sector'] ?? 'escuela',
        codigo: json['codigo'] ?? '',
        mostrarMensajesMascota:
            json['mostrar_mensajes_mascota'] as bool? ?? true,
      );
}

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final DateTime fechaRegistro;
  final int puntosTotales;
  final int racha;
  final List<Medalla> medallas;
  final String foto;
  final OrganizacionInfo? organizacion;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.fechaRegistro,
    this.puntosTotales = 0,
    this.racha = 0,
    this.medallas = const [],
    this.foto = '',
    this.organizacion,
  });

  bool get esAdmin => rol == 'admin';
  bool get esOrganizador => rol == 'organizador';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // organizacion_id llega poblado (Map) desde login//me, o como String/null
    OrganizacionInfo? org;
    final rawOrg = json['organizacion_id'];
    if (rawOrg is Map<String, dynamic>) {
      org = OrganizacionInfo.fromJson(rawOrg);
    }
    return Usuario(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'student',
      fechaRegistro: DateTime.tryParse(
              json['fechaRegistro'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
      puntosTotales: json['puntos_totales'] as int? ?? 0,
      racha: json['racha'] as int? ?? 0,
      medallas: (json['medallas'] as List? ?? [])
          .map((m) => Medalla.fromJson(m))
          .toList(),
      foto: json['foto'] ?? '',
      organizacion: org,
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
  final List<String> leccionesIds;

  Nivel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.orden,
    required this.temas,
    this.leccionesIds = const [],
  });

  int get totalLecciones => leccionesIds.length;

  factory Nivel.fromJson(Map<String, dynamic> json) {
    return Nivel(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      // 'orden' y 'numero' se mantienen sincronizados en el backend;
      // si orden falta, usar numero
      orden: json['orden'] as int? ?? json['numero'] as int? ?? 0,
      temas: List<String>.from(json['temas'] ?? []),
      leccionesIds: (json['lecciones'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
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
  // Personalización de la mascota del tema (configurable por la organización)
  final int? temaMascota;
  final String temaMensaje;

  Leccion({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.nivel,
    required this.tema,
    required this.duracion,
    this.temaMascota,
    this.temaMensaje = '',
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
      temaMascota: json['_tema_mascota'] as int?,
      temaMensaje: (json['_tema_mensaje'] as String?) ?? '',
    );
  }
}

// ─── Organizaciones (panel admin) ───────────────────────────────────────────

class Organizacion {
  final String id;
  final String nombre;
  final String codigo;
  final String codigoDocente;
  final String sector;
  final String email;
  final bool activo;
  final bool mostrarMensajesMascota;
  final String foto;
  final int totalUsuarios;
  final int totalNiveles;

  const Organizacion({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.codigoDocente = '',
    required this.sector,
    required this.email,
    this.activo = true,
    this.mostrarMensajesMascota = true,
    this.foto = '',
    this.totalUsuarios = 0,
    this.totalNiveles = 0,
  });

  factory Organizacion.fromJson(Map<String, dynamic> json) => Organizacion(
        id: json['_id'] ?? '',
        nombre: json['nombre'] ?? '',
        codigo: json['codigo'] ?? '',
        codigoDocente: json['codigo_docente'] ?? '',
        sector: json['sector'] ?? 'escuela',
        email: json['email'] ?? '',
        activo: json['activo'] as bool? ?? true,
        mostrarMensajesMascota:
            json['mostrar_mensajes_mascota'] as bool? ?? true,
        foto: json['foto'] ?? '',
        totalUsuarios: json['total_usuarios'] as int? ?? 0,
        totalNiveles: json['total_niveles'] as int? ?? 0,
      );

  // Links de invitación: URL web pública (funciona en cualquier navegador,
  // no solo si el destinatario ya tiene la app Android instalada) que abre
  // el registro con el código ya puesto.
  String get linkEstudiantes => '${Config.appUrl}/#/unirse?codigo=$codigo';
  String get linkDocentes => '${Config.appUrl}/#/unirse?codigo=$codigoDocente';
}

// Resultado de validar un código de invitación (banner del registro)
class InfoInvitacion {
  final String nombre;
  final String sector;
  final String tipo; // estudiante | docente

  const InfoInvitacion({
    required this.nombre,
    required this.sector,
    required this.tipo,
  });

  factory InfoInvitacion.fromJson(Map<String, dynamic> json) => InfoInvitacion(
        nombre: json['nombre'] ?? '',
        sector: json['sector'] ?? 'escuela',
        tipo: json['tipo'] ?? 'estudiante',
      );
}

class SolicitudOrganizacion {
  final String id;
  final String nombreOrganizacion;
  final String email;
  final String sector;
  final String mensaje;
  final String estado; // pendiente | atendida
  final DateTime fecha;

  const SolicitudOrganizacion({
    required this.id,
    required this.nombreOrganizacion,
    required this.email,
    required this.sector,
    required this.mensaje,
    required this.estado,
    required this.fecha,
  });

  factory SolicitudOrganizacion.fromJson(Map<String, dynamic> json) =>
      SolicitudOrganizacion(
        id: json['_id'] ?? '',
        nombreOrganizacion: json['nombre_organizacion'] ?? '',
        email: json['email'] ?? '',
        sector: json['sector'] ?? 'escuela',
        mensaje: json['mensaje'] ?? '',
        estado: json['estado'] ?? 'pendiente',
        fecha: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

// Reporte de un usuario (foto de perfil) o de un ejercicio. `entidad` trae
// un resumen de lo reportado (solo lo llena el backend en la vista admin);
// `reportadoPorNombre` también es solo para esa vista.
class Reporte {
  final String id;
  final String tipo; // 'usuario_foto' | 'ejercicio'
  final String entidadId;
  final String motivo;
  final String estado; // 'pendiente' | 'fundado' | 'infundado'
  final String respuestaAdmin;
  final DateTime fecha;
  final String reportadoPorNombre;
  final Map<String, dynamic>? entidad;

  const Reporte({
    required this.id,
    required this.tipo,
    required this.entidadId,
    required this.motivo,
    required this.estado,
    this.respuestaAdmin = '',
    required this.fecha,
    this.reportadoPorNombre = '',
    this.entidad,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    final reportador = json['reportado_por'];
    return Reporte(
      id: json['_id'] ?? '',
      tipo: json['tipo'] ?? '',
      entidadId: json['entidad_id']?.toString() ?? '',
      motivo: json['motivo'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      respuestaAdmin: json['respuesta_admin'] ?? '',
      fecha: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      reportadoPorNombre: reportador is Map ? (reportador['nombre'] ?? '') : '',
      entidad: json['entidad'] is Map
          ? Map<String, dynamic>.from(json['entidad'])
          : null,
    );
  }
}

// Etiquetas y emojis de los sectores disponibles
const sectoresDisponibles = {
  'escuela': ('🎒', 'Escuela'),
  'colegio': ('📘', 'Colegio'),
  'universidad': ('🎓', 'Universidad'),
  'empresa': ('🏢', 'Organización/Empresa'),
};

class Ejercicio {
  final String id;
  final String pregunta;
  final List<String> opciones;
  final String tema;
  final int dificultad;

  Ejercicio({
    required this.id,
    required this.pregunta,
    required this.opciones,
    required this.tema,
    required this.dificultad,
  });

  // El backend ya no envía respuesta_correcta: la calificación
  // se hace en el servidor vía ApiService.submitEjercicio
  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    return Ejercicio(
      id: json['_id'] ?? '',
      pregunta: json['pregunta'] ?? '',
      opciones: List<String>.from(json['opciones'] ?? []),
      tema: json['tema'] ?? '',
      dificultad: json['dificultad'] as int? ?? 1,
    );
  }

  // Índice de la respuesta correcta devuelta por el servidor tras responder
  int indexDeRespuesta(String respuestaCorrecta) {
    final r = respuestaCorrecta.trim().toLowerCase();
    return opciones.indexWhere((o) => o.trim().toLowerCase() == r);
  }
}
