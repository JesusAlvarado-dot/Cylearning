const Level = require('../models/Level');
const Topic = require('../models/Topic');
const Lesson = require('../models/Lesson');
const Exercise = require('../models/Exercise');
const ExerciseHistory = require('../models/ExerciseHistory');
const StudentProgress = require('../models/StudentProgress');
const Progreso = require('../models/Progreso');
const { respuestaExito, respuestaError, respuestaPaginada, paginar } = require('../utils/helpers');
const constants = require('../config/constants');
const Log = require('../models/Log');
const { esAdmin, esOrganizador, orgDelUsuario, puedeTocarNivel } = require('../utils/orgScope');

// Crear nivel (admin u organizador)
exports.crearNivel = async (req, res, next) => {
  try {
    const { nombre, descripcion, numero, dificultad, orden, organizacion_id } = req.body;

    // El organizador siempre crea dentro de SU organización; el admin puede
    // crear niveles públicos (sin organización) o asignarlos a una
    let orgId = null;
    if (esOrganizador(req)) {
      orgId = orgDelUsuario(req);
      if (!orgId) {
        return respuestaError(res, 'No perteneces a ninguna organización', 403);
      }
    } else if (organizacion_id) {
      orgId = organizacion_id;
    }

    const nivel = new Level({
      nombre,
      descripcion,
      numero,
      dificultad: dificultad || 'principiante',
      orden: orden || 0,
      organizacion_id: orgId,
    });

    await nivel.save();

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.LEVEL_CREATED,
      usuario_id: req.usuarioId,
      descripcion: `Nivel creado: ${nombre}`,
      entidad_tipo: 'level',
      entidad_id: nivel._id,
    });

    return respuestaExito(
      res,
      nivel,
      constants.SUCCESS_MESSAGES.EXERCISE_CREATED,
      201
    );
  } catch (error) {
    next(error);
  }
};

