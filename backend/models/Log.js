const mongoose = require('mongoose');
const constants = require('../config/constants');

const logSchema = new mongoose.Schema(
  {
    tipo: {
      type: String,
      enum: Object.values(constants.LOG_TYPES),
      required: true,
    },
    usuario_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    descripcion: {
      type: String,
      required: true,
      trim: true,
    },
    entidad_tipo: {
      type: String,
      enum: {
        values: ['user', 'exercise', 'level', 'topic', 'lesson', 'progress', 'organization'],
        message: 'Tipo de entidad no válido',
      },
      default: undefined,
      sparse: true,
    },
    entidad_id: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
    },
    detalles: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    ip_address: {
      type: String,
      default: null,
    },
    estado: {
      type: String,
      enum: ['exitoso', 'fallido', 'pendiente'],
      default: 'exitoso',
    },
    error_message: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Índices para búsquedas rápidas
logSchema.index({ usuario_id: 1 });
logSchema.index({ tipo: 1 });
logSchema.index({ createdAt: -1 });
// TTL: MongoDB borra automáticamente los logs con más de 90 días
logSchema.index({ createdAt: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 90 });
logSchema.index({ entidad_tipo: 1, entidad_id: 1 });

module.exports = mongoose.model('Log', logSchema);
