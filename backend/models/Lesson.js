const mongoose = require('mongoose');

const lessonSchema = new mongoose.Schema(
  {
    nombre: {
      type: String,
      required: [true, 'El nombre de la lección es requerido'],
      trim: true,
      minlength: [3, 'El nombre debe tener al menos 3 caracteres'],
    },
    descripcion: {
      type: String,
      trim: true,
      maxlength: [1000, 'La descripción no puede exceder 1000 caracteres'],
    },
    tema_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Topic',
      required: [true, 'El tema es requerido'],
    },
    contenido: {
      type: String,
      trim: true,
    },
    orden: {
      type: Number,
      default: 0,
    },
    activo: {
      type: Boolean,
      default: true,
    },
    punto_minimo: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// Índice para búsquedas por tema
lessonSchema.index({ tema_id: 1 });

module.exports = mongoose.model('Lesson', lessonSchema);
