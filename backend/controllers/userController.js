const User = require('../models/User');
const { respuestaExito, respuestaError, respuestaPaginada, paginar } = require('../utils/helpers');
const constants = require('../config/constants');
const Log = require('../models/Log');
const StudentProgress = require('../models/StudentProgress');

// Obtener todos los usuarios (solo admin)
exports.obtenerTodosLosUsuarios = async (req, res, next) => {
  try {
    const { pagina = 1, limite = 10 } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const usuarios = await User.find()
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 });

    const total = await User.countDocuments();

    const respuesta = respuestaPaginada(usuarios, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Usuarios obtenidos exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener usuario por ID
exports.obtenerUsuarioPorId = async (req, res, next) => {
  try {
    const { id } = req.params;

    const usuario = await User.findById(id);

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

// Actualizar usuario
exports.actualizarUsuario = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nombre, email } = req.body;

    // Validar que sea el propietario o admin
    if (req.usuarioId.toString() !== id && req.rol !== constants.ROLES.ADMIN) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.FORBIDDEN,
        403
      );
    }

    const usuario = await User.findByIdAndUpdate(
      id,
      { nombre, email },
      { new: true, runValidators: true }
    );

    if (!usuario) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.USER_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: 'actualizado',
      usuario_id: req.usuarioId,
      descripcion: `Usuario actualizado: ${usuario.nombre}`,
      entidad_tipo: 'user',
      entidad_id: usuario._id,
    });

    return respuestaExito(
      res,
      usuario.toJSON(),
      'Usuario actualizado exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Eliminar usuario (solo admin)
exports.eliminarUsuario = async (req, res, next) => {
  try {
    const { id } = req.params;

    const usuario = await User.findByIdAndDelete(id);

    if (!usuario) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.USER_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.USER_DELETED,
      usuario_id: req.usuarioId,
      descripcion: `Usuario eliminado: ${usuario.nombre}`,
      entidad_tipo: 'user',
      entidad_id: usuario._id,
    });

    return respuestaExito(
      res,
      {},
      'Usuario eliminado exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener perfil del estudiante con progreso
exports.obtenerPerfilEstudiante = async (req, res, next) => {
  try {
    const usuarioId = req.usuarioId;

    // Obtener usuario
    const usuario = await User.findById(usuarioId);

    if (!usuario) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.USER_NOT_FOUND,
        404
      );
    }

    // Obtener progreso
    const progreso = await StudentProgress.find({ estudiante_id: usuarioId })
      .populate('nivel_id', 'nombre')
      .populate('tema_id', 'nombre')
      .populate('leccion_id', 'nombre')
      .sort({ createdAt: -1 });

    // Calcular estadísticas
    const totalPuntos = progreso.reduce((sum, p) => sum + p.puntos_obtenidos, 0);
    const leccionesCompletadas = progreso.filter(
      (p) => p.estado === constants.PROGRESS_STATUS.COMPLETED
    ).length;

    return respuestaExito(
      res,
      {
        usuario: usuario.toJSON(),
        estadisticas: {
          puntos_totales: usuario.puntos_totales,
          lecciones_completadas: leccionesCompletadas,
          progreso: progreso,
        },
      },
      'Perfil del estudiante obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener estudiantes (admin) con ordenamiento por puntos
exports.obtenerEstudiantesAdmin = async (req, res, next) => {
  try {
    const { pagina = 1, limite = 50, orden = 'desc' } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const usuarios = await User.find({ rol: 'student' })
      .skip(skip)
      .limit(limit)
      .sort({ puntos_totales: orden === 'asc' ? 1 : -1 });

    const total = await User.countDocuments({ rol: 'student' });
    return respuestaExito(res, respuestaPaginada(usuarios, total, pagina, limite), 'Estudiantes obtenidos');
  } catch (error) {
    next(error);
  }
};

// Dar medalla a un estudiante (admin)
exports.darMedalla = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { tipo, descripcion } = req.body;

    if (!['oro', 'plata', 'bronce', 'estrella'].includes(tipo)) {
      return respuestaError(res, 'Tipo de medalla inválido', 400);
    }

    const usuario = await User.findByIdAndUpdate(
      id,
      { $push: { medallas: { tipo, descripcion: descripcion || '', fecha: new Date() } } },
      { new: true }
    );

    if (!usuario) return respuestaError(res, 'Usuario no encontrado', 404);

    await Log.create({
      tipo: 'actualizado',
      usuario_id: req.usuarioId,
      descripcion: `Medalla ${tipo} otorgada a ${usuario.nombre}`,
      entidad_tipo: 'user',
      entidad_id: usuario._id,
    });

    return respuestaExito(res, usuario.toJSON(), 'Medalla otorgada exitosamente');
  } catch (error) {
    next(error);
  }
};

// Cambiar contraseña
exports.cambiarContrasena = async (req, res, next) => {
  try {
    const { contraseniaActual, contrasenioNueva } = req.body;
    const usuarioId = req.usuarioId;

    // Validar que los campos existan
    if (!contraseniaActual || !contrasenioNueva) {
      return respuestaError(
        res,
        'Las contraseñas actual y nueva son requeridas',
        400
      );
    }

    // Obtener usuario con contraseña
    const usuario = await User.findById(usuarioId).select('+contrasena');

    if (!usuario) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.USER_NOT_FOUND,
        404
      );
    }

    // Verificar contraseña actual
    const contrasenaValida = await usuario.compararContrasena(contraseniaActual);

    if (!contrasenaValida) {
      return respuestaError(
        res,
        'La contraseña actual es incorrecta',
        401
      );
    }

    // Actualizar contraseña
    usuario.contrasena = contrasenioNueva;
    await usuario.save();

    return respuestaExito(
      res,
      {},
      'Contraseña cambiada exitosamente'
    );
  } catch (error) {
    next(error);
  }
};
