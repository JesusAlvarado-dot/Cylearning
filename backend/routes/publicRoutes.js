const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const orgController = require('../controllers/orgController');

// Formulario público "¿Eres una organización?": rate limit agresivo para
// evitar spam (5 solicitudes por IP cada hora)
const solicitudLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    mensaje: 'Demasiadas solicitudes. Intenta de nuevo en una hora',
  },
});

router.post('/solicitudes-organizacion', solicitudLimiter, orgController.crearSolicitud);

// Validar un código de invitación (para el banner del registro).
// Rate limit moderado para no permitir adivinar códigos por fuerza bruta.
const codigoLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    mensaje: 'Demasiados intentos. Espera unos minutos',
  },
});
router.get('/codigo/:codigo', codigoLimiter, orgController.validarCodigo);

module.exports = router;
