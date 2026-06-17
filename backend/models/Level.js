const mongoose = require('mongoose');

const levelSchema = new mongoose.Schema(
  {
    nombre: {
      type: String,
      required: [true, 'El nombre del nivel es requerido'],
      unique: true,
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
      unique: true,
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
  },
  {
    timestamps: true,
  }
);

// Índice para ordenar por número
levelSchema.index({ numero: 1 });

module.exports = mongoose.model('Level', levelSchema);
