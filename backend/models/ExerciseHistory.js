const mongoose = require('mongoose');
const constants = require('../config/constants');

const exerciseHistorySchema = new mongoose.Schema(
  {
    estudiante_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    ejercicio_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Exercise',
      required: true,
    },
    leccion_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lesson',
      required: true,
    },
    respuesta_ingresada: {
      type: String,
      required: true,
      trim: true,
    },
    estado: {
      type: String,
      enum: [constants.ANSWER_STATUS.CORRECT, constants.ANSWER_STATUS.INCORRECT],
      required: true,
    },
    puntos_ganados: {
      type: Number,
      default: 0,
      min: 0,
    },
    tiempo_respuesta: {
      type: Number, // en segundos
      default: 0,
    },
    intento_numero: {
      type: Number,
      default: 1,
    },
  },
  {
    timestamps: true,
  }
);

// Índices para búsquedas rápidas
exerciseHistorySchema.index({ estudiante_id: 1 });
exerciseHistorySchema.index({ ejercicio_id: 1 });
exerciseHistorySchema.index({ leccion_id: 1 });
exerciseHistorySchema.index({ estudiante_id: 1, ejercicio_id: 1 });
exerciseHistorySchema.index({ createdAt: 1 });

module.exports = mongoose.model('ExerciseHistory', exerciseHistorySchema);
