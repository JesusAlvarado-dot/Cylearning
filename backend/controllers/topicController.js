const Topic = require('../models/Topic');
const Level = require('../models/Level');
const Lesson = require('../models/Lesson');
const Exercise = require('../models/Exercise');
const ExerciseHistory = require('../models/ExerciseHistory');
const StudentProgress = require('../models/StudentProgress');
const Progreso = require('../models/Progreso');
const { respuestaExito, respuestaError, respuestaPaginada, paginar } = require('../utils/helpers');
const constants = require('../config/constants');
const Log = require('../models/Log');
const { puedeTocarNivel, puedeTocarTema, nivelesDelAlcance } = require('../utils/orgScope');

// Crear tema (admin u organizador sobre niveles de su organización)
exports.crearTema = async (req, res, next) => {
  try {
    const { nombre, descripcion, nivel_id, orden, mascota, mensaje_mascota } = req.body;

    // Validar que el nivel existe
    const nivel = await Level.findById(nivel_id);
    if (!nivel) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LEVEL_NOT_FOUND,
        404
      );
    }

    if (!(await puedeTocarNivel(req, nivel_id))) {
      return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
    }

    const tema = new Topic({
      nombre,
      descripcion,
      nivel_id,
      orden: orden || 0,
      mascota: mascota ?? null,
      mensaje_mascota: mensaje_mascota || '',
    });

    await tema.save();

    // Registrar en logs
    await Log.create({
      tipo: 'creado',
      usuario_id: req.usuarioId,
      descripcion: `Tema creado: ${nombre}`,
      entidad_tipo: 'topic',
      entidad_id: tema._id,
    });

    return respuestaExito(
      res,
      tema,
      constants.SUCCESS_MESSAGES.EXERCISE_CREATED,
      201
    );
  } catch (error) {
    next(error);
  }
};

// Obtener todos los temas (el organizador solo ve los de su organización)
exports.obtenerTodoLosTemas = async (req, res, next) => {
  try {
    const { pagina = 1, limite = 10, nivel_id, activo } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const filtro = {};
    if (nivel_id) filtro.nivel_id = nivel_id;
    if (activo !== undefined) filtro.activo = activo === 'true';

    // Organizador: limitar a los niveles de su organización
    const alcance = await nivelesDelAlcance(req);
    if (alcance !== null) {
      filtro.nivel_id = nivel_id
        ? nivel_id // ya se validará que esté dentro del alcance abajo
        : { $in: alcance };
      if (nivel_id && !alcance.some((id) => id.toString() === nivel_id)) {
        return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
      }
    }

    const temas = await Topic.find(filtro)
      .skip(skip)
      .limit(limit)
      .populate('nivel_id', 'nombre')
      .sort({ orden: 1 });

    const total = await Topic.countDocuments(filtro);

    const respuesta = respuestaPaginada(temas, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Temas obtenidos exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener tema por ID
exports.obtenerTemaPorId = async (req, res, next) => {
  try {
    const { id } = req.params;

    const tema = await Topic.findById(id).populate('nivel_id', 'nombre');

    if (!tema) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.TOPIC_NOT_FOUND,
        404
      );
    }

    // Obtener lecciones del tema
    const lecciones = await Lesson.find({ tema_id: id }).sort({ orden: 1 });

    return respuestaExito(
      res,
      { ...tema.toObject(), lecciones },
      'Tema obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Actualizar tema (admin u organizador dueño)
exports.actualizarTema = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion, orden, activo, mascota, mensaje_mascota } = req.body;

    if (!(await puedeTocarTema(req, id))) {
      return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
    }

    const tema = await Topic.findByIdAndUpdate(
      id,
      { nombre, descripcion, orden, activo, mascota, mensaje_mascota },
      { new: true, runValidators: true }
    ).populate('nivel_id', 'nombre');

    if (!tema) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.TOPIC_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: 'actualizado',
      usuario_id: req.usuarioId,
      descripcion: `Tema actualizado: ${nombre}`,
      entidad_tipo: 'topic',
      entidad_id: tema._id,
    });

    return respuestaExito(
      res,
      tema,
      'Tema actualizado exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Eliminar tema (admin u organizador dueño) — cascada de lecciones/ejercicios
exports.eliminarTema = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!(await puedeTocarTema(req, id))) {
      return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
    }

    const tema = await Topic.findById(id);
    if (!tema) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.TOPIC_NOT_FOUND,
        404
      );
    }

    const lecciones = await Lesson.find({ tema_id: id }).select('_id');
    const leccionIds = lecciones.map((l) => l._id);

    // Borrar en cascada: ejercicios, historial y progreso relacionado
    const ejercicios = await Exercise.deleteMany({ leccion_id: { $in: leccionIds } });
    await ExerciseHistory.deleteMany({ leccion_id: { $in: leccionIds } });
    await StudentProgress.deleteMany({ tema_id: id });
    await Progreso.updateMany(
      {},
      { $pull: { lecciones_completadas: { $in: leccionIds } } }
    );
    await Lesson.deleteMany({ tema_id: id });
    await tema.deleteOne();

    // Registrar en logs
    await Log.create({
      tipo: 'eliminado',
      usuario_id: req.usuarioId,
      descripcion: `Tema eliminado en cascada: ${tema.nombre} (${leccionIds.length} lecciones, ${ejercicios.deletedCount} ejercicios)`,
      entidad_tipo: 'topic',
      entidad_id: tema._id,
    });

    return respuestaExito(
      res,
      {
        lecciones_eliminadas: leccionIds.length,
        ejercicios_eliminados: ejercicios.deletedCount,
      },
      'Tema y todo su contenido eliminados exitosamente'
    );
  } catch (error) {
    next(error);
  }
};
