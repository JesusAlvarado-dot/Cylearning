const mongoose = require('mongoose');
const constants = require('../config/constants');

const studentProgressSchema = new mongoose.Schema(
  {
    estudiante_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    leccion_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lesson',
      required: true,
    },
    tema_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Topic',
      required: true,
    },
    nivel_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Level',
      required: true,
    },
    estado: {
      type: String,
      enum: [
        constants.PROGRESS_STATUS.NOT_STARTED,
        constants.PROGRESS_STATUS.IN_PROGRESS,
        constants.PROGRESS_STATUS.COMPLETED,
      ],
      default: constants.PROGRESS_STATUS.NOT_STARTED,
    },
    puntos_obtenidos: {
      type: Number,
      default: 0,
    },
    puntos_totales: {
      type: Number,
      default: 0,
    },
    ejercicios_respondidos: {
      type: Number,
      default: 0,
    },
    ejercicios_correctos: {
      type: Number,
      default: 0,
    },
    porcentaje_completado: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },
    fecha_inicio: {
      type: Date,
      default: Date.now,
    },
    fecha_completado: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Índices para búsquedas rápidas
studentProgressSchema.index({ estudiante_id: 1, leccion_id: 1 }, { unique: true });
studentProgressSchema.index({ estudiante_id: 1 });
studentProgressSchema.index({ nivel_id: 1 });
studentProgressSchema.index({ tema_id: 1 });

module.exports = mongoose.model('StudentProgress', studentProgressSchema);
