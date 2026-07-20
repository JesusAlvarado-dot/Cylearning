/**
 * Tests de integración del API de CyLearn.
 * Usa la base de datos `cylearn_test` (separada de la de desarrollo)
 * en el mismo servidor/cluster de MongoDB.
 */
process.env.NODE_ENV = 'test';
require('dotenv').config();

// Derivar la URI de test insertando un nombre de base de datos propio
const baseUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/cylearn';
process.env.MONGODB_TEST_URI = baseUri.includes('mongodb.net/?')
  ? baseUri.replace('mongodb.net/?', 'mongodb.net/cylearn_test?')
  : 'mongodb://localhost:27017/cylearn_test';

const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../app');
const { connectDB } = require('../config/database');
const User = require('../models/User');

jest.setTimeout(60000);

let adminToken;
let studentToken;
let studentId;

// IDs del contenido creado durante los tests
let nivelId, temaId, leccionId, ejercicioId;

beforeAll(async () => {
  await connectDB();
  await mongoose.connection.dropDatabase();

  // El registro público fuerza rol student: el admin se crea directo en la BD
  await User.create({
    nombre: 'Admin Test',
    email: 'admin@test.com',
    contrasena: 'Admin123!',
    rol: 'admin',
  });

  const login = await request(app)
    .post('/api/auth/login')
    .send({ email: 'admin@test.com', contrasena: 'Admin123!' });
  adminToken = login.body.datos.token;
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
});

const asAdmin = (req) => req.set('Authorization', `Bearer ${adminToken}`);
const asStudent = (req) => req.set('Authorization', `Bearer ${studentToken}`);

describe('Autenticación', () => {
  test('registro crea estudiante y fuerza rol student aunque se envíe admin', async () => {
    const res = await request(app).post('/api/auth/registro').send({
      nombre: 'Estudiante Test',
      email: 'est@test.com',
      contrasena: 'abc123',
      rol: 'admin', // intento de escalado
    });
    expect(res.status).toBe(201);
    expect(res.body.datos.usuario.rol).toBe('student');
    expect(res.body.datos.usuario.contrasena).toBeUndefined();
    studentToken = res.body.datos.token;
    studentId = res.body.datos.usuario._id;
  });

  test('login con credenciales incorrectas responde 401', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'est@test.com', contrasena: 'incorrecta' });
    expect(res.status).toBe(401);
  });

  test('inyección NoSQL en login responde 400', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: { $gt: '' }, contrasena: { $gt: '' } });
    expect(res.status).toBe(400);
  });

  test('ruta protegida sin token responde 401', async () => {
    const res = await request(app).get('/api/auth/me');
    expect(res.status).toBe(401);
  });
});

describe('Permisos', () => {
  test('estudiante no puede acceder a rutas admin', async () => {
    const res = await asStudent(request(app).get('/api/admin/usuarios'));
    expect(res.status).toBe(403);
  });

  test('admin puede crear/editar/eliminar usuarios', async () => {
    const crear = await asAdmin(request(app).post('/api/admin/usuarios')).send({
      nombre: 'Usuario Temporal',
      email: 'temp@test.com',
      contrasena: 'abc123',
      rol: 'student',
    });
    expect(crear.status).toBe(201);
    const id = crear.body.datos._id;

    const editar = await asAdmin(
      request(app).put(`/api/admin/usuarios/${id}`)
    ).send({ nombre: 'Usuario Editado' });
    expect(editar.status).toBe(200);
    expect(editar.body.datos.nombre).toBe('Usuario Editado');

    const borrar = await asAdmin(request(app).delete(`/api/admin/usuarios/${id}`));
    expect(borrar.status).toBe(200);
  });
});

describe('Contenido (admin)', () => {
  test('crear nivel → tema → lección → ejercicio', async () => {
    const nivel = await asAdmin(request(app).post('/api/admin/niveles')).send({
      nombre: 'Nivel Test',
      descripcion: 'desc',
      numero: 1,
      orden: 1,
    });
    expect(nivel.status).toBe(201);
    nivelId = nivel.body.datos._id;

    const tema = await asAdmin(request(app).post('/api/admin/temas')).send({
      nombre: 'Tema Test',
      descripcion: 'desc',
      nivel_id: nivelId,
      orden: 1,
    });
    expect(tema.status).toBe(201);
    temaId = tema.body.datos._id;

    const leccion = await asAdmin(request(app).post('/api/admin/lecciones')).send({
      nombre: 'Leccion Test',
      descripcion: 'desc',
      contenido: 'contenido de prueba',
      tema_id: temaId,
    });
    expect(leccion.status).toBe(201);
    leccionId = leccion.body.datos._id;

    const ejercicio = await asAdmin(request(app).post('/api/admin/ejercicios')).send({
      pregunta: '¿Cuál es una contraseña segura?',
      tipo: 'seleccion_unica',
      opciones: ['123456', 'X9$k2!pQ'],
      respuesta_correcta: 'X9$k2!pQ',
      explicacion: 'Las contraseñas seguras mezclan símbolos y letras',
      puntos: 10,
      leccion_id: leccionId,
    });
    expect(ejercicio.status).toBe(201);
    ejercicioId = ejercicio.body.datos._id;
  });

  test('crear ejercicio con tipo inválido responde 400', async () => {
    const res = await asAdmin(request(app).post('/api/admin/ejercicios')).send({
      pregunta: 'Pregunta inválida de tipo',
      tipo: 'tipo_falso',
      opciones: ['a'],
      respuesta_correcta: 'a',
      leccion_id: leccionId,
    });
    expect(res.status).toBe(400);
  });

  test('niveles para estudiante incluyen lecciones y total_lecciones', async () => {
    const res = await asStudent(request(app).get('/api/student/niveles?limite=100'));
    expect(res.status).toBe(200);
    const nivel = res.body.datos.datos.find((n) => n._id === nivelId);
    expect(nivel.total_lecciones).toBe(1);
    expect(nivel.lecciones).toContain(leccionId);
  });
});

