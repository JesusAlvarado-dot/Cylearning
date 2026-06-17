const mongoose = require('mongoose');
const environment = require('./config/environment');
const { connectDB, disconnectDB } = require('./config/database');
const User = require('./models/User');
const Level = require('./models/Level');
const Topic = require('./models/Topic');
const Lesson = require('./models/Lesson');
const Exercise = require('./models/Exercise');

// Datos de seed
const seedData = async () => {
  try {
    await connectDB();
    console.log('Conectado a MongoDB');

    // Limpiar colecciones
    console.log('Limpiando colecciones...');
    await User.deleteMany({});
    await Level.deleteMany({});
    await Topic.deleteMany({});
    await Lesson.deleteMany({});
    await Exercise.deleteMany({});

    // ============ CREAR ADMIN ============
    const admin = await User.create({
      nombre: 'Administrador CyLearn',
      email: 'admin@cylearn.com',
      contrasena: 'Admin123!',
      rol: 'admin',
    });
    console.log('✅ Admin creado:', admin.email);

    // ============ CREAR ESTUDIANTE DE PRUEBA ============
    const estudiante = await User.create({
      nombre: 'Juan Estudiante',
      email: 'estudiante@cylearn.com',
      contrasena: 'Student123!',
      rol: 'student',
    });
    console.log('✅ Estudiante creado:', estudiante.email);

    // ============ NIVEL 1: PRINCIPIANTE ============
    const nivel1 = await Level.create({
      nombre: 'Nivel 1: Principiante',
      descripcion: 'Aprende los conceptos básicos de ciberseguridad',
      numero: 1,
      dificultad: 'principiante',
      orden: 1,
    });
    console.log('✅ Nivel 1 creado');

    // Tema 1.1: Contraseñas Seguras
    const tema1_1 = await Topic.create({
      nombre: 'Contraseñas Seguras',
      descripcion: 'Aprende a crear contraseñas fuertes y proteger tus cuentas',
      nivel_id: nivel1._id,
      orden: 1,
    });

    const leccion1_1_1 = await Lesson.create({
      nombre: 'Qué es una Contraseña Segura',
      descripcion: 'Descubre los elementos clave para una contraseña fuerte',
      tema_id: tema1_1._id,
      contenido: 'Una contraseña segura tiene: mayúsculas, minúsculas, números y caracteres especiales. Mínimo 8 caracteres.',
      orden: 1,
    });

    await Exercise.create({
      pregunta: '¿Cuál de estas es la contraseña más segura?',
      tipo: 'seleccion_unica',
      opciones: ['abc123', 'MyP@ssw0rd!', '12345678', 'password'],
      respuesta_correcta: 'MyP@ssw0rd!',
      explicacion: 'Una buena contraseña mezcla mayúsculas, minúsculas, números y símbolos especiales.',
      puntos: 10,
      leccion_id: leccion1_1_1._id,
      creado_por: admin._id,
      orden: 1,
    });

    await Exercise.create({
      pregunta: '¿Cuántos caracteres mínimos debe tener una contraseña segura?',
      tipo: 'completar',
      opciones: [],
      respuesta_correcta: '8',
      explicacion: 'Se recomienda mínimo 8 caracteres, aunque más es siempre mejor.',
      puntos: 10,
      leccion_id: leccion1_1_1._id,
      creado_por: admin._id,
      orden: 2,
    });

    const leccion1_1_2 = await Lesson.create({
      nombre: 'Errores Comunes en Contraseñas',
      descripcion: 'Conoce qué NO debes hacer con tus contraseñas',
      tema_id: tema1_1._id,
      contenido: 'Evita: usar tu nombre, fechas de nacimiento, palabras del diccionario, patrones numéricos.',
      orden: 2,
    });

    await Exercise.create({
      pregunta: '¿Es seguro usar tu fecha de nacimiento en la contraseña?',
      tipo: 'verdadero_falso',
      opciones: ['verdadero', 'falso'],
      respuesta_correcta: 'falso',
      explicacion: 'Nunca uses información personal como fechas de nacimiento o nombres en contraseñas.',
      puntos: 10,
      leccion_id: leccion1_1_2._id,
      creado_por: admin._id,
      orden: 1,
    });

    // Tema 1.2: Identificar Phishing
    const tema1_2 = await Topic.create({
      nombre: 'Identificar Phishing',
      descripcion: 'Aprende a detectar emails y sitios maliciosos',
      nivel_id: nivel1._id,
      orden: 2,
    });

    const leccion1_2_1 = await Lesson.create({
      nombre: '¿Qué es Phishing?',
      descripcion: 'Entiende este tipo de ataque digital',
      tema_id: tema1_2._id,
      contenido: 'Phishing es un ataque donde alguien intenta robarte información haciéndose pasar por una empresa o persona de confianza.',
      orden: 1,
    });

    await Exercise.create({
      pregunta: 'Un email dice que tu cuenta fue comprometida y te pide que hagas clic en un enlace. ¿Qué haces?',
      tipo: 'seleccion_unica',
      opciones: [
        'Hago clic inmediatamente',
        'Le pregunto a mis padres y verifico en el sitio oficial',
        'Ignoro el email',
        'Comparto el enlace con amigos'
      ],
      respuesta_correcta: 'Le pregunto a mis padres y verifico en el sitio oficial',
      explicacion: 'Siempre verifica directamente en el sitio oficial, no hagas clic en enlaces de emails sospechosos.',
      puntos: 15,
      leccion_id: leccion1_2_1._id,
      creado_por: admin._id,
      orden: 1,
    });

    // Tema 1.3: Privacidad Online
    const tema1_3 = await Topic.create({
      nombre: 'Privacidad en Internet',
      descripcion: 'Protege tu información personal en redes sociales',
      nivel_id: nivel1._id,
      orden: 3,
    });

    const leccion1_3_1 = await Lesson.create({
      nombre: 'Qué NO Compartir Online',
      descripcion: 'Información que nunca debes publicar en internet',
      tema_id: tema1_3._id,
      contenido: 'NUNCA compartas: dirección completa, número de teléfono, número de documento, contraseñas, información bancaria.',
      orden: 1,
    });

    await Exercise.create({
      pregunta: '¿Cuál de estos datos es SEGURO compartir en redes sociales?',
      tipo: 'seleccion_unica',
      opciones: [
        'Tu número de identificación',
        'Tu número telefónico',
        'Una foto tuya con tus amigos',
        'Tu contraseña'
      ],
      respuesta_correcta: 'Una foto tuya con tus amigos',
      explicacion: 'Las fotos públicas están bien, pero nunca compartas documentos, números de contacto privados o contraseñas.',
      puntos: 10,
      leccion_id: leccion1_3_1._id,
      creado_por: admin._id,
      orden: 1,
    });

    // ============ NIVEL 2: INTERMEDIO ============
    const nivel2 = await Level.create({
      nombre: 'Nivel 2: Intermedio',
      descripcion: 'Profundiza en conceptos avanzados de seguridad digital',
      numero: 2,
      dificultad: 'intermedio',
      orden: 2,
    });
    console.log('✅ Nivel 2 creado');

    // Tema 2.1: Malware y Virus
    const tema2_1 = await Topic.create({
      nombre: 'Malware y Virus',
      descripcion: 'Entiende los tipos de amenazas digitales',
      nivel_id: nivel2._id,
      orden: 1,
    });

    const leccion2_1_1 = await Lesson.create({
      nombre: 'Tipos de Malware',
      descripcion: 'Conoce los diferentes tipos de software malicioso',
      tema_id: tema2_1._id,
      contenido: 'Tipos: Virus, Gusano, Troyano, Ransomware, Spyware, Adware.',
      orden: 1,
    });

    await Exercise.create({
      pregunta: 'Un programa que se copia a sí mismo y se propaga a otros archivos es un:',
      tipo: 'seleccion_unica',
      opciones: ['Virus', 'Troyano', 'Spam', 'Cookies'],
      respuesta_correcta: 'Virus',
      explicacion: 'Los virus se replican modificando otros archivos. Los troyanos se hacen pasar por programas legítimos.',
      puntos: 15,
      leccion_id: leccion2_1_1._id,
      creado_por: admin._id,
      orden: 1,
    });

    // Tema 2.2: Autenticación Doble (2FA)
    const tema2_2 = await Topic.create({
      nombre: 'Autenticación Doble (2FA)',
      descripcion: 'Protege tus cuentas con dos capas de seguridad',
      nivel_id: nivel2._id,
      orden: 2,
    });

    const leccion2_2_1 = await Lesson.create({
      nombre: '¿Qué es 2FA?',
      descripcion: 'Aprende cómo funcionan dos factores de autenticación',
      tema_id: tema2_2._id,
      contenido: '2FA requiere: algo que sabes (contraseña) + algo que tienes (teléfono, llave de seguridad).',
      orden: 1,
    });

    await Exercise.create({
      pregunta: 'La autenticación de dos factores es más segura que solo contraseña porque:',
      tipo: 'seleccion_unica',
      opciones: [
        'Usa contraseñas más largas',
        'Requiere dos formas diferentes de verificar tu identidad',
        'No es necesaria una contraseña',
        'Es más rápida'
      ],
      respuesta_correcta: 'Requiere dos formas diferentes de verificar tu identidad',
      explicacion: 'Incluso si alguien roba tu contraseña, no puede entrar sin acceso al segundo factor (como tu teléfono).',
      puntos: 15,
      leccion_id: leccion2_2_1._id,
      creado_por: admin._id,
      orden: 1,
    });

    // ============ NIVEL 3: AVANZADO ============
    const nivel3 = await Level.create({
      nombre: 'Nivel 3: Avanzado',
      descripcion: 'Domina temas avanzados de ciberseguridad',
      numero: 3,
      dificultad: 'avanzado',
      orden: 3,
    });
    console.log('✅ Nivel 3 creado');

    // Tema 3.1: Criptografía Básica
    const tema3_1 = await Topic.create({
      nombre: 'Criptografía Básica',
      descripcion: 'Entiende cómo se encriptan los datos',
      nivel_id: nivel3._id,
      orden: 1,
    });

    const leccion3_1_1 = await Lesson.create({
      nombre: 'Cifrado Simétrico vs Asimétrico',
      descripcion: 'Conoce los dos tipos principales de encriptación',
      tema_id: tema3_1._id,
      contenido: 'Simétrico: usa 1 clave. Asimétrico: usa 2 claves (pública y privada).',
      orden: 1,
    });

    await Exercise.create({
      pregunta: 'En criptografía asimétrica, ¿cuántas claves se usan?',
      tipo: 'completar',
      opciones: [],
      respuesta_correcta: '2',
      explicacion: 'Se usan dos claves: una pública (que todos pueden ver) y una privada (que solo tú tienes).',
      puntos: 20,
      leccion_id: leccion3_1_1._id,
      creado_por: admin._id,
      orden: 1,
    });

    // Tema 3.2: HTTPS y Certificados
    const tema3_2 = await Topic.create({
      nombre: 'HTTPS y Certificados',
      descripcion: 'Aprende a identificar sitios web seguros',
      nivel_id: nivel3._id,
      orden: 2,
    });

    const leccion3_2_1 = await Lesson.create({
      nombre: '¿Qué es HTTPS?',
      descripcion: 'Entiende la diferencia entre HTTP y HTTPS',
      tema_id: tema3_2._id,
      contenido: 'HTTP es inseguro. HTTPS encripta la comunicación. Busca el candado 🔒 en el navegador.',
      orden: 1,
    });

    await Exercise.create({
      pregunta: '¿Verdadero o Falso? HTTPS encripta la comunicación entre tu navegador y el servidor',
      tipo: 'verdadero_falso',
      opciones: ['verdadero', 'falso'],
      respuesta_correcta: 'verdadero',
      explicacion: 'Correcto. HTTPS (Hypertext Transfer Protocol Secure) usa encriptación SSL/TLS para proteger tus datos.',
      puntos: 15,
      leccion_id: leccion3_2_1._id,
      creado_por: admin._id,
      orden: 1,
    });

    console.log('\n✅ ¡SEED COMPLETADO EXITOSAMENTE!');
    console.log('\n📊 Datos creados:');
    console.log('   - 1 Admin: admin@cylearn.com / Admin123!');
    console.log('   - 1 Estudiante: estudiante@cylearn.com / Student123!');
    console.log('   - 3 Niveles de dificultad');
    console.log('   - 8 Temas');
    console.log('   - 12 Lecciones');
    console.log('   - 15 Ejercicios');

    await disconnectDB();
  } catch (error) {
    console.error('❌ Error al hacer seed:', error.message);
    await disconnectDB();
    process.exit(1);
  }
};

seedData();
