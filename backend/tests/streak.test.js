/**
 * Tests unitarios de la lógica de rachas (utils/streak.js).
 * No requieren base de datos: operan sobre objetos planos.
 */
const { registrarActividad, reanudarRacha } = require('../utils/streak');

// Usuario "limpio" para cada caso
function nuevoUsuario(overrides = {}) {
  return {
    racha: 0,
    ultima_actividad: null,
    racha_recuperable: 0,
    racha_recuperable_expira: null,
    reanudaciones: { mes: '', usadas: 0 },
    ...overrides,
  };
}

function haceDias(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

describe('registrarActividad', () => {
  test('primera actividad inicia la racha en 1', () => {
    const u = nuevoUsuario();
    expect(registrarActividad(u)).toBe(true);
    expect(u.racha).toBe(1);
    expect(u.ultima_actividad).not.toBeNull();
  });

  test('actividad el mismo día no cambia nada', () => {
    const u = nuevoUsuario({ racha: 5, ultima_actividad: new Date() });
    expect(registrarActividad(u)).toBe(false);
    expect(u.racha).toBe(5);
  });

  test('actividad al día siguiente suma 1', () => {
    const u = nuevoUsuario({ racha: 5, ultima_actividad: haceDias(1) });
    registrarActividad(u);
    expect(u.racha).toBe(6);
    expect(u.racha_recuperable).toBe(0);
  });

  test('perder exactamente UN día deja la racha recuperable', () => {
    const u = nuevoUsuario({ racha: 10, ultima_actividad: haceDias(2) });
    registrarActividad(u);
    expect(u.racha).toBe(1);
    expect(u.racha_recuperable).toBe(10);
    expect(u.racha_recuperable_expira).not.toBeNull();
    // Expira hoy al final del día
    const hoy = new Date();
    expect(u.racha_recuperable_expira.getDate()).toBe(hoy.getDate());
  });

  test('perder DOS o más días reinicia sin opción de reanudar', () => {
    const u = nuevoUsuario({ racha: 10, ultima_actividad: haceDias(3) });
    registrarActividad(u);
    expect(u.racha).toBe(1);
    expect(u.racha_recuperable).toBe(0);
    expect(u.racha_recuperable_expira).toBeNull();
  });

  test('una racha recuperable vencida se limpia en la siguiente actividad', () => {
    const ayer = haceDias(1);
    const u = nuevoUsuario({
      racha: 1,
      ultima_actividad: haceDias(1),
      racha_recuperable: 8,
      racha_recuperable_expira: new Date(ayer.getFullYear(), ayer.getMonth(), ayer.getDate(), 23, 59, 59),
    });
    registrarActividad(u);
    expect(u.racha_recuperable).toBe(0);
    expect(u.racha).toBe(2); // ayer tenía 1, hoy suma
  });
});

describe('reanudarRacha', () => {
  const mesActual = new Date().toISOString().slice(0, 7);

  function usuarioConRachaPerdida(usadas = 0) {
    const finDeHoy = new Date();
    finDeHoy.setHours(23, 59, 59, 999);
    return nuevoUsuario({
      racha: 1,
      racha_recuperable: 7,
      racha_recuperable_expira: finDeHoy,
      reanudaciones: { mes: mesActual, usadas },
    });
  }

  test('reanuda la racha: acumulado anterior + el día de hoy', () => {
    const u = usuarioConRachaPerdida();
    const r = reanudarRacha(u);
    expect(r.ok).toBe(true);
    expect(u.racha).toBe(8); // 7 + hoy
    expect(u.racha_recuperable).toBe(0);
    expect(u.reanudaciones.usadas).toBe(1);
  });

  test('falla si no hay racha recuperable', () => {
    const u = nuevoUsuario();
    const r = reanudarRacha(u);
    expect(r.ok).toBe(false);
  });

  test('falla a la cuarta reanudación del mes', () => {
    const u = usuarioConRachaPerdida(3);
    const r = reanudarRacha(u);
    expect(r.ok).toBe(false);
    expect(r.mensaje).toMatch(/3 reanudaciones/);
  });

  test('el contador mensual se reinicia al cambiar de mes', () => {
    const u = usuarioConRachaPerdida(3);
    u.reanudaciones.mes = '2020-01'; // mes viejo
    const r = reanudarRacha(u);
    expect(r.ok).toBe(true);
    expect(u.reanudaciones.mes).toBe(mesActual);
    expect(u.reanudaciones.usadas).toBe(1);
  });

  test('falla si la ventana de reanudación ya venció', () => {
    const u = usuarioConRachaPerdida();
    u.racha_recuperable_expira = haceDias(1);
    const r = reanudarRacha(u);
    expect(r.ok).toBe(false);
    expect(u.racha_recuperable).toBe(0);
  });
});
