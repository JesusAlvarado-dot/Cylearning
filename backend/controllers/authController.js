const User = require('../models/User');
const { respuestaExito, respuestaError, obtenerIP } = require('../utils/helpers');
const jwtUtils = require('../utils/jwt');
const constants = require('../config/constants');
const Log = require('../models/Log');
const { obtenerPerfilGoogle } = require('../utils/googleAuth');

// Busca la organización por código (estudiante o docente) y devuelve
// {organizacionId, rol} listos para asignar a un usuario nuevo.
// Usado tanto por el registro local como por el login/registro con Google.
async function resolverCodigoOrganizacion(codigoOrganizacion) {
  if (!codigoOrganizacion || typeof codigoOrganizacion !== 'string' || !codigoOrganizacion.trim()) {
    return { organizacionId: null, rol: constants.ROLES.STUDENT };
  }
  const Organization = require('../models/Organization');
  const codigo = codigoOrganizacion.trim().toUpperCase();
  const organizacion = await Organization.findOne({
    $or: [{ codigo }, { codigo_docente: codigo }],
    activo: true,
  });
  if (!organizacion) {
    const error = new Error('Código de organización inválido');
    error.esCodigoInvalido = true;
    throw error;
  }
  return {
    organizacionId: organizacion._id,
    rol: organizacion.codigo_docente === codigo ? constants.ROLES.ORGANIZER : constants.ROLES.STUDENT,
  };
}

// Registro de usuario
exports.registro = async (req, res, next) => {
  try {
    const { nombre, email, contrasena, codigo_organizacion } = req.body;

    // Validar que no exista el usuario
    const usuarioExistente = await User.findOne({ email });
    if (usuarioExistente) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.USER_EXISTS,
        400
      );
    }

    // Código de organización (opcional). El código de estudiante une como
    // estudiante; el código docente registra como ORGANIZADOR de la org
    // (así los profesores se invitan entre sí con su propio link).
    let organizacionId, rol;
    try {
      ({ organizacionId, rol } = await resolverCodigoOrganizacion(codigo_organizacion));
    } catch (e) {
      if (e.esCodigoInvalido) return respuestaError(res, e.message, 400);
      throw e;
    }

    // Crear usuario
    const usuario = new User({
      nombre,
      email,
      contrasena,
      rol,
      organizacion_id: organizacionId,
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

    // Validar que los campos existan y sean strings (evita inyección NoSQL)
    if (!email || !contrasena || typeof email !== 'string' || typeof contrasena !== 'string') {
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

    // Cuenta creada solo con Google: no tiene contraseña que comparar.
    if (!usuario.contrasena) {
      return respuestaError(
        res,
        'Esta cuenta usa Google para iniciar sesión. Usa "Continuar con Google".',
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

    // Incluir los datos de la organización (sector define el tema visual)
    const conOrg = await User.findById(usuario._id)
      .populate('organizacion_id', 'nombre sector codigo mostrar_mensajes_mascota foto');

    // Respuesta
    return respuestaExito(
      res,
      {
        usuario: conOrg.toJSON(),
        token,
      },
      constants.SUCCESS_MESSAGES.LOGIN_SUCCESS
    );
  } catch (error) {
    next(error);
  }
};

// Inicio de sesión / registro con Google. Recibe el access token que el
// cliente (Android/Web) obtiene de google_sign_in y lo valida contra el
// endpoint de userinfo de Google. Si el email ya existe como cuenta local,
// la vincula (queda disponible con ambos métodos); si no existe, la crea.
exports.loginGoogle = async (req, res, next) => {
  try {
    const { accessToken, codigo_organizacion } = req.body;
    if (!accessToken || typeof accessToken !== 'string') {
      return respuestaError(res, 'accessToken es requerido', 400);
    }

    let payload;
    try {
      payload = await obtenerPerfilGoogle(accessToken);
    } catch (e) {
      return respuestaError(res, 'Token de Google inválido o expirado', 401);
    }

    const { sub: googleId, email, name, picture } = payload || {};
    if (!email) {
      return respuestaError(res, 'La cuenta de Google no tiene un email asociado', 400);
    }

    let usuario = await User.findOne({ $or: [{ googleId }, { email }] });

    if (usuario) {
      let cambios = false;
      if (!usuario.googleId) {
        usuario.googleId = googleId;
        cambios = true;
      }
      if (!usuario.foto && picture) {
        usuario.foto = picture;
        cambios = true;
      }
      if (cambios) await usuario.save();
    } else {
      let organizacionId, rol;
      try {
        ({ organizacionId, rol } = await resolverCodigoOrganizacion(codigo_organizacion));
      } catch (e) {
        if (e.esCodigoInvalido) return respuestaError(res, e.message, 400);
        throw e;
      }

      usuario = new User({
        nombre: name || email.split('@')[0],
        email,
        googleId,
        foto: picture || '',
        rol,
        organizacion_id: organizacionId,
      });
      await usuario.save();
    }

    usuario.ultimo_acceso = new Date();
    await usuario.save();

    await Log.create({
      tipo: constants.LOG_TYPES.LOGIN,
      usuario_id: usuario._id,
      descripcion: 'Usuario inició sesión con Google',
      ip_address: obtenerIP(req),
    });

    const token = jwtUtils.generarToken(usuario._id, usuario.rol);
    const conOrg = await User.findById(usuario._id)
      .populate('organizacion_id', 'nombre sector codigo mostrar_mensajes_mascota foto');

    return respuestaExito(
      res,
      {
        usuario: conOrg.toJSON(),
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
    const usuario = await User.findById(req.usuarioId)
      .populate('organizacion_id', 'nombre sector codigo mostrar_mensajes_mascota foto');

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
