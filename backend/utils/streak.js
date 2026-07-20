// Lógica de rachas diarias (estilo TikTok/Snapchat).
//
// La racha se mantiene haciendo al menos UNA actividad (ejercicio) por día:
//   - mismo día:            sin cambio
//   - 1 día de diferencia:  racha + 1
//   - 2 días (perdió UNO):  la racha anterior queda "recuperable" hasta el fin
//                           del día en que regresó; mientras tanto racha = 1
//   - 3+ días:              racha = 1, sin posibilidad de reanudar
//
// Reanudar restaura la racha perdida (+1 por el día actual) y consume una de
// las 3 oportunidades del mes.

const LIMITE_REANUDACIONES_MES = 3;

function _soloFecha(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function _finDelDia(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);
}

// Registra actividad del día sobre el documento de usuario (sin guardar).
// Devuelve true si algo cambió y hay que hacer user.save().
function registrarActividad(user) {
  const now = new Date();
  const hoy = _soloFecha(now);

  // Racha recuperable que ya venció deja de ofrecerse
  if (user.racha_recuperable > 0 && user.racha_recuperable_expira && user.racha_recuperable_expira < now) {
    user.racha_recuperable = 0;
    user.racha_recuperable_expira = null;
  }

  if (!user.ultima_actividad) {
    user.racha = 1;
    user.ultima_actividad = now;
    return true;
  }

  const ultimo = _soloFecha(user.ultima_actividad);
  const diffDias = Math.round((hoy - ultimo) / 86400000);

  if (diffDias === 0) {
    return false; // mismo día: nada que actualizar
  }

  if (diffDias === 1) {
    user.racha = (user.racha || 0) + 1;
  } else if (diffDias === 2 && (user.racha || 0) > 0) {
    // Faltó exactamente UN día: ofrecer reanudar hasta el fin de hoy
    user.racha_recuperable = user.racha;
    user.racha_recuperable_expira = _finDelDia(now);
    user.racha = 1;
  } else {
    // Faltó más de un día: se pierde definitivamente
    user.racha = 1;
    user.racha_recuperable = 0;
    user.racha_recuperable_expira = null;
  }

  user.ultima_actividad = now;
  return true;
}

// Intenta reanudar la racha perdida. Devuelve { ok, mensaje? }.
// No guarda: el caller hace user.save() si ok.
function reanudarRacha(user) {
  const now = new Date();

  if (!user.racha_recuperable || user.racha_recuperable <= 0) {
    return { ok: false, mensaje: 'No tienes ninguna racha para reanudar' };
  }
  if (user.racha_recuperable_expira && user.racha_recuperable_expira < now) {
    user.racha_recuperable = 0;
    user.racha_recuperable_expira = null;
    return { ok: false, mensaje: 'La oportunidad de reanudar tu racha ya venció' };
  }

  const mesActual = now.toISOString().slice(0, 7);
  if (user.reanudaciones?.mes !== mesActual) {
    user.reanudaciones = { mes: mesActual, usadas: 0 };
  }
  if (user.reanudaciones.usadas >= LIMITE_REANUDACIONES_MES) {
    return { ok: false, mensaje: 'Ya usaste tus 3 reanudaciones de este mes' };
  }

  // La racha continúa: lo acumulado antes de perderla + el día de hoy
  user.racha = user.racha_recuperable + 1;
  user.racha_recuperable = 0;
  user.racha_recuperable_expira = null;
  user.reanudaciones.usadas += 1;

  return { ok: true };
}

module.exports = {
  registrarActividad,
  reanudarRacha,
  LIMITE_REANUDACIONES_MES,
};
