const Lesson = require('../models/Lesson');
const Topic = require('../models/Topic');
const Exercise = require('../models/Exercise');
const ExerciseHistory = require('../models/ExerciseHistory');
const StudentProgress = require('../models/StudentProgress');
const Progreso = require('../models/Progreso');
const { respuestaExito, respuestaError, respuestaPaginada, paginar, ocultarRespuesta } = require('../utils/helpers');
const constants = require('../config/constants');
const Log = require('../models/Log');

// Crear lección (solo admin)
exports.crearLeccion = async (req, res, next) => {
  try {
    const { nombre, descripcion, tema_id, contenido, orden, punto_minimo } = req.body;

    // Validar que el tema existe
    const tema = await Topic.findById(tema_id);
    if (!tema) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.TOPIC_NOT_FOUND,
        404
      );
    }

    const leccion = new Lesson({
      nombre,
      descripcion,
      tema_id,
      contenido,
      orden: orden || 0,
      punto_minimo: punto_minimo || 0,
    });

    await leccion.save();

    // Registrar en logs
    await Log.create({
      tipo: 'creado',
      usuario_id: req.usuarioId,
      descripcion: `Lección creada: ${nombre}`,
      entidad_tipo: 'lesson',
      entidad_id: leccion._id,
    });

    return respuestaExito(
      res,
      leccion,
      constants.SUCCESS_MESSAGES.EXERCISE_CREATED,
      201
    );
  } catch (error) {
    next(error);
  }
};

// Obtener todas las lecciones
exports.obtenerTodasLasLecciones = async (req, res, next) => {
  try {
    const { pagina = 1, limite = 10, tema_id, activo } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const filtro = {};
    if (tema_id) filtro.tema_id = tema_id;
    if (activo !== undefined) filtro.activo = activo === 'true';

    const lecciones = await Lesson.find(filtro)
      .skip(skip)
      .limit(limit)
      .populate('tema_id', 'nombre')
      .sort({ orden: 1 });

    const total = await Lesson.countDocuments(filtro);

    const respuesta = respuestaPaginada(lecciones, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Lecciones obtenidas exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener lección por ID
exports.obtenerLeccionPorId = async (req, res, next) => {
  try {
    const { id } = req.params;

    const leccion = await Lesson.findById(id)
      .populate('tema_id', 'nombre nivel_id')
      .populate({
        path: 'tema_id',
        populate: { path: 'nivel_id', select: 'nombre' },
      });

    if (!leccion) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LESSON_NOT_FOUND,
        404
      );
    }

    // Obtener ejercicios activos de la lección
    let ejercicios = await Exercise.find({
      leccion_id: id,
      activo: true,
    }).sort({ orden: 1 });

    // Los estudiantes no deben recibir la respuesta correcta
    if (req.rol !== constants.ROLES.ADMIN) {
      ejercicios = ejercicios.map(ocultarRespuesta);
    }

    return respuestaExito(
      res,
      { ...leccion.toObject(), ejercicios },
      'Lección obtenida exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Actualizar lección (solo admin)
exports.actualizarLeccion = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion, contenido, orden, activo, punto_minimo } = req.body;

    const leccion = await Lesson.findByIdAndUpdate(
      id,
      { nombre, descripcion, contenido, orden, activo, punto_minimo },
      { new: true, runValidators: true }
    ).populate('tema_id', 'nombre');

    if (!leccion) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LESSON_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: 'actualizado',
      usuario_id: req.usuarioId,
      descripcion: `Lección actualizada: ${nombre}`,
      entidad_tipo: 'lesson',
      entidad_id: leccion._id,
    });

    return respuestaExito(
      res,
      leccion,
      'Lección actualizada exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Eliminar lección (solo admin) — borrado en cascada de sus ejercicios
exports.eliminarLeccion = async (req, res, next) => {
  try {
    const { id } = req.params;

    const leccion = await Lesson.findById(id);
    if (!leccion) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LESSON_NOT_FOUND,
        404
      );
    }

    // Borrar en cascada: ejercicios, historial y progreso relacionado
    const ejercicios = await Exercise.deleteMany({ leccion_id: id });
    await ExerciseHistory.deleteMany({ leccion_id: id });
    await StudentProgress.deleteMany({ leccion_id: id });
    await Progreso.updateMany(
      {},
      { $pull: { lecciones_completadas: leccion._id } }
    );
    await leccion.deleteOne();

    // Registrar en logs
    await Log.create({
      tipo: 'eliminado',
      usuario_id: req.usuarioId,
      descripcion: `Lección eliminada en cascada: ${leccion.nombre} (${ejercicios.deletedCount} ejercicios)`,
      entidad_tipo: 'lesson',
      entidad_id: leccion._id,
    });

    return respuestaExito(
      res,
      { ejercicios_eliminados: ejercicios.deletedCount },
      'Lección y sus ejercicios eliminados exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Iniciar lección (estudiante)
exports.iniciarLeccion = async (req, res, next) => {
  try {
    const { id } = req.params;
    const estudianteId = req.usuarioId;

    // Obtener lección
    const leccion = await Lesson.findById(id)
      .populate('tema_id', 'nombre nivel_id')
      .populate({
        path: 'tema_id',
        populate: { path: 'nivel_id', select: 'nombre' },
      });

    if (!leccion) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LESSON_NOT_FOUND,
        404
      );
    }

    // Verificar o crear progreso
    let progreso = await StudentProgress.findOne({
      estudiante_id: estudianteId,
      leccion_id: id,
    });

    if (!progreso) {
      progreso = await StudentProgress.create({
        estudiante_id: estudianteId,
        leccion_id: id,
        tema_id: leccion.tema_id._id,
        nivel_id: leccion.tema_id.nivel_id._id,
        estado: constants.PROGRESS_STATUS.IN_PROGRESS,
      });
    } else if (progreso.estado === constants.PROGRESS_STATUS.NOT_STARTED) {
      progreso.estado = constants.PROGRESS_STATUS.IN_PROGRESS;
      await progreso.save();
    }

    // Obtener ejercicios sin la respuesta correcta (la calificación es del servidor)
    const ejercicios = await Exercise.find({
      leccion_id: id,
      activo: true,
    })
      .sort({ orden: 1 });

    return respuestaExito(
      res,
      {
        leccion,
        ejercicios: ejercicios.map(ocultarRespuesta),
        progreso,
      },
      'Lección iniciada exitosamente'
    );
  } catch (error) {
    next(error);
  }
};
