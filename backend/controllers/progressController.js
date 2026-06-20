const StudentProgress = require('../models/StudentProgress');
const ExerciseHistory = require('../models/ExerciseHistory');
const Level = require('../models/Level');
const Progreso = require('../models/Progreso');
const { respuestaExito, respuestaError, respuestaPaginada, paginar } = require('../utils/helpers');
const constants = require('../config/constants');

// GET /api/student/progreso/resumen → {lecciones_completadas:[], niveles_completados:[]}
exports.obtenerResumen = async (req, res, next) => {
  try {
    const estudianteId = req.usuarioId;
    let progreso = await Progreso.findOne({ estudiante_id: estudianteId });
    if (!progreso) {
      progreso = await Progreso.create({
        estudiante_id: estudianteId,
        lecciones_completadas: [],
        niveles_completados: [],
      });
    }
    return respuestaExito(res, {
      lecciones_completadas: progreso.lecciones_completadas.map(id => id.toString()),
      niveles_completados:   progreso.niveles_completados.map(id => id.toString()),
    }, 'Resumen obtenido');
  } catch (error) {
    next(error);
  }
};

// POST /api/student/lecciones/:id/completar  body: { porcentaje }
exports.completarLeccion = async (req, res, next) => {
  try {
    const estudianteId = req.usuarioId;
    const leccionId    = req.params.id;
    const porcentaje   = Number(req.body.porcentaje) || 0;

    if (porcentaje < 70) {
      return respuestaExito(res, { desbloqueado: false }, 'Necesitas al menos 70% para desbloquear el siguiente tema');
    }

    let progreso = await Progreso.findOne({ estudiante_id: estudianteId });
    if (!progreso) {
      progreso = await Progreso.create({ estudiante_id: estudianteId, lecciones_completadas: [], niveles_completados: [] });
    }

    if (!progreso.lecciones_completadas.some(id => id.toString() === leccionId)) {
      progreso.lecciones_completadas.push(leccionId);
      await progreso.save();
    }

    return respuestaExito(res, { desbloqueado: true }, 'Lección completada');
  } catch (error) {
    next(error);
  }
};

// POST /api/student/niveles/:id/completar  body: { porcentaje }
exports.completarNivel = async (req, res, next) => {
  try {
    const estudianteId = req.usuarioId;
    const nivelId      = req.params.id;
    const porcentaje   = Number(req.body.porcentaje) || 0;

    if (porcentaje < 70) {
      return respuestaExito(res, { desbloqueado: false }, 'Necesitas al menos 70% para desbloquear el siguiente nivel');
    }

    let progreso = await Progreso.findOne({ estudiante_id: estudianteId });
    if (!progreso) {
      progreso = await Progreso.create({ estudiante_id: estudianteId, lecciones_completadas: [], niveles_completados: [] });
    }

    if (!progreso.niveles_completados.some(id => id.toString() === nivelId)) {
      progreso.niveles_completados.push(nivelId);
      await progreso.save();
    }

    return respuestaExito(res, { desbloqueado: true }, 'Nivel completado');
  } catch (error) {
    next(error);
  }
};

