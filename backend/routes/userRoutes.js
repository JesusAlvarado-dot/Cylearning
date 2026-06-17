const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middlewares/authMiddleware');
const { requiereAdmin } = require('../middlewares/roleMiddleware');

// Obtener todos los usuarios (admin)
router.get(
  '/',
  authMiddleware,
  requiereAdmin,
  userController.obtenerTodosLosUsuarios
);

// Obtener usuario por ID (admin)
router.get(
  '/:id',
  authMiddleware,
  requiereAdmin,
  userController.obtenerUsuarioPorId
);

// Actualizar usuario (propietario o admin)
router.put(
  '/:id',
  authMiddleware,
  userController.actualizarUsuario
);

// Eliminar usuario (admin)
router.delete(
  '/:id',
  authMiddleware,
  requiereAdmin,
  userController.eliminarUsuario
);

// Obtener perfil del estudiante (estudiante)
router.get(
  '/perfil/estudiante',
  authMiddleware,
  userController.obtenerPerfilEstudiante
);

// Cambiar contraseña
router.post(
  '/cambiar-contrasena',
  authMiddleware,
  userController.cambiarContrasena
);

module.exports = router;
