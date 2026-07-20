const Organization = require('../models/Organization');
const { SECTORES } = require('../models/Organization');
const OrgRequest = require('../models/OrgRequest');
const User = require('../models/User');
const Level = require('../models/Level');
const Log = require('../models/Log');
const { respuestaExito, respuestaError } = require('../utils/helpers');
const constants = require('../config/constants');

// ─── Organizaciones (solo admin) ─────────────────────────────────────────────

// GET /api/admin/organizaciones
exports.obtenerOrganizaciones = async (req, res, next) => {
  try {
    const organizaciones = await Organization.find().sort({ createdAt: -1 }).lean();

    // Conteos de usuarios y niveles por organización para el panel
    const [usuarios, niveles] = await Promise.all([
      User.aggregate([
        { $match: { organizacion_id: { $ne: null } } },
        { $group: { _id: '$organizacion_id', total: { $sum: 1 } } },
      ]),
      Level.aggregate([
        { $match: { organizacion_id: { $ne: null } } },
        { $group: { _id: '$organizacion_id', total: { $sum: 1 } } },
      ]),
    ]);
    const usuariosPorOrg = new Map(usuarios.map((u) => [u._id.toString(), u.total]));
    const nivelesPorOrg = new Map(niveles.map((n) => [n._id.toString(), n.total]));

    for (const org of organizaciones) {
      org.total_usuarios = usuariosPorOrg.get(org._id.toString()) || 0;
      org.total_niveles = nivelesPorOrg.get(org._id.toString()) || 0;
    }

    return respuestaExito(res, organizaciones, 'Organizaciones obtenidas');
  } catch (error) {
    next(error);
  }
};

// POST /api/admin/organizaciones  { nombre, sector, email }
exports.crearOrganizacion = async (req, res, next) => {
  try {
    const { nombre, sector, email } = req.body;

    const organizacion = await Organization.create({ nombre, sector, email });

    await Log.create({
      tipo: constants.LOG_TYPES.CREATED,
      usuario_id: req.usuarioId,
      descripcion: `Organización creada: ${organizacion.nombre} (${organizacion.codigo})`,
      entidad_tipo: 'organization',
      entidad_id: organizacion._id,
    });

    return respuestaExito(res, organizacion, 'Organización creada', 201);
  } catch (error) {
    if (error.code === 11000) {
      return respuestaError(res, 'Ya existe una organización con ese nombre', 400);
    }
    next(error);
  }
};

// PUT /api/admin/organizaciones/:id
exports.actualizarOrganizacion = async (req, res, next) => {
  try {
    const { nombre, sector, email, activo, mostrar_mensajes_mascota, foto } = req.body;

    if (foto !== undefined) {
      const { validarFoto } = require('../utils/foto');
      const errorFoto = validarFoto(foto);
      if (errorFoto) return respuestaError(res, errorFoto, 400);
    }

    const organizacion = await Organization.findByIdAndUpdate(
      req.params.id,
      { nombre, sector, email, activo, mostrar_mensajes_mascota, foto },
      { new: true, runValidators: true }
    );
    if (!organizacion) {
      return respuestaError(res, 'Organización no encontrada', 404);
    }

    return respuestaExito(res, organizacion, 'Organización actualizada');
  } catch (error) {
    if (error.code === 11000) {
      return respuestaError(res, 'Ya existe una organización con ese nombre', 400);
    }
    next(error);
  }
};

// POST /api/admin/organizaciones/:id/regenerar-codigo  { tipo? }
// tipo: 'estudiante' (default) o 'docente'
exports.regenerarCodigo = async (req, res, next) => {
  try {
    const organizacion = await Organization.findById(req.params.id);
    if (!organizacion) {
      return respuestaError(res, 'Organización no encontrada', 404);
    }
    // El pre-validate genera el que falte
    if (req.body?.tipo === 'docente') {
      organizacion.codigo_docente = undefined;
    } else {
      organizacion.codigo = undefined;
    }
    await organizacion.save();
    return respuestaExito(res, organizacion, 'Código regenerado');
  } catch (error) {
    next(error);
  }
};