// Obtener todos los niveles.
// El contenido visible depende de quién pregunta:
//   - estudiante de una organización: SOLO los niveles de esa organización
//   - estudiante sin organización:    solo los niveles públicos
//   - organizador:                    los niveles de su organización
//   - admin:                          todos (con filtro opcional)
exports.obtenerTodosLosNiveles = async (req, res, next) => {
  try {
    const { pagina = 1, limite = 10, activo, organizacion_id } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const filtro = {};
    if (activo !== undefined) {
      filtro.activo = activo === 'true';
    }

    if (esAdmin(req)) {
      if (organizacion_id === 'publicos') filtro.organizacion_id = null;
      else if (organizacion_id) filtro.organizacion_id = organizacion_id;
    } else {
      // Estudiantes y organizadores: su organización o el catálogo público
      filtro.organizacion_id = orgDelUsuario(req);
    }

    const niveles = await Level.find(filtro)
      .skip(skip)
      .limit(limit)
      .sort({ orden: 1, numero: 1 })
      .lean();

    // Adjuntar las lecciones de cada nivel para que el cliente
    // pueda mostrar el progreso real (X/Y lecciones completadas)
    const nivelIds = niveles.map((n) => n._id);
    const temas = await Topic.find({ nivel_id: { $in: nivelIds } })
      .select('_id nivel_id')
      .lean();
    const lecciones = await Lesson.find({ tema_id: { $in: temas.map((t) => t._id) } })
      .select('_id tema_id')
      .lean();

    const nivelDeTema = new Map(temas.map((t) => [t._id.toString(), t.nivel_id.toString()]));
    const leccionesPorNivel = {};
    for (const l of lecciones) {
      const nivelId = nivelDeTema.get(l.tema_id.toString());
      if (!nivelId) continue;
      (leccionesPorNivel[nivelId] = leccionesPorNivel[nivelId] || []).push(l._id.toString());
    }
    for (const n of niveles) {
      n.lecciones = leccionesPorNivel[n._id.toString()] || [];
      n.total_lecciones = n.lecciones.length;
    }

    const total = await Level.countDocuments(filtro);

    const respuesta = respuestaPaginada(niveles, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Niveles obtenidos exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Reordenar niveles (solo admin): recibe [{ id, orden }] y aplica el orden
// específico definido por el admin (independiente de la dificultad)
exports.reordenarNiveles = async (req, res, next) => {
  try {
    const { orden } = req.body; // [{ id: '...', orden: 1 }, ...]

    if (!Array.isArray(orden) || orden.length === 0) {
      return respuestaError(res, 'Se requiere un arreglo "orden" con { id, orden }', 400);
    }
    for (const item of orden) {
      if (!item.id || typeof item.orden !== 'number') {
        return respuestaError(res, 'Cada elemento debe tener id y orden numérico', 400);
      }
      if (!(await puedeTocarNivel(req, item.id))) {
        return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
      }
    }

    await Level.bulkWrite(
      orden.map((item) => ({
        updateOne: {
          filter: { _id: item.id },
          update: { $set: { orden: item.orden } },
        },
      }))
    );

    await Log.create({
      tipo: 'actualizado',
      usuario_id: req.usuarioId,
      descripcion: `Niveles reordenados (${orden.length})`,
      entidad_tipo: 'level',
    });

    const niveles = await Level.find().sort({ orden: 1, numero: 1 });
    return respuestaExito(res, niveles, 'Orden de niveles actualizado');
  } catch (error) {
    next(error);
  }
};

// Obtener nivel por ID
exports.obtenerNivelPorId = async (req, res, next) => {
  try {
    const { id } = req.params;

    const nivel = await Level.findById(id);

    if (!nivel) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LEVEL_NOT_FOUND,
        404
      );
    }

    // Obtener temas del nivel
    const temas = await Topic.find({ nivel_id: id }).sort({ orden: 1 });

    return respuestaExito(
      res,
      { ...nivel.toObject(), temas },
      'Nivel obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Actualizar nivel (admin, u organizador sobre su propio contenido)
exports.actualizarNivel = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion, dificultad, orden, activo } = req.body;

    if (!(await puedeTocarNivel(req, id))) {
      return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
    }

    const nivel = await Level.findByIdAndUpdate(
      id,
      { nombre, descripcion, dificultad, orden, activo },
      { new: true, runValidators: true }
    );

    if (!nivel) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LEVEL_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: 'actualizado',
      usuario_id: req.usuarioId,
      descripcion: `Nivel actualizado: ${nombre}`,
      entidad_tipo: 'level',
      entidad_id: nivel._id,
    });

    return respuestaExito(
      res,
      nivel,
      'Nivel actualizado exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Eliminar nivel (admin u organizador dueño) — borrado en cascada
exports.eliminarNivel = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!(await puedeTocarNivel(req, id))) {
      return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
    }

    const nivel = await Level.findById(id);
    if (!nivel) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LEVEL_NOT_FOUND,
        404
      );
    }

    // Recolectar todo el contenido anidado
    const temas = await Topic.find({ nivel_id: id }).select('_id');
    const temaIds = temas.map((t) => t._id);
    const lecciones = await Lesson.find({ tema_id: { $in: temaIds } }).select('_id');
    const leccionIds = lecciones.map((l) => l._id);

    // Borrar en cascada: ejercicios, historial y progreso relacionado
    const ejercicios = await Exercise.deleteMany({ leccion_id: { $in: leccionIds } });
    await ExerciseHistory.deleteMany({ leccion_id: { $in: leccionIds } });
    await StudentProgress.deleteMany({ nivel_id: id });
    await Progreso.updateMany(
      {},
      { $pull: { lecciones_completadas: { $in: leccionIds }, niveles_completados: nivel._id } }
    );
    await Lesson.deleteMany({ tema_id: { $in: temaIds } });
    await Topic.deleteMany({ nivel_id: id });
    await nivel.deleteOne();

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.LEVEL_DELETED,
      usuario_id: req.usuarioId,
      descripcion: `Nivel eliminado en cascada: ${nivel.nombre} (${temaIds.length} temas, ${leccionIds.length} lecciones, ${ejercicios.deletedCount} ejercicios)`,
      entidad_tipo: 'level',
      entidad_id: nivel._id,
    });

    return respuestaExito(
      res,
      {
        temas_eliminados: temaIds.length,
        lecciones_eliminadas: leccionIds.length,
        ejercicios_eliminados: ejercicios.deletedCount,
      },
      'Nivel y todo su contenido eliminados exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener nivel con estructura completa (niveles -> temas -> lecciones)
exports.obtenerEstructuraNivel = async (req, res, next) => {
  try {
    const { id } = req.params;

    const nivel = await Level.findById(id);

    if (!nivel) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LEVEL_NOT_FOUND,
        404
      );
    }

    // Obtener temas con lecciones
    const temas = await Topic.find({ nivel_id: id })
      .sort({ orden: 1 })
      .lean();

    for (let tema of temas) {
      tema.lecciones = await Lesson.find({ tema_id: tema._id })
        .sort({ orden: 1 })
        .lean();
    }

    return respuestaExito(
      res,
      { ...nivel.toObject(), temas },
      'Estructura del nivel obtenida exitosamente'
    );
  } catch (error) {
    next(error);
  }
};
