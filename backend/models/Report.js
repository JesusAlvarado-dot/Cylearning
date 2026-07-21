const mongoose = require('mongoose');

// Reporte de un estudiante sobre contenido problemático: foto de perfil de
// otro usuario (visible en el ranking) o un ejercicio (contenido educativo
// creado por una organización con fines cuestionables). El admin lo revisa
// y decide si está fundado o no; la resolución queda registrada aquí para
// que quien reportó pueda ver la respuesta.
const TIPOS = ['usuario_foto', 'ejercicio'];
const ESTADOS = ['pendiente', 'fundado', 'infundado'];

const reportSchema = new mongoose.Schema(
  {
    tipo: {
      type: String,
      enum: TIPOS,
      required: true,
    },
    // ID del User (usuario_foto) o del Exercise (ejercicio) reportado
    entidad_id: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
    },
    reportado_por: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    motivo: {
      type: String,
      required: [true, 'El motivo es requerido'],
      trim: true,
      maxlength: 500,
    },
    estado: {
      type: String,
      enum: ESTADOS,
      default: 'pendiente',
    },
    // Mensaje que ve quien reportó al resolverse ("Recibimos tu reporte...")
    respuesta_admin: {
      type: String,
      default: '',
    },
    resuelto_por: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    resuelto_en: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

reportSchema.index({ estado: 1 });
reportSchema.index({ reportado_por: 1 });
reportSchema.index({ tipo: 1, entidad_id: 1 });

module.exports = mongoose.model('Report', reportSchema);
module.exports.TIPOS = TIPOS;
module.exports.ESTADOS = ESTADOS;
