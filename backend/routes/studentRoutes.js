const express = require('express');
const router = express.Router();
const levelController = require('../controllers/levelController');
const lessonController = require('../controllers/lessonController');
const exerciseController = require('../controllers/exerciseController');
const progressController = require('../controllers/progressController');
const userController = require('../controllers/userController');
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middlewares/authMiddleware');

// Middleware de autenticación para todas las rutas
router.use(authMiddleware);

// ============== PERFIL ==============
// Actualizar el propio perfil (nombre y/o contraseña)
router.put('/perfil', userController.actualizarPerfil);

// ============== NIVELES ==============
// Obtener todos los niveles activos
router.get('/niveles', levelController.obtenerTodosLosNiveles);

// Obtener nivel con estructura completa
router.get('/niveles/:id/estructura', levelController.obtenerEstructuraNivel);

// ============== LECCIONES ==============
// Obtener todas las lecciones
router.get('/lecciones', lessonController.obtenerTodasLasLecciones);

// Iniciar lección
router.get('/lecciones/:id/iniciar', lessonController.iniciarLeccion);

// Obtener lección por ID
router.get('/lecciones/:id', lessonController.obtenerLeccionPorId);

// ============== EJERCICIOS ==============
// Obtener ejercicios de una lección
router.get('/ejercicios', exerciseController.obtenerTodosLosEjercicios);

// Obtener ejercicio por ID (sin la respuesta correcta)
router.get('/ejercicios/:id', exerciseController.obtenerEjercicioPorId);

// Responder ejercicio
router.post('/ejercicios/:id/responder', exerciseController.responderEjercicio);

// Obtener respuestas del estudiante para un ejercicio
router.get('/ejercicios/:id/respuestas', exerciseController.obtenerRespuestasEstudiante);

// ============== PROGRESO ==============
// Resumen de lecciones y niveles completados (para locking en Flutter)
router.get('/progreso/resumen', progressController.obtenerResumen);

// Marcar lección como completada (requiere >= 70%)
router.post('/lecciones/:id/completar', progressController.completarLeccion);

// Marcar nivel como completado (requiere >= 70% en prueba final)
router.post('/niveles/:id/completar', progressController.completarNivel);

// Obtener progreso en una lección
router.get('/progreso/leccion/:leccionId', progressController.obtenerProgresoLeccion);

// Obtener progreso general del estudiante
router.get('/progreso', progressController.obtenerProgresoGeneral);

// Ranking público de estudiantes (top 20 por puntos)
router.get('/ranking', progressController.obtenerRankingPublico);

// ============== RACHA ==============
// Reanudar racha perdida por un solo día (máx. 3 por mes)
router.post('/racha/reanudar', progressController.reanudarRachaStudent);

// ============== REPORTES ==============
// Reportar una foto de perfil (visible en el ranking) o un ejercicio
router.post('/reportes', reportController.crearReporte);
// Ver mis propios reportes y la respuesta del admin
router.get('/reportes', reportController.misReportes);

module.exports = router;
