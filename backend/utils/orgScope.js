// Alcance por organización para el panel de contenido.
//
// El admin (dueños de la app) puede tocar todo. El organizador solo puede
// ver/crear/editar contenido cuyo nivel pertenece a SU organización.
const Level = require('../models/Level');
const Topic = require('../models/Topic');
const Lesson = require('../models/Lesson');
const constants = require('../config/constants');

function esAdmin(req) {
  return req.usuario?.rol === constants.ROLES.ADMIN;
}

function esOrganizador(req) {
  return req.usuario?.rol === constants.ROLES.ORGANIZER;
}

function orgDelUsuario(req) {
  return req.usuario?.organizacion_id ? req.usuario.organizacion_id.toString() : null;
}

// ¿El usuario puede administrar este nivel?
async function puedeTocarNivel(req, nivelId) {
  if (esAdmin(req)) return true;
  if (!esOrganizador(req)) return false;
  const org = orgDelUsuario(req);
  if (!org) return false;
  const nivel = await Level.findById(nivelId).select('organizacion_id');
  if (!nivel) return false;
  return nivel.organizacion_id?.toString() === org;
}

async function puedeTocarTema(req, temaId) {
  if (esAdmin(req)) return true;
  const tema = await Topic.findById(temaId).select('nivel_id');
  if (!tema) return false;
  return puedeTocarNivel(req, tema.nivel_id);
}

async function puedeTocarLeccion(req, leccionId) {
  if (esAdmin(req)) return true;
  const leccion = await Lesson.findById(leccionId).select('tema_id');
  if (!leccion) return false;
  return puedeTocarTema(req, leccion.tema_id);
}

// IDs de niveles administrables por el usuario (para filtrar listados).
// Devuelve null si es admin (sin filtro).
async function nivelesDelAlcance(req) {
  if (esAdmin(req)) return null;
  const org = orgDelUsuario(req);
  if (!org) return [];
  const niveles = await Level.find({ organizacion_id: org }).select('_id');
  return niveles.map((n) => n._id);
}

module.exports = {
  esAdmin,
  esOrganizador,
  orgDelUsuario,
  puedeTocarNivel,
  puedeTocarTema,
  puedeTocarLeccion,
  nivelesDelAlcance,
};