// GET /api/public/codigo/:codigo — valida un código de invitación y dice a
// qué organización pertenece y de qué tipo es (para el banner del registro)
exports.validarCodigo = async (req, res, next) => {
  try {
    const codigo = (req.params.codigo || '').trim().toUpperCase();
    if (!codigo) {
      return respuestaError(res, 'Código requerido', 400);
    }
    const organizacion = await Organization.findOne({
      $or: [{ codigo }, { codigo_docente: codigo }],
      activo: true,
    }).select('nombre sector codigo codigo_docente');
    if (!organizacion) {
      return respuestaError(res, 'Código de organización inválido', 404);
    }
    return respuestaExito(res, {
      nombre: organizacion.nombre,
      sector: organizacion.sector,
      tipo: organizacion.codigo_docente === codigo ? 'docente' : 'estudiante',
    }, 'Código válido');
  } catch (error) {
    next(error);
  }
};

// DELETE /api/admin/organizaciones/:id — desvincula usuarios y desactiva
// los niveles de la organización (no borra contenido educativo)
exports.eliminarOrganizacion = async (req, res, next) => {
  try {
    const organizacion = await Organization.findById(req.params.id);
    if (!organizacion) {
      return respuestaError(res, 'Organización no encontrada', 404);
    }

    // Los organizadores de la org eliminada vuelven a ser estudiantes
    await User.updateMany(
      { organizacion_id: organizacion._id, rol: constants.ROLES.ORGANIZER },
      { rol: constants.ROLES.STUDENT }
    );
    const usuarios = await User.updateMany(
      { organizacion_id: organizacion._id },
      { organizacion_id: null }
    );
    const niveles = await Level.updateMany(
      { organizacion_id: organizacion._id },
      { activo: false }
    );
    await organizacion.deleteOne();

    await Log.create({
      tipo: constants.LOG_TYPES.DELETED,
      usuario_id: req.usuarioId,
      descripcion: `Organización eliminada: ${organizacion.nombre} (${usuarios.modifiedCount} usuarios desvinculados, ${niveles.modifiedCount} niveles desactivados)`,
      entidad_tipo: 'organization',
      entidad_id: organizacion._id,
    });

    return respuestaExito(res, {
      usuarios_desvinculados: usuarios.modifiedCount,
      niveles_desactivados: niveles.modifiedCount,
    }, 'Organización eliminada');
  } catch (error) {
    next(error);
  }
};

// PUT /api/admin/usuarios/:id/organizacion  { organizacion_id|null, rol? }
// Asigna (o quita) la organización de un usuario; opcionalmente lo convierte
// en organizador de esa organización.
exports.asignarUsuarioOrganizacion = async (req, res, next) => {
  try {
    const { organizacion_id, rol } = req.body;

    const usuario = await User.findById(req.params.id);
    if (!usuario) {
      return respuestaError(res, constants.ERROR_MESSAGES.USER_NOT_FOUND, 404);
    }
    if (usuario.rol === constants.ROLES.ADMIN) {
      return respuestaError(res, 'No se puede asignar organización a un admin', 400);
    }

    if (organizacion_id) {
      const organizacion = await Organization.findById(organizacion_id);
      if (!organizacion) {
        return respuestaError(res, 'Organización no encontrada', 404);
      }
      usuario.organizacion_id = organizacion._id;
    } else {
      usuario.organizacion_id = null;
    }

    // Solo se permite alternar entre estudiante y organizador
    if (rol === constants.ROLES.ORGANIZER || rol === constants.ROLES.STUDENT) {
      if (rol === constants.ROLES.ORGANIZER && !usuario.organizacion_id) {
        return respuestaError(res, 'Un organizador debe tener organización asignada', 400);
      }
      usuario.rol = rol;
    }
    // Sin organización no puede quedar como organizador
    if (!usuario.organizacion_id && usuario.rol === constants.ROLES.ORGANIZER) {
      usuario.rol = constants.ROLES.STUDENT;
    }

    await usuario.save();
    const conOrg = await User.findById(usuario._id)
      .populate('organizacion_id', 'nombre sector codigo');
    return respuestaExito(res, conOrg, 'Usuario actualizado');
  } catch (error) {
    next(error);
  }
};

// ─── Mi organización (organizador) ───────────────────────────────────────────

// GET /api/admin/mi-organizacion
exports.obtenerMiOrganizacion = async (req, res, next) => {
  try {
    if (!req.usuario.organizacion_id) {
      return respuestaError(res, 'No perteneces a ninguna organización', 404);
    }
    const organizacion = await Organization.findById(req.usuario.organizacion_id);
    if (!organizacion) {
      return respuestaError(res, 'Organización no encontrada', 404);
    }
    return respuestaExito(res, organizacion, 'Organización obtenida');
  } catch (error) {
    next(error);
  }
};

