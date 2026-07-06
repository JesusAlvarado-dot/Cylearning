const { body, validationResult } = require('express-validator');
const constants = require('../config/constants');

// Validadores personalizados
const validarEmail = body('email')
  .isEmail()
  .withMessage('Email inválido')
  .normalizeEmail();

const validarContrasena = body('contrasena')
  .isLength({ min: 6 })
  .withMessage('La contraseña debe tener al menos 6 caracteres')
  .matches(/[a-zA-Z]/)
  .withMessage('La contraseña debe contener al menos una letra');

const validarNombre = body('nombre')
  .trim()
  .isLength({ min: 3, max: 50 })
  .withMessage('El nombre debe tener entre 3 y 50 caracteres');

const validarRol = body('rol')
  .isIn(Object.values(constants.ROLES))
  .withMessage(`El rol debe ser uno de: ${Object.values(constants.ROLES).join(', ')}`);

const validarTipoEjercicio = body('tipo')
  .isIn(Object.values(constants.EXERCISE_TYPES))
  .withMessage(
    `El tipo debe ser uno de: ${Object.values(constants.EXERCISE_TYPES).join(', ')}`
  );

const validarPuntos = body('puntos')
  .isInt({ min: 0, max: 100 })
  .withMessage('Los puntos deben ser un número entre 0 y 100');

// Variantes opcionales para creación/actualización parcial
const validarPuntosOpcional = body('puntos')
  .optional()
  .isInt({ min: 0, max: 100 })
  .withMessage('Los puntos deben ser un número entre 0 y 100');

const validarTipoEjercicioOpcional = body('tipo')
  .optional()
  .isIn(Object.values(constants.EXERCISE_TYPES))
  .withMessage(
    `El tipo debe ser uno de: ${Object.values(constants.EXERCISE_TYPES).join(', ')}`
  );

// Middleware para verificar resultados de validación
const verificarValidacion = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      mensaje: 'Error de validación',
      errores: errors.array().map((error) => ({
        campo: error.param,
        mensaje: error.msg,
      })),
    });
  }
  next();
};

module.exports = {
  validarEmail,
  validarContrasena,
  validarNombre,
  validarRol,
  validarTipoEjercicio,
  validarTipoEjercicioOpcional,
  validarPuntos,
  validarPuntosOpcional,
  verificarValidacion,
};
