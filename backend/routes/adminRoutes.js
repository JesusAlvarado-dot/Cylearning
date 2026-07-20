const express = require('express');
const router = express.Router();
const levelController = require('../controllers/levelController');
const topicController = require('../controllers/topicController');
const lessonController = require('../controllers/lessonController');
const exerciseController = require('../controllers/exerciseController');
const progressController = require('../controllers/progressController');
const logController = require('../controllers/logController');
const userController = require('../controllers/userController');
const orgController = require('../controllers/orgController');
const authMiddleware = require('../middlewares/authMiddleware');
const { requiereAdmin, requiereAdminOOrganizador } = require('../middlewares/roleMiddleware');
const {
  validarEmail,
  validarContrasena,
  validarNombre,
  validarTipoEjercicio,
  validarTipoEjercicioOpcional,
  validarPuntosOpcional,
  verificarValidacion,
} = require('../utils/validators');

// Autenticación para todas las rutas. El acceso por rol se decide por
// sección: la gestión de usuarios/organizaciones/logs es SOLO del admin
// (dueños de la app); el contenido educativo también lo administran los
// organizadores, limitados a su organización dentro de cada controlador.
router.use(authMiddleware, requiereAdminOOrganizador);

// ============== USUARIOS (solo admin) ==============
router.get('/usuarios', requiereAdmin, userController.obtenerEstudiantesAdmin);
router.post(
  '/usuarios',
  requiereAdmin,
  validarNombre,
  validarEmail,
  validarContrasena,
  verificarValidacion,
  userController.crearUsuarioAdmin
);
router.put('/usuarios/:id', requiereAdmin, userController.actualizarUsuario);
router.delete('/usuarios/:id', requiereAdmin, userController.eliminarUsuario);
router.post('/usuarios/:id/medalla', requiereAdmin, userController.darMedalla);
router.put('/usuarios/:id/organizacion', requiereAdmin, orgController.asignarUsuarioOrganizacion);

// ============== ORGANIZACIONES (solo admin) ==============
router.get('/organizaciones', requiereAdmin, orgController.obtenerOrganizaciones);
router.post('/organizaciones', requiereAdmin, orgController.crearOrganizacion);
router.put('/organizaciones/:id', requiereAdmin, orgController.actualizarOrganizacion);
router.post('/organizaciones/:id/regenerar-codigo', requiereAdmin, orgController.regenerarCodigo);
router.delete('/organizaciones/:id', requiereAdmin, orgController.eliminarOrganizacion);

// ============== SOLICITUDES DE ORGANIZACIONES (solo admin) ==============
router.get('/solicitudes', requiereAdmin, orgController.obtenerSolicitudes);
router.put('/solicitudes/:id', requiereAdmin, orgController.actualizarSolicitud);
router.delete('/solicitudes/:id', requiereAdmin, orgController.eliminarSolicitud);

// ============== MI ORGANIZACIÓN (organizador) ==============
router.get('/mi-organizacion', orgController.obtenerMiOrganizacion);
router.put('/mi-organizacion', orgController.actualizarMiOrganizacion);

// ============== NIVELES (admin y organizador, con alcance) ==============
router.post('/niveles', levelController.crearNivel);
router.get('/niveles', levelController.obtenerTodosLosNiveles);
// (antes de /niveles/:id para que "reordenar" no se interprete como un id)
router.put('/niveles/reordenar', levelController.reordenarNiveles);
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
router.post(
  '/ejercicios',
  validarTipoEjercicio,
  validarPuntosOpcional,
  verificarValidacion,
  exerciseController.crearEjercicio
);
router.get('/ejercicios', exerciseController.obtenerTodosLosEjercicios);
router.get('/ejercicios/:id', exerciseController.obtenerEjercicioPorId);
router.put(
  '/ejercicios/:id',
  validarTipoEjercicioOpcional,
  validarPuntosOpcional,
  verificarValidacion,
  exerciseController.actualizarEjercicio
);
router.delete('/ejercicios/:id', exerciseController.eliminarEjercicio);

// ============== PROGRESO (solo admin) ==============
router.get('/progreso/nivel/:nivelId', requiereAdmin, progressController.obtenerProgresoNivel);
router.get('/estadisticas/estudiante/:estudianteId', requiereAdmin, progressController.obtenerEstadisticasEstudiante);
router.get('/ranking/estudiantes', requiereAdmin, progressController.obtenerRankingEstudiantes);

// ============== LOGS (solo admin) ==============
router.get('/logs', requiereAdmin, logController.obtenerTodosLosLogs);
router.get('/logs/usuario/:usuarioId', requiereAdmin, logController.obtenerLogsUsuario);
router.get('/logs/entidad/:entidadTipo/:entidadId', requiereAdmin, logController.obtenerLogsEntidad);
router.get('/logs/estadisticas', requiereAdmin, logController.obtenerEstadisticasLogs);
router.post('/logs/limpiar', requiereAdmin, logController.limpiarLogsAntiguos);

module.exports = router;
