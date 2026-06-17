const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const constants = require('../config/constants');

const userSchema = new mongoose.Schema(
  {
    nombre: {
      type: String,
      required: [true, 'El nombre es requerido'],
      trim: true,
      minlength: [3, 'El nombre debe tener al menos 3 caracteres'],
      maxlength: [50, 'El nombre no puede exceder 50 caracteres'],
    },
    email: {
      type: String,
      required: [true, 'El email es requerido'],
      unique: true,
      lowercase: true,
      match: [/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/, 'Ingresa un email válido'],
    },
    contrasena: {
      type: String,
      required: [true, 'La contraseña es requerida'],
      minlength: [6, 'La contraseña debe tener al menos 6 caracteres'],
      select: false,
    },
    rol: {
      type: String,
      enum: [constants.ROLES.ADMIN, constants.ROLES.STUDENT],
      default: constants.ROLES.STUDENT,
    },
    activo: {
      type: Boolean,
      default: true,
    },
    puntos_totales: {
      type: Number,
      default: 0,
    },
    medallas: {
      type: [{
        tipo: { type: String, enum: ['oro', 'plata', 'bronce', 'estrella'] },
        descripcion: { type: String, default: '' },
        fecha: { type: Date, default: Date.now },
      }],
      default: [],
    },
    ultimo_acceso: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Middleware para hashear la contraseña antes de guardar
userSchema.pre('save', async function (next) {
  // Si la contraseña no fue modificada, continua
  if (!this.isModified('contrasena')) {
    return next();
  }

  try {
    const salt = await bcrypt.genSalt(10);
    this.contrasena = await bcrypt.hash(this.contrasena, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Método para comparar contraseñas
userSchema.methods.compararContrasena = async function (contrasenaIngresada) {
  return await bcrypt.compare(contrasenaIngresada, this.contrasena);
};

// Método para obtener el usuario sin la contraseña
userSchema.methods.toJSON = function () {
  const usuario = this.toObject();
  delete usuario.contrasena;
  return usuario;
};

module.exports = mongoose.model('User', userSchema);
