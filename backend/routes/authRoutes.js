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

// Login / registro con Google (recibe idToken ya verificado por Google en el cliente)
router.post(
  '/google',
  authController.loginGoogle
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
