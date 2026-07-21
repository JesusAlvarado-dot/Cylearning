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
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/, 'Ingresa un email válido'],
    },
    // No requerida si la cuenta se creó/vinculó con Google (googleId presente).
    contrasena: {
      type: String,
      required: [function () { return !this.googleId; }, 'La contraseña es requerida'],
      minlength: [6, 'La contraseña debe tener al menos 6 caracteres'],
      select: false,
    },
    // ID único de la cuenta de Google (payload.sub del idToken verificado).
    // sparse: los usuarios con login local nunca tienen este campo, así el
    // índice unique no choca entre ellos.
    googleId: {
      type: String,
      index: true,
      unique: true,
      sparse: true,
    },
    rol: {
      type: String,
      enum: [constants.ROLES.ADMIN, constants.ROLES.ORGANIZER, constants.ROLES.STUDENT],
      default: constants.ROLES.STUDENT,
    },
    // Organización a la que pertenece (null = usuario del público general).
    // Los estudiantes de una organización solo ven los niveles de esa org;
    // los organizadores gestionan el contenido de la suya.
    organizacion_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      default: null,
    },
    activo: {
      type: Boolean,
      default: true,
    },
    // Foto de perfil: data URI base64 (subida desde la app) o URL https
    // (cuando venga de Google/Facebook). Vacío = avatar con inicial.
    foto: {
      type: String,
      default: '',
    },
    puntos_totales: {
      type: Number,
      default: 0,
    },
    medallas: {
      type: [{
        tipo: { type: String, enum: ['oro', 'plata', 'bronce', 'estrella', 'justiciero'] },
        descripcion: { type: String, default: '' },
        fecha: { type: Date, default: Date.now },
      }],
      default: [],
    },
    ultimo_acceso: {
      type: Date,
      default: null,
    },
    racha: {
      type: Number,
      default: 0,
    },
    ultima_actividad: {
      type: Date,
      default: null,
    },
    // Racha perdida por UN solo día sin actividad: se puede reanudar el mismo
    // día en que el estudiante regresa (estilo TikTok/Snapchat). Si faltó más
    // de un día, no es recuperable y racha vuelve a empezar.
    racha_recuperable: {
      type: Number,
      default: 0,
    },
    racha_recuperable_expira: {
      type: Date,
      default: null,
    },
    // Reanudaciones usadas en el mes (máximo 3): { mes: '2026-07', usadas: 2 }
    reanudaciones: {
      mes: { type: String, default: '' },
      usadas: { type: Number, default: 0 },
    },
  },
  {
    timestamps: true,
  }
);

// Reanudaciones que le quedan al usuario este mes (se resetea cada mes)
userSchema.methods.reanudacionesRestantes = function (limite = 3) {
  const mesActual = new Date().toISOString().slice(0, 7); // '2026-07'
  if (this.reanudaciones?.mes !== mesActual) return limite;
  return Math.max(0, limite - (this.reanudaciones.usadas || 0));
};

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
