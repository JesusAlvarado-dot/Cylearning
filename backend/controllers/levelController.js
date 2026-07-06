const Level = require('../models/Level');
const Topic = require('../models/Topic');
const Lesson = require('../models/Lesson');
const { respuestaExito, respuestaError, respuestaPaginada, paginar } = require('../utils/helpers');
const constants = require('../config/constants');
const Log = require('../models/Log');

// Crear nivel (solo admin)
exports.crearNivel = async (req, res, next) => {
  try {
    const { nombre, descripcion, numero, dificultad, orden } = req.body;

    const nivel = new Level({
      nombre,
      descripcion,
      numero,
      dificultad: dificultad || 'principiante',
      orden: orden || 0,
    });

    await nivel.save();

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.LEVEL_CREATED,
      usuario_id: req.usuarioId,
      descripcion: `Nivel creado: ${nombre}`,
      entidad_tipo: 'level',
      entidad_id: nivel._id,
    });

    return respuestaExito(
      res,
      nivel,
      constants.SUCCESS_MESSAGES.EXERCISE_CREATED,
      201
    );
  } catch (error) {
    next(error);
  }
};

// Obtener todos los niveles
exports.obtenerTodosLosNiveles = async (req, res, next) => {
  try {
    const { pagina = 1, limite = 10, activo } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const filtro = {};
    if (activo !== undefined) {
      filtro.activo = activo === 'true';
    }

    const niveles = await Level.find(filtro)
      .skip(skip)
      .limit(limit)
      .sort({ orden: 1, numero: 1 })
      .lean();

    // Adjuntar las lecciones de cada nivel para que el cliente
    // pueda mostrar el progreso real (X/Y lecciones completadas)
    const nivelIds = niveles.map((n) => n._id);
    const temas = await Topic.find({ nivel_id: { $in: nivelIds } })
      .select('_id nivel_id')
      .lean();
    const lecciones = await Lesson.find({ tema_id: { $in: temas.map((t) => t._id) } })
      .select('_id tema_id')
      .lean();

    const nivelDeTema = new Map(temas.map((t) => [t._id.toString(), t.nivel_id.toString()]));
    const leccionesPorNivel = {};
    for (const l of lecciones) {
      const nivelId = nivelDeTema.get(l.tema_id.toString());
      if (!nivelId) continue;
      (leccionesPorNivel[nivelId] = leccionesPorNivel[nivelId] || []).push(l._id.toString());
    }
    for (const n of niveles) {
      n.lecciones = leccionesPorNivel[n._id.toString()] || [];
      n.total_lecciones = n.lecciones.length;
    }

    const total = await Level.countDocuments(filtro);

    const respuesta = respuestaPaginada(niveles, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Niveles obtenidos exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener nivel por ID
exports.obtenerNivelPorId = async (req, res, next) => {
  try {
    const { id } = req.params;

    const nivel = await Level.findById(id);

    if (!nivel) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LEVEL_NOT_FOUND,
        404
      );
    }

    // Obtener temas del nivel
    const temas = await Topic.find({ nivel_id: id }).sort({ orden: 1 });

    return respuestaExito(
      res,
      { ...nivel.toObject(), temas },
      'Nivel obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Actualizar nivel (solo admin)
exports.actualizarNivel = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion, dificultad, orden, activo } = req.body;

    const nivel = await Level.findByIdAndUpdate(
      id,
      { nombre, descripcion, dificultad, orden, activo },
      { new: true, runValidators: true }
    );

    if (!nivel) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LEVEL_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: 'actualizado',
      usuario_id: req.usuarioId,
      descripcion: `Nivel actualizado: ${nombre}`,
      entidad_tipo: 'level',
      entidad_id: nivel._id,
    });

    return respuestaExito(
      res,
      nivel,
      'Nivel actualizado exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Eliminar nivel (solo admin)
exports.eliminarNivel = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Verificar que no tenga temas
    const temas = await Topic.countDocuments({ nivel_id: id });
    if (temas > 0) {
      return respuestaError(
        res,
        'No se puede eliminar un nivel que tiene temas asociados',
        400
      );
    }

    const nivel = await Level.findByIdAndDelete(id);

    if (!nivel) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LEVEL_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: constants.LOG_TYPES.LEVEL_DELETED,
      usuario_id: req.usuarioId,
      descripcion: `Nivel eliminado: ${nivel.nombre}`,
      entidad_tipo: 'level',
      entidad_id: nivel._id,
    });

    return respuestaExito(
      res,
      {},
      'Nivel eliminado exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener nivel con estructura completa (niveles -> temas -> lecciones)
exports.obtenerEstructuraNivel = async (req, res, next) => {
  try {
    const { id } = req.params;

    const nivel = await Level.findById(id);

    if (!nivel) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LEVEL_NOT_FOUND,
        404
      );
    }

    // Obtener temas con lecciones
    const temas = await Topic.find({ nivel_id: id })
      .sort({ orden: 1 })
      .lean();

    for (let tema of temas) {
      tema.lecciones = await Lesson.find({ tema_id: tema._id })
        .sort({ orden: 1 })
        .lean();
    }

    return respuestaExito(
      res,
      { ...nivel.toObject(), temas },
      'Estructura del nivel obtenida exitosamente'
    );
  } catch (error) {
    next(error);
  }
};