describe('Calificación en el servidor', () => {
  test('el estudiante NO recibe respuesta_correcta ni explicacion', async () => {
    const res = await asStudent(
      request(app).get(`/api/student/lecciones/${leccionId}/iniciar`)
    );
    expect(res.status).toBe(200);
    for (const e of res.body.datos.ejercicios) {
      expect(e.respuesta_correcta).toBeUndefined();
      expect(e.explicacion).toBeUndefined();
    }
  });

  test('el admin SÍ recibe respuesta_correcta', async () => {
    const res = await asAdmin(
      request(app).get(`/api/admin/ejercicios/${ejercicioId}`)
    );
    expect(res.body.datos.respuesta_correcta).toBe('X9$k2!pQ');
  });

  test('completar lección sin responder es rechazado aunque el cliente mienta', async () => {
    const res = await asStudent(
      request(app).post(`/api/student/lecciones/${leccionId}/completar`)
    ).send({ porcentaje: 100 });
    expect(res.status).toBe(200);
    expect(res.body.datos.desbloqueado).toBe(false);
    expect(res.body.datos.porcentaje).toBe(0);
  });

  test('responder mal devuelve esCorrecta=false con la respuesta correcta', async () => {
    const res = await asStudent(
      request(app).post(`/api/student/ejercicios/${ejercicioId}/responder`)
    ).send({ respuesta: '123456' });
    expect(res.status).toBe(200);
    expect(res.body.datos.esCorrecta).toBe(false);
    expect(res.body.datos.respuesta_correcta).toBe('X9$k2!pQ');
  });

  test('responder con número no crashea', async () => {
    const res = await asStudent(
      request(app).post(`/api/student/ejercicios/${ejercicioId}/responder`)
    ).send({ respuesta: 42 });
    expect(res.status).toBe(200);
    expect(res.body.datos.esCorrecta).toBe(false);
  });

  test('responder bien y completar otorga puntos acotados (una sola vez)', async () => {
    const ok = await asStudent(
      request(app).post(`/api/student/ejercicios/${ejercicioId}/responder`)
    ).send({ respuesta: 'X9$k2!pQ' });
    expect(ok.body.datos.esCorrecta).toBe(true);

    const completar = await asStudent(
      request(app).post(`/api/student/lecciones/${leccionId}/completar`)
    ).send({ porcentaje: 99999 }); // el servidor lo ignora
    expect(completar.body.datos.desbloqueado).toBe(true);
    expect(completar.body.datos.porcentaje).toBe(100);
    expect(completar.body.datos.puntos_ganados).toBeLessThanOrEqual(100);

    // Repetir no da puntos de nuevo
    const repetir = await asStudent(
      request(app).post(`/api/student/lecciones/${leccionId}/completar`)
    ).send({});
    expect(repetir.body.datos.puntos_ganados).toBe(0);
  });

  test('completar lección inexistente responde 404', async () => {
    const res = await asStudent(
      request(app).post('/api/student/lecciones/aaaaaaaaaaaaaaaaaaaaaaaa/completar')
    ).send({ porcentaje: 100 });
    expect(res.status).toBe(404);
  });
});

describe('Perfil', () => {
  test('actualizar nombre y contraseña propios', async () => {
    const res = await asStudent(request(app).put('/api/student/perfil')).send({
      nombre: 'Nombre Nuevo',
      contrasena: 'nueva123',
    });
    expect(res.status).toBe(200);
    expect(res.body.datos.nombre).toBe('Nombre Nuevo');

    // La contraseña nueva funciona para login
    const login = await request(app)
      .post('/api/auth/login')
      .send({ email: 'est@test.com', contrasena: 'nueva123' });
    expect(login.status).toBe(200);
  });

  test('contraseña corta es rechazada', async () => {
    const res = await asStudent(request(app).put('/api/student/perfil')).send({
      contrasena: '123',
    });
    expect(res.status).toBe(400);
  });
});

describe('Borrado en cascada', () => {
  test('eliminar nivel borra temas, lecciones, ejercicios y limpia progreso', async () => {
    const res = await asAdmin(request(app).delete(`/api/admin/niveles/${nivelId}`));
    expect(res.status).toBe(200);
    expect(res.body.datos.temas_eliminados).toBe(1);
    expect(res.body.datos.lecciones_eliminadas).toBe(1);
    expect(res.body.datos.ejercicios_eliminados).toBe(1);

    const tema = await asAdmin(request(app).get(`/api/admin/temas/${temaId}`));
    expect(tema.status).toBe(404);
    const leccion = await asAdmin(request(app).get(`/api/admin/lecciones/${leccionId}`));
    expect(leccion.status).toBe(404);
    const ejercicio = await asAdmin(request(app).get(`/api/admin/ejercicios/${ejercicioId}`));
    expect(ejercicio.status).toBe(404);

    // El progreso del estudiante ya no referencia lo borrado
    const resumen = await asStudent(request(app).get('/api/student/progreso/resumen'));
    expect(resumen.body.datos.lecciones_completadas).not.toContain(leccionId);
    expect(resumen.body.datos.niveles_completados).not.toContain(nivelId);
  });
});

describe('Logs', () => {
  test('limpiar logs con dias negativo es rechazado', async () => {
    const res = await asAdmin(request(app).post('/api/admin/logs/limpiar')).send({
      dias: -5,
    });
    expect(res.status).toBe(400);
  });
});
