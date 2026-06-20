const mongoose = require('mongoose');

// Simple progress tracker: which lessons and levels has the student completed
const ProgresoSchema = new mongoose.Schema(
  {
    estudiante_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    lecciones_completadas: [
      { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson' },
    ],
    niveles_completados: [
      { type: mongoose.Schema.Types.ObjectId, ref: 'Level' },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Progreso', ProgresoSchema);
