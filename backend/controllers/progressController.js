const mongoose = require('mongoose');
const StudentProgress = require('../models/StudentProgress');
const Lesson = require('../models/Lesson');
const Topic = require('../models/Topic');
const Exercise = require('../models/Exercise');
const ExerciseHistory = require('../models/ExerciseHistory');
const Level = require('../models/Level');
const Progreso = require('../models/Progreso');
const User = require('../models/User');
const { respuestaExito, respuestaError, respuestaPaginada, paginar } = require('../utils/helpers');
const { registrarActividad, reanudarRacha } = require('../utils/streak');
const constants = require('../config/constants');

// ─── Helpers privados ────────────────────────────────────────────────────────

// Calcular el porcentaje del estudiante a partir de la última respuesta
// registrada para cada ejercicio (calificada por el servidor). Los ejercicios
// sin responder cuentan como incorrectos.
async function _porcentajeServidor(estudianteId, ejercicioIds) {
  const total = ejercicioIds.length;
  if (total === 0) return 0;

  const ultimas = await ExerciseHistory.aggregate([
    {
      $match: {
        estudiante_id: new mongoose.Types.ObjectId(estudianteId),
        ejercicio_id: { $in: ejercicioIds },
      },
    },
    { $sort: { createdAt: 1 } },
    { $group: { _id: '$ejercicio_id', estado: { $last: '$estado' } } },
  ]);

  const correctas = ultimas.filter(
    (u) => u.estado === constants.ANSWER_STATUS.CORRECT
  ).length;

  return Math.round((correctas / total) * 100);
}

function _medallaRacha(racha) {
  if (racha === 3)  return { tipo: 'estrella', descripcion: '¡3 días de racha seguidos! 🔥' };
  if (racha === 7)  return { tipo: 'estrella', descripcion: '¡Una semana aprendiendo! 🌟' };
  if (racha === 30) return { tipo: 'oro',      descripcion: '¡30 días de racha! ¡Increíble! 🏆' };
  return null;
}

// POST /api/student/racha/reanudar — recuperar la racha perdida por un día
// (máximo 3 veces al mes, solo si se perdió exactamente UN día)
exports.reanudarRachaStudent = async (req, res, next) => {
  try {
    const usuario = await User.findById(req.usuarioId);
    if (!usuario) {
      return respuestaError(res, constants.ERROR_MESSAGES.USER_NOT_FOUND, 404);
    }

    const resultado = reanudarRacha(usuario);
    if (!resultado.ok) {
      return respuestaError(res, resultado.mensaje, 400);
    }

    await usuario.save();

    return respuestaExito(res, {
      racha: usuario.racha,
      reanudaciones_restantes: usuario.reanudacionesRestantes(),
    }, `¡Racha reanudada! Sigues con ${usuario.racha} días 🔥`);
  } catch (error) {
    next(error);
  }
};

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

    const leccion = await Lesson.findById(leccionId);
    if (!leccion) {
      return respuestaError(res, constants.ERROR_MESSAGES.LESSON_NOT_FOUND, 404);
    }

    // El porcentaje se calcula en el servidor a partir de las respuestas
    // calificadas (no se confía en el valor enviado por el cliente)
    const ejercicios = await Exercise.find({ leccion_id: leccionId, activo: true }).select('_id');
    if (ejercicios.length === 0) {
      return respuestaError(res, 'La lección no tiene ejercicios activos', 400);
    }
    const porcentaje = await _porcentajeServidor(estudianteId, ejercicios.map((e) => e._id));

    if (porcentaje < 70) {
      return respuestaExito(res, { desbloqueado: false, porcentaje }, 'Necesitas al menos 70% para desbloquear el siguiente tema');
    }

    const usuario = await User.findById(estudianteId);
    const rachaAntes = usuario.racha || 0;
    registrarActividad(usuario);

    let progreso = await Progreso.findOne({ estudiante_id: estudianteId });
    if (!progreso) {
      progreso = await Progreso.create({ estudiante_id: estudianteId, lecciones_completadas: [], niveles_completados: [] });
    }

    let puntos_ganados = 0;
    let medalla_racha = null;

    if (!progreso.lecciones_completadas.some(id => id.toString() === leccionId)) {
      puntos_ganados = porcentaje; // 70-100 pts por lección
      usuario.puntos_totales = (usuario.puntos_totales || 0) + puntos_ganados;
      progreso.lecciones_completadas.push(leccionId);
      await progreso.save();

      // Medalla por racha si cambió
      if (usuario.racha !== rachaAntes) {
        medalla_racha = _medallaRacha(usuario.racha);
        if (medalla_racha) usuario.medallas.push(medalla_racha);
      }
    }

    await usuario.save();

    return respuestaExito(res, {
      desbloqueado: true,
      porcentaje,
      puntos_ganados,
      racha: usuario.racha,
      medalla: medalla_racha,
    }, 'Lección completada');
  } catch (error) {
    next(error);
  }
};

