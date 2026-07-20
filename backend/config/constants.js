module.exports = {
  // Roles
  ROLES: {
    ADMIN: 'admin',           // dueños de la app: acceso total
    ORGANIZER: 'organizador', // gestiona el contenido de SU organización
    STUDENT: 'student',
  },

  // Exercise Types
  EXERCISE_TYPES: {
    SINGLE_CHOICE: 'seleccion_unica',
    FILL_IN: 'completar',
    TRUE_FALSE: 'verdadero_falso',
  },

  // Exercise Status
  EXERCISE_STATUS: {
    ACTIVE: true,
    INACTIVE: false,
  },

  // Progress Status
  PROGRESS_STATUS: {
    NOT_STARTED: 'no_iniciado',
    IN_PROGRESS: 'en_progreso',
    COMPLETED: 'completado',
  },

  // Answer Status
  ANSWER_STATUS: {
    CORRECT: 'correcto',
    INCORRECT: 'incorrecto',
  },

  // Log Types
  LOG_TYPES: {
    LOGIN: 'login',
    LOGOUT: 'logout',
    EXERCISE_CREATED: 'ejercicio_creado',
    EXERCISE_UPDATED: 'ejercicio_actualizado',
    EXERCISE_DELETED: 'ejercicio_eliminado',
    EXERCISE_ANSWERED: 'ejercicio_respondido',
    USER_CREATED: 'usuario_creado',
    USER_DELETED: 'usuario_eliminado',
    LEVEL_CREATED: 'nivel_creado',
    LEVEL_DELETED: 'nivel_eliminado',
    ERROR: 'error',
    CREATED: 'creado',
    UPDATED: 'actualizado',
    DELETED: 'eliminado',
  },

  // Pagination
  PAGINATION: {
    DEFAULT_PAGE: 1,
    DEFAULT_LIMIT: 10,
    MAX_LIMIT: 100,
  },

  // Error Messages
  ERROR_MESSAGES: {
    INVALID_CREDENTIALS: 'Credenciales inválidas',
    USER_NOT_FOUND: 'Usuario no encontrado',
    USER_EXISTS: 'El usuario ya existe',
    UNAUTHORIZED: 'No autorizado',
    FORBIDDEN: 'Acceso denegado',
    INVALID_TOKEN: 'Token inválido o expirado',
    INTERNAL_ERROR: 'Error interno del servidor',
    EXERCISE_NOT_FOUND: 'Ejercicio no encontrado',
    LESSON_NOT_FOUND: 'Lección no encontrada',
    TOPIC_NOT_FOUND: 'Tema no encontrado',
    LEVEL_NOT_FOUND: 'Nivel no encontrado',
  },

  // Success Messages
  SUCCESS_MESSAGES: {
    LOGIN_SUCCESS: 'Inicio de sesión exitoso',
    LOGOUT_SUCCESS: 'Cierre de sesión exitoso',
    USER_CREATED: 'Usuario creado exitosamente',
    EXERCISE_CREATED: 'Ejercicio creado exitosamente',
    EXERCISE_UPDATED: 'Ejercicio actualizado exitosamente',
    EXERCISE_DELETED: 'Ejercicio eliminado exitosamente',
  },

  // Default Points
  DEFAULT_POINTS: 10,

  // Max Attempts
  MAX_EXERCISE_ATTEMPTS: 10,
};
