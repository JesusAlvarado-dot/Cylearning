require('dotenv').config();

module.exports = {
  // Database
  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/app-escuela',
    testUri: process.env.MONGODB_TEST_URI || 'mongodb://localhost:27017/app-escuela-test',
  },

  // JWT
  jwt: {
    secret: process.env.JWT_SECRET || 'tu_secret_key_muy_seguro_cambiar_en_produccion',
    expiresIn: process.env.JWT_EXPIRE || '7d',
  },

  // Server
  server: {
    port: parseInt(process.env.PORT, 10) || 5000,
    nodeEnv: process.env.NODE_ENV || 'development',
  },

  // CORS
  cors: {
    origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  },

  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },

  // Bcrypt
  bcrypt: {
    rounds: 10,
  },

  // App
  app: {
    name: 'App Escuela',
    version: '1.0.0',
  },
};