// PUT /api/admin/mi-organizacion — el organizador ajusta la configuración
// visual (mensajes de mascota y logo); nombre/sector los maneja el admin
exports.actualizarMiOrganizacion = async (req, res, next) => {
  try {
    if (!req.usuario.organizacion_id) {
      return respuestaError(res, 'No perteneces a ninguna organización', 404);
    }
    const { mostrar_mensajes_mascota, foto } = req.body;

    const cambios = {};
    if (mostrar_mensajes_mascota !== undefined) {
      cambios.mostrar_mensajes_mascota = !!mostrar_mensajes_mascota;
    }
    if (foto !== undefined) {
      const { validarFoto } = require('../utils/foto');
      const errorFoto = validarFoto(foto);
      if (errorFoto) return respuestaError(res, errorFoto, 400);
      cambios.foto = foto;
    }

    const organizacion = await Organization.findByIdAndUpdate(
      req.usuario.organizacion_id,
      cambios,
      { new: true }
    );
    return respuestaExito(res, organizacion, 'Configuración actualizada');
  } catch (error) {
    next(error);
  }
};

// ─── Solicitudes de organizaciones ───────────────────────────────────────────

// POST /api/public/solicitudes-organizacion (sin autenticación, rate-limited)
exports.crearSolicitud = async (req, res, next) => {
  try {
    const { nombre_organizacion, email, sector, mensaje } = req.body;

    if (!SECTORES.includes(sector)) {
      return respuestaError(res, `Sector inválido. Opciones: ${SECTORES.join(', ')}`, 400);
    }

    const solicitud = await OrgRequest.create({
      nombre_organizacion,
      email,
      sector,
      mensaje: mensaje || '',
    });

    return respuestaExito(
      res,
      { id: solicitud._id },
      '¡Solicitud enviada! Te contactaremos pronto por correo',
      201
    );
  } catch (error) {
    next(error);
  }
};

// GET /api/admin/solicitudes?estado=pendiente
exports.obtenerSolicitudes = async (req, res, next) => {
  try {
    const filtro = {};
    if (req.query.estado) filtro.estado = req.query.estado;
    const solicitudes = await OrgRequest.find(filtro).sort({ createdAt: -1 });
    return respuestaExito(res, solicitudes, 'Solicitudes obtenidas');
  } catch (error) {
    next(error);
  }
};

// PUT /api/admin/solicitudes/:id  { estado: aceptada | rechazada | pendiente }
// Al aceptar o rechazar se envía el correo correspondiente a la organización
// desde la cuenta oficial (si el correo está configurado en el servidor).
exports.actualizarSolicitud = async (req, res, next) => {
  try {
    const { estado } = req.body;
    if (!['pendiente', 'aceptada', 'rechazada'].includes(estado)) {
      return respuestaError(res, 'Estado inválido', 400);
    }
    const solicitud = await OrgRequest.findByIdAndUpdate(
      req.params.id,
      { estado },
      { new: true }
    );
    if (!solicitud) {
      return respuestaError(res, 'Solicitud no encontrada', 404);
    }

    // Notificar por correo el resultado (no rompe la operación si falla)
    let correo = { enviado: false, motivo: 'Sin cambio de resultado' };
    if (estado === 'aceptada' || estado === 'rechazada') {
      const { enviarResultadoSolicitud } = require('../utils/mailer');
      correo = await enviarResultadoSolicitud(solicitud, estado === 'aceptada');
    }

    return respuestaExito(res, {
      solicitud,
      correo_enviado: correo.enviado,
      correo_motivo: correo.motivo || null,
    }, 'Solicitud actualizada');
  } catch (error) {
    next(error);
  }
};

// DELETE /api/admin/solicitudes/:id
exports.eliminarSolicitud = async (req, res, next) => {
  try {
    const solicitud = await OrgRequest.findByIdAndDelete(req.params.id);
    if (!solicitud) {
      return respuestaError(res, 'Solicitud no encontrada', 404);
    }
    return respuestaExito(res, {}, 'Solicitud eliminada');
  } catch (error) {
    next(error);
  }
};
