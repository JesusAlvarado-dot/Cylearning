const User = require('../models/User');
const { respuestaExito, respuestaError, obtenerIP } = require('../utils/helpers');
const jwtUtils = require('../utils/jwt');
const constants = require('../config/constants');
const Log = require('../models/Log');

// Registro de usuario
exports.registro = async (req, res, next) => {
  try {
    const { nombre, email, contrasena } = req.body;

    // Validar que no exista el usuario
    const usuarioExistente = await User.findOne({ email });
    if (usuarioExistente) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.USER_EXISTS,
        400
      );
    }

    // Crear usuario
    const usuario = new User({
      nombre,
      email,
      contrasena,
      rol: constants.ROLES.STUDENT, // Por defecto estudiante
    });

    await usuario.save();

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.LOGIN,
      usuario_id: usuario._id,
      descripcion: 'Usuario registrado',
      entidad_tipo: 'user',
      entidad_id: usuario._id,
      ip_address: obtenerIP(req),
    });

    // Generar token
    const token = jwtUtils.generarToken(usuario._id, usuario.rol);

    // Respuesta
    return respuestaExito(
      res,
      {
        usuario: usuario.toJSON(),
        token,
      },
      constants.SUCCESS_MESSAGES.LOGIN_SUCCESS,
      201
    );
  } catch (error) {
    next(error);
  }
};

// Inicio de sesión
exports.login = async (req, res, next) => {
  try {
    const { email, contrasena } = req.body;

    // Validar que los campos existan
    if (!email || !contrasena) {
      return respuestaError(
        res,
        'Email y contraseña son requeridos',
        400
      );
    }

    // Buscar usuario
    const usuario = await User.findOne({ email }).select('+contrasena');
    if (!usuario) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.INVALID_CREDENTIALS,
        401
      );
    }

    // Verificar contraseña
    const contrasenaValida = await usuario.compararContrasena(contrasena);
    if (!contrasenaValida) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.INVALID_CREDENTIALS,
        401
      );
    }

    // Actualizar último acceso
    usuario.ultimo_acceso = new Date();
    await usuario.save();

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.LOGIN,
      usuario_id: usuario._id,
      descripcion: 'Usuario inició sesión',
      ip_address: obtenerIP(req),
    });

    // Generar token
    const token = jwtUtils.generarToken(usuario._id, usuario.rol);

    // Respuesta
    return respuestaExito(
      res,
      {
        usuario: usuario.toJSON(),
        token,
      },
      constants.SUCCESS_MESSAGES.LOGIN_SUCCESS
    );
  } catch (error) {
    next(error);
  }
};

// Logout (solo para registrar en logs)
exports.logout = async (req, res, next) => {
  try {
    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.LOGOUT,
      usuario_id: req.usuarioId,
      descripcion: 'Usuario cerró sesión',
      ip_address: obtenerIP(req),
    });

    return respuestaExito(
      res,
      {},
      constants.SUCCESS_MESSAGES.LOGOUT_SUCCESS
    );
  } catch (error) {
    next(error);
  }
};

// Obtener usuario actual
exports.obtenerUsuarioActual = async (req, res, next) => {
  try {
    const usuario = await User.findById(req.usuarioId);

    if (!usuario) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.USER_NOT_FOUND,
        404
      );
    }

    return respuestaExito(
      res,
      usuario.toJSON(),
      'Usuario obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};
