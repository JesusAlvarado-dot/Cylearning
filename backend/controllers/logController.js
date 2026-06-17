const Log = require('../models/Log');
const { respuestaExito, respuestaError, respuestaPaginada, paginar } = require('../utils/helpers');

// Obtener todos los logs (solo admin)
exports.obtenerTodosLosLogs = async (req, res, next) => {
  try {
    const { pagina = 1, limite = 10, tipo, usuario_id, estado } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const filtro = {};
    if (tipo) filtro.tipo = tipo;
    if (usuario_id) filtro.usuario_id = usuario_id;
    if (estado) filtro.estado = estado;

    const logs = await Log.find(filtro)
      .skip(skip)
      .limit(limit)
      .populate('usuario_id', 'nombre email')
      .sort({ createdAt: -1 });

    const total = await Log.countDocuments(filtro);

    const respuesta = respuestaPaginada(logs, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Logs obtenidos exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener logs de un usuario específico (admin o el propio usuario)
exports.obtenerLogsUsuario = async (req, res, next) => {
  try {
    const { usuarioId } = req.params;
    const { pagina = 1, limite = 10 } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    // Validar permisos
    if (req.usuarioId.toString() !== usuarioId && req.rol !== 'admin') {
      return respuestaError(res, 'No tienes permisos para ver estos logs', 403);
    }

    const logs = await Log.find({ usuario_id: usuarioId })
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 });

    const total = await Log.countDocuments({ usuario_id: usuarioId });

    const respuesta = respuestaPaginada(logs, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Logs del usuario obtenidos exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener logs de una entidad específica (admin)
exports.obtenerLogsEntidad = async (req, res, next) => {
  try {
    const { entidadTipo, entidadId } = req.params;
    const { pagina = 1, limite = 10 } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const logs = await Log.find({
      entidad_tipo: entidadTipo,
      entidad_id: entidadId,
    })
      .skip(skip)
      .limit(limit)
      .populate('usuario_id', 'nombre email')
      .sort({ createdAt: -1 });

    const total = await Log.countDocuments({
      entidad_tipo: entidadTipo,
      entidad_id: entidadId,
    });

    const respuesta = respuestaPaginada(logs, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Logs de la entidad obtenidos exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener estadísticas de logs (admin)
exports.obtenerEstadisticasLogs = async (req, res, next) => {
  try {
    const { desde, hasta } = req.query;

    const filtro = {};
    if (desde || hasta) {
      filtro.createdAt = {};
      if (desde) filtro.createdAt.$gte = new Date(desde);
      if (hasta) filtro.createdAt.$lte = new Date(hasta);
    }

    // Contar por tipo
    const logsporTipo = await Log.aggregate([
      { $match: filtro },
      { $group: { _id: '$tipo', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);

    // Contar por estado
    const logsPorEstado = await Log.aggregate([
      { $match: filtro },
      { $group: { _id: '$estado', count: { $sum: 1 } } },
    ]);

    // Total de logs
    const totalLogs = await Log.countDocuments(filtro);

    // Errores
    const errores = await Log.countDocuments({
      ...filtro,
      tipo: 'error',
    });

    return respuestaExito(
      res,
      {
        total_logs: totalLogs,
        total_errores: errores,
        logs_por_tipo: logsporTipo,
        logs_por_estado: logsPorEstado,
      },
      'Estadísticas de logs obtenidas exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Limpiar logs antiguos (admin)
exports.limpiarLogsAntiguos = async (req, res, next) => {
  try {
    const { dias = 30 } = req.body;

    // Calcular fecha
    const fecha = new Date();
    fecha.setDate(fecha.getDate() - dias);

    // Eliminar logs
    const resultado = await Log.deleteMany({
      createdAt: { $lt: fecha },
    });

    return respuestaExito(
      res,
      {
        logs_eliminados: resultado.deletedCount,
      },
      'Logs antiguos eliminados exitosamente'
    );
  } catch (error) {
    next(error);
  }
};
