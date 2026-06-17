const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middlewares/authMiddleware');
const {
  validarEmail,
  validarContrasena,
  validarNombre,
  verificarValidacion,
} = require('../utils/validators');

// Registro
router.post(
  '/registro',
  validarNombre,
  validarEmail,
  validarContrasena,
  verificarValidacion,
  authController.registro
);

// Login
router.post(
  '/login',
  validarEmail,
  verificarValidacion,
  authController.login
);

// Logout (requiere autenticación)
router.post(
  '/logout',
  authMiddleware,
  authController.logout
);

// Obtener usuario actual (requiere autenticación)
router.get(
  '/me',
  authMiddleware,
  authController.obtenerUsuarioActual
);

module.exports = router;
