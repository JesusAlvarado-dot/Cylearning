const Exercise = require('../models/Exercise');
const Lesson = require('../models/Lesson');
const ExerciseHistory = require('../models/ExerciseHistory');
const StudentProgress = require('../models/StudentProgress');
const User = require('../models/User');
const { registrarActividad } = require('../utils/streak');
const { puedeTocarLeccion, nivelesDelAlcance } = require('../utils/orgScope');
const Topic = require('../models/Topic');
const { respuestaExito, respuestaError, respuestaPaginada, paginar, compararRespuestas, calcularPorcentaje, ocultarRespuesta } = require('../utils/helpers');
const constants = require('../config/constants');
const Log = require('../models/Log');

// Crear ejercicio (solo admin)
exports.crearEjercicio = async (req, res, next) => {
  try {
    const {
      pregunta,
      tipo,
      opciones,
      respuesta_correcta,
      explicacion,
      puntos,
      leccion_id,
      orden,
    } = req.body;

    // Validar que la lección existe
    const leccion = await Lesson.findById(leccion_id);
    if (!leccion) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LESSON_NOT_FOUND,
        404
      );
    }

    if (!(await puedeTocarLeccion(req, leccion_id))) {
      return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
    }

    const ejercicio = new Exercise({
      pregunta,
      tipo,
      opciones: opciones || [],
      respuesta_correcta,
      explicacion,
      puntos: puntos || constants.DEFAULT_POINTS,
      leccion_id,
      orden: orden || 0,
      creado_por: req.usuarioId,
    });

    await ejercicio.save();

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.EXERCISE_CREATED,
      usuario_id: req.usuarioId,
      descripcion: `Ejercicio creado: ${pregunta.substring(0, 50)}`,
      entidad_tipo: 'exercise',
      entidad_id: ejercicio._id,
    });

    return respuestaExito(
      res,
      ejercicio,
      constants.SUCCESS_MESSAGES.EXERCISE_CREATED,
      201
    );
  } catch (error) {
    next(error);
  }
};

// Obtener todos los ejercicios
exports.obtenerTodosLosEjercicios = async (req, res, next) => {
  try {
    const { pagina = 1, limite = 10, leccion_id, activo } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const filtro = {};
    if (leccion_id) filtro.leccion_id = leccion_id;
    if (activo !== undefined) filtro.activo = activo === 'true';

    // Organizador: limitar a ejercicios de lecciones de su organización
    const alcance = await nivelesDelAlcance(req);
    if (alcance !== null && req.rol === constants.ROLES.ORGANIZER) {
      const temasOrg = await Topic.find({ nivel_id: { $in: alcance } }).select('_id');
      const leccionesOrg = await Lesson.find({ tema_id: { $in: temasOrg.map((t) => t._id) } }).select('_id');
      const leccionIds = leccionesOrg.map((l) => l._id.toString());
      if (leccion_id && !leccionIds.includes(leccion_id)) {
        return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
      }
      if (!leccion_id) filtro.leccion_id = { $in: leccionesOrg.map((l) => l._id) };
    }

    let ejercicios = await Exercise.find(filtro)
      .skip(skip)
      .limit(limit)
      .populate('leccion_id', 'nombre')
      .populate('creado_por', 'nombre email')
      .sort({ orden: 1 });

    // Los estudiantes no deben recibir la respuesta correcta
    if (req.rol !== constants.ROLES.ADMIN && req.rol !== constants.ROLES.ORGANIZER) {
      ejercicios = ejercicios.map(ocultarRespuesta);
    }

    const total = await Exercise.countDocuments(filtro);

    const respuesta = respuestaPaginada(ejercicios, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Ejercicios obtenidos exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener ejercicio por ID
exports.obtenerEjercicioPorId = async (req, res, next) => {
  try {
    const { id } = req.params;

    const ejercicio = await Exercise.findById(id)
      .populate('leccion_id', 'nombre')
      .populate('creado_por', 'nombre email');

    if (!ejercicio) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.EXERCISE_NOT_FOUND,
        404
      );
    }

    const esGestor = req.rol === constants.ROLES.ADMIN || req.rol === constants.ROLES.ORGANIZER;
    return respuestaExito(
      res,
      esGestor ? ejercicio : ocultarRespuesta(ejercicio),
      'Ejercicio obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Actualizar ejercicio (solo admin)
exports.actualizarEjercicio = async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      pregunta,
      tipo,
      opciones,
      respuesta_correcta,
      explicacion,
      puntos,
      orden,
      activo,
    } = req.body;

    const existente = await Exercise.findById(id).select('leccion_id');
    if (existente && !(await puedeTocarLeccion(req, existente.leccion_id))) {
      return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
    }

    const ejercicio = await Exercise.findByIdAndUpdate(
      id,
      {
        pregunta,
        tipo,
        opciones,
        respuesta_correcta,
        explicacion,
        puntos,
        orden,
        activo,
      },
      { new: true, runValidators: true }
    )
      .populate('leccion_id', 'nombre')
      .populate('creado_por', 'nombre');

    if (!ejercicio) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.EXERCISE_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.EXERCISE_UPDATED,
      usuario_id: req.usuarioId,
      descripcion: `Ejercicio actualizado: ${ejercicio.pregunta.substring(0, 50)}`,
      entidad_tipo: 'exercise',
      entidad_id: ejercicio._id,
    });

    return respuestaExito(
      res,
      ejercicio,
      constants.SUCCESS_MESSAGES.EXERCISE_UPDATED
    );
  } catch (error) {
    next(error);
  }
};