// POST /api/student/niveles/:id/completar  body: { porcentaje }
exports.completarNivel = async (req, res, next) => {
  try {
    const estudianteId = req.usuarioId;
    const nivelId      = req.params.id;

    const nivel = await Level.findById(nivelId);
    if (!nivel) {
      return respuestaError(res, constants.ERROR_MESSAGES.LEVEL_NOT_FOUND, 404);
    }

    // El porcentaje se calcula en el servidor con todos los ejercicios
    // activos del nivel (la prueba final los recorre todos)
    const temas = await Topic.find({ nivel_id: nivelId }).select('_id');
    const lecciones = await Lesson.find({ tema_id: { $in: temas.map((t) => t._id) } }).select('_id');
    const ejercicios = await Exercise.find({
      leccion_id: { $in: lecciones.map((l) => l._id) },
      activo: true,
    }).select('_id');
    if (ejercicios.length === 0) {
      return respuestaError(res, 'El nivel no tiene ejercicios activos', 400);
    }
    const porcentaje = await _porcentajeServidor(estudianteId, ejercicios.map((e) => e._id));

    if (porcentaje < 70) {
      return respuestaExito(res, { desbloqueado: false, porcentaje }, 'Necesitas al menos 70% para desbloquear el siguiente nivel');
    }

    const usuario = await User.findById(estudianteId);
    const rachaAntes = usuario.racha || 0;
    registrarActividad(usuario);

    let progreso = await Progreso.findOne({ estudiante_id: estudianteId });
    if (!progreso) {
      progreso = await Progreso.create({ estudiante_id: estudianteId, lecciones_completadas: [], niveles_completados: [] });
    }

    let puntos_ganados = 0;
    let medalla = null;

    if (!progreso.niveles_completados.some(id => id.toString() === nivelId)) {
      puntos_ganados = Math.round(porcentaje * 1.5); // 105-150 pts por prueba final
      usuario.puntos_totales = (usuario.puntos_totales || 0) + puntos_ganados;

      // Medalla según puntaje
      const tipoMedalla = porcentaje === 100 ? 'oro' : porcentaje >= 85 ? 'plata' : 'bronce';
      const descMedalla  = porcentaje === 100
        ? '¡Perfecto! 100% en la prueba final 🥇'
        : porcentaje >= 85
          ? `¡Excelente! ${porcentaje}% en la prueba final 🥈`
          : `Nivel superado con ${porcentaje}% 🥉`;
      usuario.medallas.push({ tipo: tipoMedalla, descripcion: descMedalla });
      medalla = { tipo: tipoMedalla, descripcion: descMedalla };

      progreso.niveles_completados.push(nivelId);
      await progreso.save();
    }

    // Medalla de racha si aplica
    if (usuario.racha !== rachaAntes) {
      const mRacha = _medallaRacha(usuario.racha);
      if (mRacha) {
        usuario.medallas.push(mRacha);
        if (!medalla) medalla = mRacha;
      }
    }

    await usuario.save();

    return respuestaExito(res, {
      desbloqueado: true,
      porcentaje,
      puntos_ganados,
      racha: usuario.racha,
      medalla,
    }, 'Nivel completado');
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

// GET /api/student/ranking — top 20 estudiantes por puntos (público para estudiantes)
// alcance=global (default) → top 20 de toda la app
// alcance=organizacion    → top 20 SOLO de la organización del usuario
//                           (el "ranking de clase")
exports.obtenerRankingPublico = async (req, res, next) => {
  try {
    const filtro = { rol: 'student', activo: true };

    if (req.query.alcance === 'organizacion') {
      if (!req.usuario.organizacion_id) {
        return respuestaError(res, 'No perteneces a ninguna organización', 400);
      }
      filtro.organizacion_id = req.usuario.organizacion_id;
    }

    const top = await User.find(filtro)
      .select('nombre puntos_totales medallas racha foto')
      .sort({ puntos_totales: -1 })
      .limit(20);
    return respuestaExito(res, top, 'Ranking obtenido');
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
      pipeline.unshift({ $match: { nivel_id: new mongoose.Types.ObjectId(nivel_id) } });
    }

    const ranking = await StudentProgress.aggregate(pipeline);

    // Obtener información de los estudiantes
    const rankingConEstudiantes = [];
    for (let item of ranking) {
      const estudiante = await User.findById(item._id).select('nombre email');
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
