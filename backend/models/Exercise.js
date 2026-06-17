const mongoose = require('mongoose');
const constants = require('../config/constants');

const exerciseSchema = new mongoose.Schema(
  {
    pregunta: {
      type: String,
      required: [true, 'La pregunta es requerida'],
      trim: true,
      minlength: [5, 'La pregunta debe tener al menos 5 caracteres'],
    },
    tipo: {
      type: String,
      enum: [
        constants.EXERCISE_TYPES.SINGLE_CHOICE,
        constants.EXERCISE_TYPES.FILL_IN,
        constants.EXERCISE_TYPES.TRUE_FALSE,
      ],
      required: [true, 'El tipo de ejercicio es requerido'],
    },
    opciones: {
      type: [String],
      validate: {
        validator: function (v) {
          // Para selección única y verdadero/falso se requieren opciones
          if (
            this.tipo === constants.EXERCISE_TYPES.SINGLE_CHOICE ||
            this.tipo === constants.EXERCISE_TYPES.TRUE_FALSE
          ) {
            return v && v.length > 0;
          }
          return true;
        },
        message: 'Las opciones son requeridas para este tipo de ejercicio',
      },
    },
    respuesta_correcta: {
      type: String,
      required: [true, 'La respuesta correcta es requerida'],
      trim: true,
    },
    explicacion: {
      type: String,
      trim: true,
      maxlength: [500, 'La explicación no puede exceder 500 caracteres'],
    },
    puntos: {
      type: Number,
      default: constants.DEFAULT_POINTS,
      min: [0, 'Los puntos no pueden ser negativos'],
      max: [100, 'Los puntos no pueden exceder 100'],
    },
    leccion_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lesson',
      required: [true, 'La lección es requerida'],
    },
    activo: {
      type: Boolean,
      default: true,
    },
    orden: {
      type: Number,
      default: 0,
    },
    creado_por: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// Índices para búsquedas rápidas
exerciseSchema.index({ leccion_id: 1 });
exerciseSchema.index({ creado_por: 1 });
exerciseSchema.index({ activo: 1 });

module.exports = mongoose.model('Exercise', exerciseSchema);