// Obtener progreso del estudiante en una lección
exports.obtenerProgresoLeccion = async (req, res, next) => {
  try {
    const { leccionId } = req.params;
    const estudianteId = req.usuarioId;

    const progreso = await StudentProgress.findOne({
      estudiante_id: estudianteId,
      leccion_id: leccionId,
    })
      .populate('leccion_id', 'nombre')
      .populate('tema_id', 'nombre')
      .populate('nivel_id', 'nombre');

    if (!progreso) {
      return respuestaError(
        res,
        'No hay progreso registrado para esta lección',
        404
      );
    }

    // Obtener historial de respuestas
    const historial = await ExerciseHistory.find({
      estudiante_id: estudianteId,
      leccion_id: leccionId,
    });

    return respuestaExito(
      res,
      {
        progreso,
        historial,
      },
      'Progreso obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener progreso general del estudiante
exports.obtenerProgresoGeneral = async (req, res, next) => {
  try {
    const estudianteId = req.usuarioId;
    const { pagina = 1, limite = 10, nivel_id } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const filtro = { estudiante_id: estudianteId };
    if (nivel_id) filtro.nivel_id = nivel_id;

    const progreso = await StudentProgress.find(filtro)
      .skip(skip)
      .limit(limit)
      .populate('nivel_id', 'nombre numero')
      .populate('tema_id', 'nombre')
      .populate('leccion_id', 'nombre')
      .sort({ createdAt: -1 });

    const total = await StudentProgress.countDocuments(filtro);

    // Calcular estadísticas generales
    const todosProgresos = await StudentProgress.find({ estudiante_id: estudianteId });
    const totalPuntos = todosProgresos.reduce((sum, p) => sum + p.puntos_obtenidos, 0);
    const leccionesCompletadas = todosProgresos.filter(
      (p) => p.estado === constants.PROGRESS_STATUS.COMPLETED
    ).length;
    const porcentajePromedio = todosProgresos.length > 0
      ? Math.round(
          todosProgresos.reduce((sum, p) => sum + p.porcentaje_completado, 0) /
            todosProgresos.length
        )
      : 0;

    const respuesta = respuestaPaginada(progreso, total, pagina, limite);

    return respuestaExito(
      res,
      {
        ...respuesta,
        estadisticas: {
          total_puntos: totalPuntos,
          lecciones_completadas: leccionesCompletadas,
          lecciones_en_progreso: todosProgresos.filter(
            (p) => p.estado === constants.PROGRESS_STATUS.IN_PROGRESS
          ).length,
          porcentaje_promedio: porcentajePromedio,
        },
      },
      'Progreso general obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener progreso por nivel (admin)
exports.obtenerProgresoNivel = async (req, res, next) => {
  try {
    const { nivelId } = req.params;
    const { pagina = 1, limite = 10 } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    // Validar que el nivel existe
    const nivel = await Level.findById(nivelId);
    if (!nivel) {
      return respuestaError(res, constants.ERROR_MESSAGES.LEVEL_NOT_FOUND, 404);
    }

    const progreso = await StudentProgress.find({ nivel_id: nivelId })
      .skip(skip)
      .limit(limit)
      .populate('estudiante_id', 'nombre email puntos_totales')
      .populate('leccion_id', 'nombre')
      .sort({ createdAt: -1 });

    const total = await StudentProgress.countDocuments({ nivel_id: nivelId });

    const respuesta = respuestaPaginada(progreso, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Progreso del nivel obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener estadísticas de un estudiante (admin)
exports.obtenerEstadisticasEstudiante = async (req, res, next) => {
  try {
    const { estudianteId } = req.params;

    // Obtener todos los progresos del estudiante
    const progresos = await StudentProgress.find({
      estudiante_id: estudianteId,
    }).populate('nivel_id', 'nombre numero');

    const historial = await ExerciseHistory.find({
      estudiante_id: estudianteId,
    });

    // Calcular estadísticas
    const totalPuntos = progresos.reduce((sum, p) => sum + p.puntos_obtenidos, 0);
    const leccionesCompletadas = progresos.filter(
      (p) => p.estado === constants.PROGRESS_STATUS.COMPLETED
    ).length;
    const ejerciciosCorrectos = historial.filter(
      (h) => h.estado === constants.ANSWER_STATUS.CORRECT
    ).length;
    const ejerciciosIncorrectos = historial.filter(
      (h) => h.estado === constants.ANSWER_STATUS.INCORRECT
    ).length;
    const porcentajeAcierto =
      historial.length > 0
        ? Math.round((ejerciciosCorrectos / historial.length) * 100)
        : 0;

    // Progreso por nivel
    const progresosPorNivel = {};
    for (let progreso of progresos) {
      const nivelNombre = progreso.nivel_id.nombre;
      if (!progresosPorNivel[nivelNombre]) {
        progresosPorNivel[nivelNombre] = {
          nivel_id: progreso.nivel_id._id,
          leccionesCompletadas: 0,
          totalLecciones: 0,
          puntos: 0,
        };
      }
      progresosPorNivel[nivelNombre].totalLecciones += 1;
      if (progreso.estado === constants.PROGRESS_STATUS.COMPLETED) {
        progresosPorNivel[nivelNombre].leccionesCompletadas += 1;
      }
      progresosPorNivel[nivelNombre].puntos += progreso.puntos_obtenidos;
    }

    return respuestaExito(
      res,
      {
        estadisticas: {
          total_puntos: totalPuntos,
          lecciones_completadas: leccionesCompletadas,
          ejercicios_correctos: ejerciciosCorrectos,
          ejercicios_incorrectos: ejerciciosIncorrectos,
          porcentaje_acierto: porcentajeAcierto,
          total_ejercicios: historial.length,
        },
        progreso_por_nivel: progresosPorNivel,
        progresos,
      },
      'Estadísticas obtenidas exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener ranking de estudiantes (admin)
exports.obtenerRankingEstudiantes = async (req, res, next) => {
  try {
    const { pagina = 1, limite = 10, nivel_id } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    // Obtener todos los progresos agrupados por estudiante
    const pipeline = [
      {
        $group: {
          _id: '$estudiante_id',
          totalPuntos: { $sum: '$puntos_obtenidos' },
          leccionesCompletadas: {
            $sum: {
              $cond: [
                { $eq: ['$estado', constants.PROGRESS_STATUS.COMPLETED] },
                1,
                0,
              ],
            },
          },
          totalLecciones: { $sum: 1 },
        },
      },
      { $sort: { totalPuntos: -1 } },
      { $skip: skip },
      { $limit: limit },
    ];

    // Si se filtra por nivel, agregar match
    if (nivel_id) {
      pipeline.unshift({ $match: { nivel_id: require('mongoose').Types.ObjectId(nivel_id) } });
    }

    const ranking = await StudentProgress.aggregate(pipeline);

    // Obtener información de los estudiantes
    const rankingConEstudiantes = [];
    for (let item of ranking) {
      const estudiante = await require('../models/User').findById(item._id).select('nombre email');
      if (estudiante) {
        rankingConEstudiantes.push({
          estudiante,
          totalPuntos: item.totalPuntos,
          leccionesCompletadas: item.leccionesCompletadas,
          totalLecciones: item.totalLecciones,
        });
      }
    }

    const total = await StudentProgress.distinct('estudiante_id');

    const respuesta = respuestaPaginada(rankingConEstudiantes, total.length, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Ranking obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};
