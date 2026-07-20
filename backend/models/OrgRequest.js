const mongoose = require('mongoose');
const { SECTORES } = require('./Organization');

// Solicitud enviada desde la pantalla de login por una organización
// interesada. El admin las revisa y responde por correo desde la app.
const orgRequestSchema = new mongoose.Schema(
  {
    nombre_organizacion: {
      type: String,
      required: [true, 'El nombre de la organización es requerido'],
      trim: true,
      minlength: [3, 'El nombre debe tener al menos 3 caracteres'],
      maxlength: [80, 'El nombre no puede exceder 80 caracteres'],
    },
    email: {
      type: String,
      required: [true, 'El email de contacto es requerido'],
      lowercase: true,
      trim: true,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/, 'Ingresa un email válido'],
    },
    sector: {
      type: String,
      enum: SECTORES,
      required: [true, 'El sector es requerido'],
    },
    mensaje: {
      type: String,
      trim: true,
      maxlength: [1000, 'El mensaje no puede exceder 1000 caracteres'],
      default: '',
    },
    estado: {
      type: String,
      // 'atendida' se conserva por compatibilidad con solicitudes viejas;
      // el flujo actual usa aceptada (envía correo 🎉) o rechazada (correo de
      // disculpa), ambos desde la cuenta oficial
      enum: ['pendiente', 'aceptada', 'rechazada', 'atendida'],
      default: 'pendiente',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('OrgRequest', orgRequestSchema);
