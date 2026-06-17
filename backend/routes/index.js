const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const adminRoutes = require('./adminRoutes');
const studentRoutes = require('./studentRoutes');
const exerciseRoutes = require('./exerciseRoutes');

module.exports = (app) => {
  // Rutas de autenticación
  app.use('/api/auth', authRoutes);

  // Rutas de usuarios
  app.use('/api/users', userRoutes);

  // Rutas de administrador
  app.use('/api/admin', adminRoutes);

  // Rutas de estudiante
  app.use('/api/student', studentRoutes);

  // Rutas de ejercicios públicas
  app.use('/api/exercises', exerciseRoutes);
};
