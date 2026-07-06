const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const environment = require('./config/environment');
const routes = require('./routes');
const { errorHandler, ruta404 } = require('./middlewares/errorHandler');

const app = express();

// Detrás de un proxy (nginx, Render, Railway...) configurar TRUST_PROXY=true
// en el .env para que el rate limiting cuente las IPs reales de los clientes
if (process.env.TRUST_PROXY === 'true') {
  app.set('trust proxy', 1);
}

// ============== MIDDLEWARES GLOBALES ==============

// Seguridad
app.use(helmet());

// CORS — acepta cualquier origin en desarrollo (Flutter web usa puerto dinámico)
const corsOrigin = environment.cors.origin;
app.use(
  cors({
    origin: corsOrigin === '*' ? true : corsOrigin,
    credentials: true,
  })
);

// Logging HTTP
if (environment.server.nodeEnv === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Body parsers
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ limit: '1mb', extended: true }));

// Rate limiting — límite estricto para login/registro (fuerza bruta)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    mensaje: 'Demasiados intentos. Intenta de nuevo en 15 minutos',
  },
});

// Límite general para el resto del API
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    mensaje: 'Demasiadas peticiones. Intenta de nuevo más tarde',
  },
});

app.use('/api/auth/login', authLimiter);
app.use('/api/auth/registro', authLimiter);
app.use('/api', apiLimiter);

// ============== RUTAS ==============
routes(app);

// ============== MANEJO DE ERRORES ==============

// Ruta 404
app.use(ruta404);

// Manejador de errores global
app.use(errorHandler);

module.exports = app;
