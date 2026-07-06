const constants = require('../config/constants');
const environment = require('../config/environment');
const { respuestaError } = require('../utils/helpers');
const Log = require('../models/Log');

// Middleware manejador de errores global
const errorHandler = async (err, req, res, next) => {
  console.error('Error:', err);

  // Obtener información del error
  const status = err.status || err.statusCode || 500;
  const mensaje = err.message || constants.ERROR_MESSAGES.INTERNAL_ERROR;

  // Registrar error en logs
  try {
    await Log.create({
      tipo: constants.LOG_TYPES.ERROR,
      usuario_id: req.usuarioId || null,
      descripcion: mensaje,
      detalles: {
        stack: err.stack,
        ruta: req.path,
        metodo: req.method,
      },
      ip_address: req.ip || null,
      estado: 'fallido',
      error_message: err.message,
    });
  } catch (logError) {
    console.error('Error al registrar en logs:', logError);
  }

  // Errores de validación de Mongoose
  if (err.name === 'ValidationError') {
    const errores = Object.keys(err.errors).map((campo) => ({
      campo,
      mensaje: err.errors[campo].message,
    }));

    return res.status(400).json({
      success: false,
      mensaje: 'Error de validación',
      errores,
    });
  }

  // Errores de duplicado de Mongoose
  if (err.code === 11000) {
    const campo = Object.keys(err.keyPattern)[0];
    return res.status(400).json({
      success: false,
      mensaje: `El ${campo} ya existe`,
      detalles: { campo },
    });
  }

  // IDs mal formados de Mongoose (evita responder 500 por un ObjectId inválido)
  if (err.name === 'CastError') {
    return respuestaError(res, 'Identificador inválido', 400);
  }

  // En producción no exponer mensajes internos de errores 500
  const esProduccion = environment.server.nodeEnv === 'production';
  const mensajeFinal = status >= 500 && esProduccion
    ? constants.ERROR_MESSAGES.INTERNAL_ERROR
    : mensaje;

  return respuestaError(res, mensajeFinal, status);
};

// Middleware 404 (ruta no encontrada)
const ruta404 = (req, res) => {
  return respuestaError(
    res,
    `Ruta no encontrada: ${req.path}`,
    404
  );
};

module.exports = {
  errorHandler,
  ruta404,
};
