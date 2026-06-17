const Topic = require('../models/Topic');
const Level = require('../models/Level');
const Lesson = require('../models/Lesson');
const { respuestaExito, respuestaError, respuestaPaginada, paginar } = require('../utils/helpers');
const constants = require('../config/constants');
const Log = require('../models/Log');

// Crear tema (solo admin)
exports.crearTema = async (req, res, next) => {
  try {
    const { nombre, descripcion, nivel_id, orden } = req.body;

    // Validar que el nivel existe
    const nivel = await Level.findById(nivel_id);
    if (!nivel) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.LEVEL_NOT_FOUND,
        404
      );
    }

    const tema = new Topic({
      nombre,
      descripcion,
      nivel_id,
      orden: orden || 0,
    });

    await tema.save();

    // Registrar en logs
    await Log.create({
      tipo: 'creado',
      usuario_id: req.usuarioId,
      descripcion: `Tema creado: ${nombre}`,
      entidad_tipo: 'topic',
      entidad_id: tema._id,
    });

    return respuestaExito(
      res,
      tema,
      constants.SUCCESS_MESSAGES.EXERCISE_CREATED,
      201
    );
  } catch (error) {
    next(error);
  }
};

// Obtener todos los temas
exports.obtenerTodoLosTemas = async (req, res, next) => {
  try {
    const { pagina = 1, limite = 10, nivel_id, activo } = req.query;
    const { skip, limit } = paginar(pagina, limite);

    const filtro = {};
    if (nivel_id) filtro.nivel_id = nivel_id;
    if (activo !== undefined) filtro.activo = activo === 'true';

    const temas = await Topic.find(filtro)
      .skip(skip)
      .limit(limit)
      .populate('nivel_id', 'nombre')
      .sort({ orden: 1 });

    const total = await Topic.countDocuments(filtro);

    const respuesta = respuestaPaginada(temas, total, pagina, limite);

    return respuestaExito(
      res,
      respuesta,
      'Temas obtenidos exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Obtener tema por ID
exports.obtenerTemaPorId = async (req, res, next) => {
  try {
    const { id } = req.params;

    const tema = await Topic.findById(id).populate('nivel_id', 'nombre');

    if (!tema) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.TOPIC_NOT_FOUND,
        404
      );
    }

    // Obtener lecciones del tema
    const lecciones = await Lesson.find({ tema_id: id }).sort({ orden: 1 });

    return respuestaExito(
      res,
      { ...tema.toObject(), lecciones },
      'Tema obtenido exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Actualizar tema (solo admin)
exports.actualizarTema = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion, orden, activo } = req.body;

    const tema = await Topic.findByIdAndUpdate(
      id,
      { nombre, descripcion, orden, activo },
      { new: true, runValidators: true }
    ).populate('nivel_id', 'nombre');

    if (!tema) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.TOPIC_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: 'actualizado',
      usuario_id: req.usuarioId,
      descripcion: `Tema actualizado: ${nombre}`,
      entidad_tipo: 'topic',
      entidad_id: tema._id,
    });

    return respuestaExito(
      res,
      tema,
      'Tema actualizado exitosamente'
    );
  } catch (error) {
    next(error);
  }
};

// Eliminar tema (solo admin)
exports.eliminarTema = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Verificar que no tenga lecciones
    const lecciones = await Lesson.countDocuments({ tema_id: id });
    if (lecciones > 0) {
      return respuestaError(
        res,
        'No se puede eliminar un tema que tiene lecciones asociadas',
        400
      );
    }

    const tema = await Topic.findByIdAndDelete(id);

    if (!tema) {
      return respuestaError(
        res,
        constants.ERROR_MESSAGES.TOPIC_NOT_FOUND,
        404
      );
    }

    // Registrar en logs
    await Log.create({
      tipo: 'eliminado',
      usuario_id: req.usuarioId,
      descripcion: `Tema eliminado: ${tema.nombre}`,
      entidad_tipo: 'topic',
      entidad_id: tema._id,
    });

    return respuestaExito(
      res,
      {},
      'Tema eliminado exitosamente'
    );
  } catch (error) {
    next(error);
  }
};