// Eliminar ejercicio (admin u organizador dueño)
exports.eliminarEjercicio = async (req, res, next) => {
  try {
    const { id } = req.params;

    const previo = await Exercise.findById(id).select('leccion_id');
    if (previo && !(await puedeTocarLeccion(req, previo.leccion_id))) {
      return respuestaError(res, constants.ERROR_MESSAGES.FORBIDDEN, 403);
    }

    const ejercicio = await Exercise.findByIdAndDelete(id);

    if (!ejercicio) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.EXERCISE_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.EXERCISE_DELETED,
      usuario_id: req.usuarioId,
      descripcion: `Ejercicio eliminado: ${ejercicio.pregunta.substring(0, 50)}`,
      entidad_tipo: 'exercise',
      entidad_id: ejercicio._id,
    });

    return respuestaExito(
      res,
      {},
      constants.SUCCESS_MESSAGES.EXERCISE_DELETED
    );
  } catch (error) {
    next(error);
  }
};

// Responder ejercicio (estudiante)
exports.responderEjercicio = async (req, res, next) => {
  try {
    const { id } = req.params;
    const estudianteId = req.usuarioId;

    if (req.body.respuesta === undefined || req.body.respuesta === null || req.body.respuesta === '') {
      return respuestaError(res, 'La respuesta es requerida', 400);
    }

    // Aceptar números y booleanos (el cliente puede enviar índices o true/false)
    const respuesta = String(req.body.respuesta);

    // Obtener ejercicio
    const ejercicio = await Exercise.findById(id);

    if (!ejercicio) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.EXERCISE_NOT_FOUND,
        404
      );
    }

    // Comparar respuestas
    const esCorrecta = compararRespuestas(respuesta, ejercicio.respuesta_correcta);

    // Calcular puntos
    const puntosGanados = esCorrecta ? ejercicio.puntos : 0;

    // Registrar respuesta en historial
    const historial = await ExerciseHistory.create({
      estudiante_id: estudianteId,
      ejercicio_id: id,
      leccion_id: ejercicio.leccion_id,
      respuesta_ingresada: respuesta,
      estado: esCorrecta ? constants.ANSWER_STATUS.CORRECT : constants.ANSWER_STATUS.INCORRECT,
      puntos_ganados: puntosGanados,
    });

    // Actualizar progreso del estudiante
    const progreso = await StudentProgress.findOne({
      estudiante_id: estudianteId,
      leccion_id: ejercicio.leccion_id,
    });

    if (progreso) {
      // Calcular puntos totales de la lección
      const ejerciciosLeccion = await Exercise.countDocuments({
        leccion_id: ejercicio.leccion_id,
        activo: true,
      });
      const puntosTotales = await Exercise.aggregate([
        { $match: { leccion_id: ejercicio.leccion_id, activo: true } },
        { $group: { _id: null, total: { $sum: '$puntos' } } },
      ]);
      progreso.puntos_totales = puntosTotales[0]?.total || 0;

      // Con reintentos los contadores no deben superar los máximos del esquema
      progreso.ejercicios_respondidos = Math.min(
        progreso.ejercicios_respondidos + 1,
        ejerciciosLeccion
      );
      if (esCorrecta) {
        progreso.ejercicios_correctos = Math.min(
          progreso.ejercicios_correctos + 1,
          ejerciciosLeccion
        );
      }
      progreso.puntos_obtenidos = Math.min(
        progreso.puntos_obtenidos + puntosGanados,
        progreso.puntos_totales
      );
      progreso.porcentaje_completado = Math.min(
        100,
        calcularPorcentaje(progreso.ejercicios_respondidos, ejerciciosLeccion)
      );

      // Marcar como completado si respondió todos los ejercicios
      if (progreso.ejercicios_respondidos >= ejerciciosLeccion) {
        progreso.estado = constants.PROGRESS_STATUS.COMPLETED;
        progreso.fecha_completado = new Date();
      }

      await progreso.save();
    }

    // Nota: los puntos totales del usuario se otorgan al completar la
    // lección/nivel (progressController), no por respuesta individual —
    // responder repetidamente el mismo ejercicio no acumula puntos

    // La racha diaria se activa con al menos un ejercicio por día
    const usuario = await User.findById(estudianteId);
    let racha = usuario?.racha ?? 0;
    let rachaRecuperable = 0;
    let reanudacionesRestantes = 0;
    if (usuario) {
      if (registrarActividad(usuario)) await usuario.save();
      racha = usuario.racha;
      rachaRecuperable = usuario.racha_recuperable || 0;
      reanudacionesRestantes = usuario.reanudacionesRestantes();
    }

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.EXERCISE_ANSWERED,
      usuario_id: estudianteId,
      descripcion: `Ejercicio respondido: ${ejercicio.pregunta.substring(0, 50)}`,
      entidad_tipo: 'exercise',
      entidad_id: ejercicio._id,
      detalles: { esCorrecta, puntosGanados },
    });

    return respuestaExito(
      res,
      {
        historial,
        esCorrecta,
        puntosGanados,
        explicacion: ejercicio.explicacion,
        respuesta_correcta: ejercicio.respuesta_correcta,
        progreso,
        racha,
        racha_recuperable: rachaRecuperable,
        reanudaciones_restantes: reanudacionesRestantes,
      },
      esCorrecta ? 'Respuesta correcta' : 'Respuesta incorrecta'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener respuestas del estudiante para un ejercicio
exports.obtenerRespuestasEstudiante = async (req, res, next) => {
  try {
    const { id } = req.params;
    const estudianteId = req.usuarioId;

    const respuestas = await ExerciseHistory.find({
      estudiante_id: estudianteId,
      ejercicio_id: id,
    }).sort({ createdAt: -1 });

    return respuestaExito(
      res,
      respuestas,
      'Respuestas obtenidas exitosamente'
    );
  } catch (error) {
    next(error);
  }
};
