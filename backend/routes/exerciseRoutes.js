const express = require('express');
const router = express.Router();
const exerciseController = require('../controllers/exerciseController');
const authMiddleware = require('../middlewares/authMiddleware');

// Obtener todos los ejercicios (requiere autenticación)
router.get('/', authMiddleware, exerciseController.obtenerTodosLosEjercicios);

// Obtener ejercicio por ID (requiere autenticación)
router.get('/:id', authMiddleware, exerciseController.obtenerEjercicioPorId);

module.exports = router;
