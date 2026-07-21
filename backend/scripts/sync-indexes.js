// Sincroniza los índices de MongoDB con los esquemas actuales.
// Necesario tras quitar la unicidad global de nombre/numero en Level
// (ahora el nombre es único POR organización).
//
// Uso: node scripts/sync-indexes.js
require('dotenv').config();
const mongoose = require('mongoose');

const Level = require('../models/Level');
const Organization = require('../models/Organization');
const OrgRequest = require('../models/OrgRequest');
const User = require('../models/User');
const Report = require('../models/Report');

(async () => {
  await mongoose.connect(process.env.MONGODB_URI);
  for (const model of [Level, Organization, OrgRequest, User, Report]) {
    const antes = await model.collection.indexes().catch(() => []);
    await model.syncIndexes();
    const despues = await model.collection.indexes();
    console.log(`${model.modelName}:`);
    console.log('  antes :', antes.map((i) => i.name).join(', ') || '(colección nueva)');
    console.log('  ahora :', despues.map((i) => i.name).join(', '));
  }
  await mongoose.disconnect();
  console.log('Índices sincronizados.');
})();
