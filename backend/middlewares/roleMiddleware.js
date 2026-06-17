const constants = require('../config/constants');
const { respuestaError } = require('../utils/helpers');

// Middleware para verificar rol
const requiereRol = (rolesPermitidos) => {
  return (req, res, next) => {
    if (!req.usuario) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.UNAUTHORIZED,
        401
      );
    }

    if (!rolesPermitidos.includes(req.usuario.rol)) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.FORBIDDEN,
        403
      );
    }

    next();
  };
};

// Middleware específico para administrador
const requiereAdmin = requiereRol([constants.ROLES.ADMIN]);

// Middleware específico para estudiante
const requiereEstudiante = requiereRol([constants.ROLES.STUDENT]);

module.exports = {
  requiereRol,
  requiereAdmin,
  requiereEstudiante,
};
