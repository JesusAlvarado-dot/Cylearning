const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const environment = require('./config/environment');
const routes = require('./routes');
const { errorHandler, ruta404 } = require('./middlewares/errorHandler');

const app = express();

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
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// ============== RUTAS ==============
routes(app);

// ============== MANEJO DE ERRORES ==============

// Ruta 404
app.use(ruta404);

// Manejador de errores global
app.use(errorHandler);

module.exports = app;
