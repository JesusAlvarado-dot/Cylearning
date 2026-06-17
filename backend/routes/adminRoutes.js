const express = require('express');
const router = express.Router();
const levelController = require('../controllers/levelController');
const topicController = require('../controllers/topicController');
const lessonController = require('../controllers/lessonController');
const exerciseController = require('../controllers/exerciseController');
const progressController = require('../controllers/progressController');
const logController = require('../controllers/logController');
const userController = require('../controllers/userController');
const authMiddleware = require('../middlewares/authMiddleware');
const { requiereAdmin } = require('../middlewares/roleMiddleware');

// Middleware de autenticación y admin para todas las rutas
router.use(authMiddleware, requiereAdmin);

// ============== USUARIOS ==============
router.get('/usuarios', userController.obtenerEstudiantesAdmin);
router.post('/usuarios/:id/medalla', userController.darMedalla);

// ============== NIVELES ==============
router.post('/niveles', levelController.crearNivel);
router.get('/niveles', levelController.obtenerTodosLosNiveles);
router.get('/niveles/:id', levelController.obtenerNivelPorId);
router.put('/niveles/:id', levelController.actualizarNivel);
router.delete('/niveles/:id', levelController.eliminarNivel);
router.get('/niveles/:id/estructura', levelController.obtenerEstructuraNivel);

// ============== TEMAS ==============
router.post('/temas', topicController.crearTema);
router.get('/temas', topicController.obtenerTodoLosTemas);
router.get('/temas/:id', topicController.obtenerTemaPorId);
router.put('/temas/:id', topicController.actualizarTema);
router.delete('/temas/:id', topicController.eliminarTema);

// ============== LECCIONES ==============
router.post('/lecciones', lessonController.crearLeccion);
router.get('/lecciones', lessonController.obtenerTodasLasLecciones);
router.get('/lecciones/:id', lessonController.obtenerLeccionPorId);
router.put('/lecciones/:id', lessonController.actualizarLeccion);
router.delete('/lecciones/:id', lessonController.eliminarLeccion);

// ============== EJERCICIOS ==============
router.post('/ejercicios', exerciseController.crearEjercicio);
router.get('/ejercicios', exerciseController.obtenerTodosLosEjercicios);
router.get('/ejercicios/:id', exerciseController.obtenerEjercicioPorId);
router.put('/ejercicios/:id', exerciseController.actualizarEjercicio);
router.delete('/ejercicios/:id', exerciseController.eliminarEjercicio);

// ============== PROGRESO ==============
router.get('/progreso/nivel/:nivelId', progressController.obtenerProgresoNivel);
router.get('/estadisticas/estudiante/:estudianteId', progressController.obtenerEstadisticasEstudiante);
router.get('/ranking/estudiantes', progressController.obtenerRankingEstudiantes);

// ============== LOGS ==============
router.get('/logs', logController.obtenerTodosLosLogs);
router.get('/logs/usuario/:usuarioId', logController.obtenerLogsUsuario);
router.get('/logs/entidad/:entidadTipo/:entidadId', logController.obtenerLogsEntidad);
router.get('/logs/estadisticas', logController.obtenerEstadisticasLogs);
router.post('/logs/limpiar', logController.limpiarLogsAntiguos);

module.exports = router;
