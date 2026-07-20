require('dotenv').config();

// En producción el JWT_SECRET es obligatorio; en desarrollo se avisa si falta
if (!process.env.JWT_SECRET) {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('JWT_SECRET es obligatorio en producción. Configúralo en el archivo .env');
  }
  console.warn('⚠️  JWT_SECRET no configurado: usando valor por defecto SOLO para desarrollo');
}

module.exports = {
  // Database
  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/cylearn',
    testUri: process.env.MONGODB_TEST_URI || 'mongodb://localhost:27017/cylearn_test',
  },

  // JWT
  jwt: {
    secret: process.env.JWT_SECRET || 'secret_solo_para_desarrollo_local',
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
    name: 'CyLearn',
    version: '1.0.0',
  },
};
