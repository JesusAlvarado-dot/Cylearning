const mongoose = require('mongoose');
const crypto = require('crypto');

// Sectores disponibles: definen el tema visual que ve el estudiante
const SECTORES = ['escuela', 'colegio', 'universidad', 'empresa'];

const organizationSchema = new mongoose.Schema(
  {
    nombre: {
      type: String,
      required: [true, 'El nombre de la organización es requerido'],
      unique: true,
      trim: true,
      minlength: [3, 'El nombre debe tener al menos 3 caracteres'],
      maxlength: [80, 'El nombre no puede exceder 80 caracteres'],
    },
    // Código que los estudiantes ingresan al registrarse para unirse
    codigo: {
      type: String,
      unique: true,
      uppercase: true,
      index: true,
    },
    // Código para que otros profesores se registren como organizadores
    // de esta misma organización (se comparte por el link de invitación)
    codigo_docente: {
      type: String,
      unique: true,
      uppercase: true,
      index: true,
      sparse: true,
    },
    sector: {
      type: String,
      enum: SECTORES,
      required: [true, 'El sector es requerido'],
    },
    email: {
      type: String,
      required: [true, 'El email de contacto es requerido'],
      lowercase: true,
      trim: true,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/, 'Ingresa un email válido'],
    },
    activo: {
      type: Boolean,
      default: true,
    },
    // Si la organización muestra los personajes con mensajes motivacionales
    // en el caminito de lecciones
    mostrar_mensajes_mascota: {
      type: Boolean,
      default: true,
    },
    // Logo/foto de la organización (data URI base64 o URL https)
    foto: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

// Código corto legible, sin caracteres ambiguos (0/O, 1/I/L)
organizationSchema.statics.generarCodigo = function () {
  const alfabeto = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  let codigo = '';
  const bytes = crypto.randomBytes(6);
  for (let i = 0; i < 6; i++) {
    codigo += alfabeto[bytes[i] % alfabeto.length];
  }
  return codigo;
};

// Genera un código que no choque con ningún código existente (de estudiante
// ni de docente, para que un mismo código nunca sea ambiguo)
organizationSchema.statics.codigoLibre = async function () {
  for (let i = 0; i < 5; i++) {
    const candidato = this.generarCodigo();
    const existe = await this.findOne({
      $or: [{ codigo: candidato }, { codigo_docente: candidato }],
    });
    if (!existe) return candidato;
  }
  return this.generarCodigo();
};

organizationSchema.pre('validate', async function (next) {
  const Organization = this.constructor;
  if (!this.codigo) {
    this.codigo = await Organization.codigoLibre();
  }
  if (!this.codigo_docente) {
    this.codigo_docente = await Organization.codigoLibre();
  }
  next();
});

module.exports = mongoose.model('Organization', organizationSchema);
module.exports.SECTORES = SECTORES;
