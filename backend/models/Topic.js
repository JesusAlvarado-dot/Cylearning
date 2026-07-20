const mongoose = require('mongoose');

const topicSchema = new mongoose.Schema(
  {
    nombre: {
      type: String,
      required: [true, 'El nombre del tema es requerido'],
      trim: true,
      minlength: [3, 'El nombre debe tener al menos 3 caracteres'],
    },
    descripcion: {
      type: String,
      trim: true,
      maxlength: [500, 'La descripción no puede exceder 500 caracteres'],
    },
    nivel_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Level',
      required: [true, 'El nivel es requerido'],
    },
    orden: {
      type: Number,
      default: 0,
    },
    activo: {
      type: Boolean,
      default: true,
    },
    // Personaje que aparece en el caminito de lecciones de este tema
    // (índice del muñequillo elegido por el organizador; null = rotación automática)
    mascota: {
      type: Number,
      min: 0,
      max: 4,
      default: null,
    },
    // Mensaje personalizado del personaje ('' = mensajes automáticos)
    mensaje_mascota: {
      type: String,
      trim: true,
      maxlength: [200, 'El mensaje no puede exceder 200 caracteres'],
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

// Índice para búsquedas por nivel
topicSchema.index({ nivel_id: 1 });

module.exports = mongoose.model('Topic', topicSchema);
