const Report = require('../models/Report');
const User = require('../models/User');
const Exercise = require('../models/Exercise');
const { respuestaExito, respuestaError } = require('../utils/helpers');
const constants = require('../config/constants');

const MENSAJES_POR_DEFECTO = {
  fundado:
    'Recibimos tu reporte. Lo revisamos y consideramos que tenías razón: tomamos acción al respecto. ¡Gracias por ayudar a mantener CyLearn seguro!',
  infundado:
    'Recibimos tu reporte. Lo revisamos y, por ahora, no encontramos evidencia suficiente para tomar acción.',
};

const TIPOS_USUARIO = ['usuario_foto', 'usuario_nombre'];

// POST /api/student/reportes  { tipo: 'usuario_foto'|'usuario_nombre'|'ejercicio', entidad_id, motivo }
exports.crearReporte = async (req, res, next) => {
  try {
    const { tipo, entidad_id, motivo } = req.body;

    if (!Report.TIPOS.includes(tipo)) {
      return respuestaError(res, `Tipo de reporte inválido. Opciones: ${Report.TIPOS.join(', ')}`, 400);
    }
    if (!motivo || typeof motivo !== 'string' || !motivo.trim()) {
      return respuestaError(res, 'El motivo es requerido', 400);
    }

    if (TIPOS_USUARIO.includes(tipo)) {
      if (entidad_id === String(req.usuarioId)) {
        return respuestaError(res, 'No puedes reportarte a ti mismo', 400);
      }
      const usuario = await User.findById(entidad_id).select('_id');
      if (!usuario) return respuestaError(res, constants.ERROR_MESSAGES.USER_NOT_FOUND, 404);
    } else {
      const ejercicio = await Exercise.findById(entidad_id).select('_id');
      if (!ejercicio) return respuestaError(res, constants.ERROR_MESSAGES.EXERCISE_NOT_FOUND, 404);
    }

    const yaPendiente = await Report.findOne({
      tipo,
      entidad_id,
      reportado_por: req.usuarioId,
      estado: 'pendiente',
    });
    if (yaPendiente) {
      return respuestaError(res, 'Ya tienes un reporte pendiente sobre esto', 400);
    }

    const reporte = await Report.create({
      tipo,
      entidad_id,
      reportado_por: req.usuarioId,
      motivo: motivo.trim().slice(0, 500),
    });

    return respuestaExito(res, reporte, 'Reporte enviado. Nuestro equipo lo va a revisar.', 201);
  } catch (error) {
    next(error);
  }
};

// GET /api/student/reportes — reportes que YO envié, con la respuesta del admin
exports.misReportes = async (req, res, next) => {
  try {
    const reportes = await Report.find({ reportado_por: req.usuarioId }).sort({ createdAt: -1 });
    return respuestaExito(res, reportes, 'Reportes obtenidos');
  } catch (error) {
    next(error);
  }
};

// GET /api/admin/reportes?estado=pendiente — solo admin
exports.obtenerReportes = async (req, res, next) => {
  try {
    const filtro = {};
    if (req.query.estado) filtro.estado = req.query.estado;

    const reportes = await Report.find(filtro)
      .populate('reportado_por', 'nombre email foto')
      .sort({ createdAt: -1 });

    // Se agrega un resumen de la entidad reportada para que el admin pueda
    // valorar el reporte sin tener que ir a buscarla aparte.
    const conDetalle = await Promise.all(
      reportes.map(async (r) => {
        const obj = r.toObject();
        if (TIPOS_USUARIO.includes(r.tipo)) {
          const u = await User.findById(r.entidad_id).select('nombre email foto activo');
          obj.entidad = u ? { nombre: u.nombre, email: u.email, foto: u.foto, activo: u.activo } : null;
        } else {
          const e = await Exercise.findById(r.entidad_id).select('pregunta tipo opciones activo');
          obj.entidad = e
            ? { pregunta: e.pregunta, tipo: e.tipo, opciones: e.opciones, activo: e.activo }
            : null;
        }
        return obj;
      })
    );

    return respuestaExito(res, conDetalle, 'Reportes obtenidos');
  } catch (error) {
    next(error);
  }
};

// PUT /api/admin/reportes/:id  { estado: 'fundado'|'infundado', respuesta_admin? }
exports.resolverReporte = async (req, res, next) => {
  try {
    const { estado, respuesta_admin } = req.body;
    if (!['fundado', 'infundado'].includes(estado)) {
      return respuestaError(res, 'Estado inválido', 400);
    }

    const reporte = await Report.findById(req.params.id);
    if (!reporte) return respuestaError(res, 'Reporte no encontrado', 404);
    if (reporte.estado !== 'pendiente') {
      return respuestaError(res, 'Este reporte ya fue resuelto', 400);
    }

    reporte.estado = estado;
    reporte.respuesta_admin =
      (respuesta_admin && respuesta_admin.trim()) || MENSAJES_POR_DEFECTO[estado];
    reporte.resuelto_por = req.usuarioId;
    reporte.resuelto_en = new Date();
    await reporte.save();

    if (estado === 'fundado') {
      // Consecuencia sobre lo reportado
      if (reporte.tipo === 'usuario_foto') {
        await User.findByIdAndUpdate(reporte.entidad_id, { foto: '' });
      } else if (reporte.tipo === 'usuario_nombre') {
        // No se puede dejar el nombre vacío (mínimo 3 caracteres en el
        // esquema), así que se reemplaza por un nombre neutro; el usuario
        // puede ponerse otro desde su perfil.
        const nombreNeutro = `Usuario${String(reporte.entidad_id).slice(-5)}`;
        await User.findByIdAndUpdate(reporte.entidad_id, { nombre: nombreNeutro });
      } else {
        await Exercise.findByIdAndUpdate(reporte.entidad_id, { activo: false });
      }

      // Medalla "Justiciero" para quien reportó correctamente (una sola vez)
      const reportador = await User.findById(reporte.reportado_por);
      if (reportador && !reportador.medallas.some((m) => m.tipo === 'justiciero')) {
        reportador.medallas.push({
          tipo: 'justiciero',
          descripcion: 'Ayudó a detectar contenido inapropiado en la comunidad',
        });
        await reportador.save();
      }
    }

    return respuestaExito(res, reporte, 'Reporte resuelto');
  } catch (error) {
    next(error);
  }
};
