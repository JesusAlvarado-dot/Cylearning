const mongoose = require('mongoose');

const levelSchema = new mongoose.Schema(
  {
    nombre: {
      type: String,
      required: [true, 'El nombre del nivel es requerido'],
      trim: true,
      minlength: [3, 'El nombre debe tener al menos 3 caracteres'],
    },
    descripcion: {
      type: String,
      trim: true,
      maxlength: [500, 'La descripción no puede exceder 500 caracteres'],
    },
    numero: {
      type: Number,
      required: [true, 'El número del nivel es requerido'],
    },
    dificultad: {
      type: String,
      enum: ['principiante', 'intermedio', 'avanzado'],
      default: 'principiante',
    },
    activo: {
      type: Boolean,
      default: true,
    },
    orden: {
      type: Number,
      default: 0,
    },
    // null = nivel público (para usuarios sin organización).
    // Con valor = nivel exclusivo de esa organización.
    organizacion_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      default: null,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Índice para ordenar por número. El nombre/número son únicos DENTRO de cada
// organización (dos orgs distintas pueden tener un "Nivel 1" cada una).
levelSchema.index({ numero: 1 });
levelSchema.index({ organizacion_id: 1, nombre: 1 }, { unique: true });

module.exports = mongoose.model('Level', levelSchema);
