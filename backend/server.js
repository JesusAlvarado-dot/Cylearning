const app = require('./app');
const { connectDB } = require('./config/database');
const environment = require('./config/environment');

const PORT = environment.server.port;
const NODE_ENV = environment.server.nodeEnv;

// Ocultar credenciales de la URI al mostrarla en consola
const dbHost = environment.mongodb.uri.replace(/\/\/[^@]+@/, '//***:***@');

// Conectar a la base de datos
connectDB();

// Iniciar servidor
const server = app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║              🎓 APP ESCUELA - BACKEND INICIADO             ║
║                                                            ║
║  Servidor corriendo en: http://localhost:${PORT}         ║
║  Entorno: ${NODE_ENV}                                      ║
║  Base de datos: ${dbHost}                ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
  `);
});

// Manejo de errores no capturados
process.on('unhandledRejection', (err) => {
  console.error('Error no capturado:', err);
  server.close(() => process.exit(1));
});

process.on('SIGINT', () => {
  console.log('\nServidor detenido');
  server.close(() => process.exit(0));
});

module.exports = server;
