const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const adminRoutes = require('./adminRoutes');
const studentRoutes = require('./studentRoutes');
const exerciseRoutes = require('./exerciseRoutes');
const publicRoutes = require('./publicRoutes');

module.exports = (app) => {
  // Salud/despertador: la app lo llama al arrancar para sacar al servidor
  // del reposo del plan gratuito de Render ANTES de que el usuario intente
  // iniciar sesión (el arranque en frío tarda 30-50s).
  app.get('/api/salud', (req, res) => res.json({ ok: true }));

  // Rutas de autenticación
  app.use('/api/auth', authRoutes);

  // Rutas públicas (solicitudes de organizaciones)
  app.use('/api/public', publicRoutes);

  // Rutas de usuarios
  app.use('/api/users', userRoutes);

  // Rutas de administrador
  app.use('/api/admin', adminRoutes);

  // Rutas de estudiante
  app.use('/api/student', studentRoutes);

  // Rutas de ejercicios públicas
  app.use('/api/exercises', exerciseRoutes);
};
