const jwtUtils = require('../utils/jwt');
const User = require('../models/User');
const constants = require('../config/constants');
const { respuestaError } = require('../utils/helpers');

const authMiddleware = async (req, res, next) => {
  try {
    // Obtener token del header
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.INVALID_TOKEN,
        401
      );
    }

    // Verificar token
    const decoded = jwtUtils.verificarToken(token);

    // Obtener usuario de la base de datos
    const usuario = await User.findById(decoded.id);

    if (!usuario || !usuario.activo) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.USER_NOT_FOUND,
        401
      );
    }

    // Añadir usuario al request
    req.usuario = usuario;
    req.usuarioId = usuario._id;
    req.rol = usuario.rol;

    next();
  } catch (error) {
    if (
      error.message === 'Token expirado' ||
      error.message === 'Token inválido'
    ) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.INVALID_TOKEN,
        401
      );
    }

    return respuestaError(
      res,
      constants.ERROR_MESSAGES.UNAUTHORIZED,
      401
    );
  }
};

module.exports = authMiddleware;
