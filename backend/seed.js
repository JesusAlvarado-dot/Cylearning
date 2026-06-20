const environment = require('./config/environment');
const { connectDB, disconnectDB } = require('./config/database');
const mongoose = require('mongoose');
const User     = require('./models/User');
const Level    = require('./models/Level');
const Topic    = require('./models/Topic');
const Lesson   = require('./models/Lesson');
const Exercise = require('./models/Exercise');
const Progreso = require('./models/Progreso');

// ──────────────────────────────────────────────────────────────────────────────
// Contenido: 3 niveles × 3 temas × 1 lección × 3 ejercicios (seleccion_unica)
// ──────────────────────────────────────────────────────────────────────────────
const NIVELES = [
  {
    nombre: 'Contraseñas Seguras',
    descripcion: 'Aprende a crear y proteger tus contraseñas para mantener tus cuentas seguras.',
    numero: 1, orden: 1, dificultad: 'principiante',
    temas: [
      {
        nombre: '¿Qué es una contraseña?',
        descripcion: 'Descubre para qué sirven las contraseñas y por qué son tan importantes.',
        orden: 1,
        leccion: {
          nombre: 'Conoce las Contraseñas',
          descripcion: 'Aprende qué es una contraseña y por qué debes protegerla.',
          contenido: `Una contraseña es un código secreto que solo tú debes conocer. Sirve para proteger tus cuentas y tu información personal en internet.

🔑 ¿Por qué son importantes?
Sin contraseña, cualquier persona podría acceder a tu cuenta, leer tus mensajes o hacerse pasar por ti.

⚠️ Recuerda siempre:
• Tu contraseña es SOLO tuya
• No debes compartirla con nadie
• Ni siquiera con tu mejor amigo o amiga`,
          orden: 1,
          ejercicios: [
            {
              pregunta: '¿Para qué sirve una contraseña?',
              opciones: ['Para decorar tu perfil','Para proteger tu información personal','Para hacer más amigos','Para que internet sea más rápido'],
              respuesta_correcta: 'Para proteger tu información personal',
              explicacion: 'Una contraseña protege tus cuentas e información personal.',
            },
            {
              pregunta: '¿A quién debes decirle tu contraseña?',
              opciones: ['A tus mejores amigos','A tu maestra o maestro','A nadie, es solo tuya','A todos en tu clase'],
              respuesta_correcta: 'A nadie, es solo tuya',
              explicacion: 'Tu contraseña es completamente privada. Nunca la compartas con nadie.',
            },
            {
              pregunta: '¿Qué puede pasar si alguien descubre tu contraseña?',
              opciones: ['Nada malo','Tu internet se vuelve más lento','Puede acceder a tus cuentas y robar tu información','Tus fotos se borran solas'],
              respuesta_correcta: 'Puede acceder a tus cuentas y robar tu información',
              explicacion: 'Si alguien obtiene tu contraseña, puede entrar a tus cuentas y robar tu información personal.',
            },
          ],
        },
      },
      {
        nombre: 'Crea Contraseñas Fuertes',
        descripcion: 'Aprende a crear contraseñas difíciles de adivinar.',
        orden: 2,
        leccion: {
          nombre: 'Contraseñas Difíciles de Adivinar',
          descripcion: 'Conoce las reglas para crear contraseñas seguras y fuertes.',
          contenido: `Una contraseña fuerte es como un escudo difícil de romper. Para crearla debes mezclar varios tipos de caracteres.

✅ Una contraseña fuerte usa:
• Al menos 8 caracteres
• Letras mayúsculas (A, B, C)
• Letras minúsculas (a, b, c)
• Números (1, 2, 3)
• Símbolos (!, @, #)

❌ Nunca uses:
• Tu nombre o apellido
• Tu fecha de nacimiento
• Palabras simples como "password" o "123456"

💡 Truco: Frase → iniciales → contraseña
"Mi perro Fido tiene 3 años!" → MpFt3a!`,
          orden: 1,
          ejercicios: [
            {
              pregunta: '¿Cuál de estas contraseñas es la más segura?',
              opciones: ['123456','miperro','M1P3rr0!Seguro','nombre2024'],
              respuesta_correcta: 'M1P3rr0!Seguro',
              explicacion: '"M1P3rr0!Seguro" usa mayúsculas, minúsculas, números y símbolos.',
            },
            {
              pregunta: '¿Cuántos caracteres debe tener mínimo una contraseña segura?',
              opciones: ['2 caracteres','4 caracteres','6 caracteres','8 o más caracteres'],
              respuesta_correcta: '8 o más caracteres',
              explicacion: 'Los expertos recomiendan contraseñas de al menos 8 caracteres.',
            },
            {
              pregunta: '¿Qué NO debes usar en tu contraseña?',
              opciones: ['Números y símbolos','Letras mayúsculas y minúsculas','Tu fecha de nacimiento','Combinaciones raras de caracteres'],
              respuesta_correcta: 'Tu fecha de nacimiento',
              explicacion: 'Tu fecha de nacimiento es información que otros pueden conocer fácilmente.',
            },
          ],
        },
      },
      {
        nombre: 'Protege tu Contraseña',
        descripcion: 'Hábitos para mantener tus contraseñas seguras.',
        orden: 3,
        leccion: {
          nombre: 'Hábitos de Seguridad',
          descripcion: 'Aprende los mejores hábitos para proteger tus contraseñas.',
          contenido: `Tener una buena contraseña no es suficiente si no la proteges bien.

🔒 Las 5 reglas de oro:
1. NUNCA compartas tu contraseña con nadie
2. Cámbiala regularmente (cada 3-6 meses)
3. Usa contraseñas DIFERENTES para cada cuenta
4. No la escribas en papeles visibles
5. Si crees que alguien la descubrió, ¡cámbiala de inmediato!

💡 ¿Olvidaste tu contraseña?
Los sitios seguros te enviarán un enlace a tu correo para crear una nueva.`,
          orden: 1,
          ejercicios: [
            {
              pregunta: 'Tu amigo te pide tu contraseña para ayudarte. ¿Qué haces?',
              opciones: ['Se la doy porque es mi mejor amigo','Le digo que no, nunca comparto mi contraseña','Se la susurro para que no escuchen otros','La escribo en un papel'],
              respuesta_correcta: 'Le digo que no, nunca comparto mi contraseña',
              explicacion: 'Nunca debes compartir tu contraseña con nadie, ni siquiera con tus mejores amigos.',
            },
            {
              pregunta: '¿Está bien usar la misma contraseña para todas tus cuentas?',
              opciones: ['Sí, así es más fácil recordarla','Sí, mientras sea una contraseña larga','No, porque si la descubren acceden a todo','No importa si cambias el nombre de usuario'],
              respuesta_correcta: 'No, porque si la descubren acceden a todo',
              explicacion: 'Usar la misma contraseña en todas partes es muy peligroso.',
            },
            {
              pregunta: '¿Qué debes hacer si crees que alguien descubrió tu contraseña?',
              opciones: ['Nada, esperar a ver qué pasa','Contárselo a todos tus amigos','Cambiarla inmediatamente','Borrar toda tu información'],
              respuesta_correcta: 'Cambiarla inmediatamente',
              explicacion: 'Si sospechas que alguien conoce tu contraseña, cámbiala de inmediato.',
            },
          ],
        },
      },
    ],
  },
  {
    nombre: 'Navegación Segura en Internet',
    descripcion: 'Identifica sitios seguros y protégete de los peligros en línea.',
    numero: 2, orden: 2, dificultad: 'intermedio',
    temas: [
      {
        nombre: 'Sitios Web Seguros',
        descripcion: 'Aprende a reconocer los sitios web de confianza.',
        orden: 1,
        leccion: {
          nombre: 'Reconoce los Sitios Seguros',
          descripcion: 'Descubre cómo identificar si un sitio web es seguro.',
          contenido: `No todos los sitios web son seguros. Algunos pueden robar tu información.

🔒 La señal más importante: el candado
En la barra del navegador busca el ícono 🔒. Significa que la conexión está protegida.

🌐 Revisa la dirección web:
• Sitios seguros comienzan con "https://" (la 's' es de 'seguro')
• Si dice solo "http://" sin la 's', ten mucho cuidado

⚠️ Señales de peligro:
• Te prometen premios o dinero gratis
• Tienen muchos anuncios que aparecen solos
• Tu navegador te advierte que es peligroso

💡 Regla de oro: Si algo parece demasiado bueno para ser verdad, probablemente es una trampa.`,
          orden: 1,
          ejercicios: [
            {
              pregunta: '¿Cómo identificas que un sitio web es seguro?',
              opciones: ['Tiene muchas imágenes bonitas','Tiene el candado 🔒 y comienza con "https://"','Carga muy rápido','Lo conocen todos tus amigos'],
              respuesta_correcta: 'Tiene el candado 🔒 y comienza con "https://"',
              explicacion: 'El candado y el "https://" indican que la conexión está cifrada y es segura.',
            },
            {
              pregunta: '¿Qué significa "https://" en la dirección de un sitio web?',
              opciones: ['Que el sitio es muy popular','Que la conexión está cifrada y es segura','Que el sitio es muy antiguo','Que solo funciona en computadoras'],
              respuesta_correcta: 'Que la conexión está cifrada y es segura',
              explicacion: 'HTTPS significa que la información viaja cifrada, protegiéndola de interceptación.',
            },
            {
              pregunta: 'Recibes: "¡Ganaste un iPhone gratis! Haz clic para reclamarlo". ¿Qué haces?',
              opciones: ['Hago clic inmediatamente','Ignoro el mensaje, probablemente es una trampa','Le cuento a todos mis amigos','Ingreso mis datos para recibir el premio'],
              respuesta_correcta: 'Ignoro el mensaje, probablemente es una trampa',
              explicacion: 'Los mensajes de premios falsos son una trampa para robar tus datos.',
            },
          ],
        },
      },
      {
        nombre: 'Peligros en Línea',
        descripcion: 'Conoce las amenazas digitales y cómo protegerte.',
        orden: 2,
        leccion: {
          nombre: 'Protégete de las Amenazas Digitales',
          descripcion: 'Aprende sobre el phishing, virus y cómo actuar.',
          contenido: `Internet es maravilloso para aprender y comunicarse, pero existen peligros que debes conocer.

🎣 Phishing (Pesca de información):
Son mensajes o sitios FALSOS que imitan sitios reales para robarte tus contraseñas.

🦠 Virus y malware:
Programas dañinos que se esconden en:
• Archivos que descargas de sitios desconocidos
• Correos de personas extrañas
• Programas "gratis" de sitios no oficiales

👻 Identidades falsas:
En internet, las personas NO siempre son quienes dicen ser.

🛡️ Mantente seguro:
• NUNCA abras archivos de desconocidos
• No hagas clic en enlaces sospechosos
• Si algo te parece raro, ¡probablemente lo es!
• Cuéntale a un adulto si algo te preocupa`,
          orden: 1,
          ejercicios: [
            {
              pregunta: '¿Qué es el "phishing"?',
              opciones: ['Un juego de pesca en línea','Un engaño para robarte información con mensajes o sitios falsos','Un tipo de virus muy famoso','Una red social nueva'],
              respuesta_correcta: 'Un engaño para robarte información con mensajes o sitios falsos',
              explicacion: 'El phishing usa mensajes y sitios falsos para engañarte y robarte tus contraseñas.',
            },
            {
              pregunta: 'Recibes un correo con un archivo adjunto de alguien que no conoces. ¿Qué haces?',
              opciones: ['Lo abro para ver qué contiene','Solo lo abro si el nombre parece interesante','No lo abro y se lo cuento a un adulto de confianza','Lo reenvío a todos mis amigos'],
              respuesta_correcta: 'No lo abro y se lo cuento a un adulto de confianza',
              explicacion: 'Los archivos de desconocidos pueden contener virus. Avisa a un adulto cuando recibas mensajes sospechosos.',
            },
            {
              pregunta: 'En un juego en línea, alguien dice ser de tu edad y te pide tu dirección. ¿Qué haces?',
              opciones: ['Se la doy porque somos del mismo juego','Se la doy solo si me muestra su foto','No le doy ninguna información personal y aviso a un adulto','Le doy solo el nombre de mi calle'],
              respuesta_correcta: 'No le doy ninguna información personal y aviso a un adulto',
              explicacion: 'En internet nunca sabes con certeza quién está del otro lado. Nunca compartas información personal.',
            },
          ],
        },
      },
      {
        nombre: 'Redes WiFi Seguras',
        descripcion: 'Aprende a usar el WiFi de forma segura.',
        orden: 3,
        leccion: {
          nombre: 'Cuida tu Conexión a Internet',
          descripcion: 'Descubre los riesgos del WiFi público.',
          contenido: `No todas las redes WiFi son seguras. El WiFi público puede poner en riesgo tu información.

📶 Tipos de redes WiFi:
✅ Red privada (tu casa): tiene contraseña, solo personas de confianza. ¡SEGURA!
⚠️ Red pública (café, parque): cualquiera puede conectarse. ¡CUIDADO!

🚨 En WiFi público alguien puede:
• Ver qué sitios estás visitando
• Interceptar tus contraseñas
• Robar tu información

💡 Reglas para WiFi público:
1. NUNCA ingreses contraseñas o datos bancarios
2. No hagas compras en línea
3. Solo úsalo para información general`,
          orden: 1,
          ejercicios: [
            {
              pregunta: '¿Cuál red WiFi es más segura para ingresar tu contraseña?',
              opciones: ['La WiFi gratuita del parque','La WiFi gratis del aeropuerto','La WiFi de tu casa con contraseña','Cualquier red con buena señal'],
              respuesta_correcta: 'La WiFi de tu casa con contraseña',
              explicacion: 'La WiFi de tu casa solo la usan personas de confianza, lo que la hace mucho más segura.',
            },
            {
              pregunta: 'Estás en una cafetería usando el WiFi gratuito. ¿Qué NO debes hacer?',
              opciones: ['Buscar información para una tarea','Ingresar tu contraseña o datos bancarios','Ver videos de YouTube','Revisar el pronóstico del clima'],
              respuesta_correcta: 'Ingresar tu contraseña o datos bancarios',
              explicacion: 'En redes WiFi públicas nunca debes ingresar contraseñas ni datos sensibles.',
            },
            {
              pregunta: '¿Por qué el WiFi público puede ser peligroso?',
              opciones: ['Porque es más lento que el WiFi de casa','Porque consume más batería','Porque otras personas pueden ver tu actividad e interceptar datos','Porque no funciona con teléfonos'],
              respuesta_correcta: 'Porque otras personas pueden ver tu actividad e interceptar datos',
              explicacion: 'En una red pública, personas malintencionadas pueden espiar tu actividad.',
            },
          ],
        },
      },
    ],
  },
  {
    nombre: 'Redes Sociales Seguras',
    descripcion: 'Usa las redes sociales de manera responsable y protege tu privacidad digital.',
    numero: 3, orden: 3, dificultad: 'avanzado',
    temas: [
      {
        nombre: 'Redes Sociales y Tu Seguridad',
        descripcion: 'Aprende a usar las redes sociales con responsabilidad.',
        orden: 1,
        leccion: {
          nombre: 'Úsalas con Responsabilidad',
          descripcion: 'Conoce los riesgos de las redes sociales y cómo disfrutarlas seguro.',
          contenido: `Las redes sociales son muy divertidas, pero debes usarlas con cuidado.

⚠️ El gran peligro:
No siempre puedes saber quién está realmente al otro lado.

🚫 Información que NUNCA debes publicar:
• Tu dirección de casa o escuela
• Tu número de teléfono
• Tu ubicación en tiempo real
• Fotos que muestren dónde vives
• Tu horario o rutina diaria

✅ Está bien compartir (con privacidad configurada):
• Tu película o canción favorita
• Tus hobbies e intereses generales`,
          orden: 1,
          ejercicios: [
            {
              pregunta: '¿Qué información NUNCA debes publicar en redes sociales?',
              opciones: ['Tu canción favorita','Tu color favorito','Tu dirección de casa y número de teléfono','El nombre de tu equipo favorito'],
              respuesta_correcta: 'Tu dirección de casa y número de teléfono',
              explicacion: 'Tu dirección y teléfono son datos muy peligrosos de compartir en internet.',
            },
            {
              pregunta: '¿Por qué debes tener cuidado con personas desconocidas en redes sociales?',
              opciones: ['Porque no les gusta la misma música','Porque no siempre son quien dicen ser','Porque hablan idiomas diferentes','Porque tienen menos seguidores'],
              respuesta_correcta: 'Porque no siempre son quien dicen ser',
              explicacion: 'En internet, las personas pueden mentir sobre su identidad, edad o intenciones.',
            },
            {
              pregunta: '¿Cuál de estas acciones es la más segura en redes sociales?',
              opciones: ['Publicar tu horario escolar','Compartir tu ubicación en tiempo real','Configurar tu perfil como privado y aceptar solo personas que conoces','Aceptar solicitudes de amistad de todos'],
              respuesta_correcta: 'Configurar tu perfil como privado y aceptar solo personas que conoces',
              explicacion: 'Un perfil privado donde solo aceptas personas que conoces es la forma más segura.',
            },
          ],
        },
      },
      {
        nombre: 'Tu Privacidad Digital',
        descripcion: 'Aprende a controlar quién puede ver tu información en línea.',
        orden: 2,
        leccion: {
          nombre: 'Controla Quién Te Ve',
          descripcion: 'Configura tu privacidad y toma el control de tu información digital.',
          contenido: `Tu privacidad digital es tu derecho. Tú decides qué compartes y con quién.

🔒 Configura tu cuenta como "Privada":
Solo las personas que TÚ aceptes podrán ver tus publicaciones.

👥 Sé selectivo con tus contactos:
• Solo acepta solicitudes de personas que conoces en la vida real
• Si no estás seguro, ¡mejor rechaza!
• Puedes bloquear a alguien si te hace sentir incómodo

🤔 Piensa ANTES de publicar:
Cuando algo se publica en internet, puede quedarse ahí para siempre.
Pregúntate:
1. ¿Estarían orgullosos mis padres si lo vieran?
2. ¿Podría hacerme daño en el futuro?
3. ¿Estoy compartiendo información que me ubica?`,
          orden: 1,
          ejercicios: [
            {
              pregunta: '¿Qué significa tener un perfil "privado" en una red social?',
              opciones: ['Que el perfil es invisible para todos','Que solo las personas que tú apruebas pueden ver tu contenido','Que no puedes publicar fotos','Que el perfil funciona más lento'],
              respuesta_correcta: 'Que solo las personas que tú apruebas pueden ver tu contenido',
              explicacion: 'Un perfil privado significa que controlas quién puede ver tus publicaciones.',
            },
            {
              pregunta: 'Alguien que no conoces te envía una solicitud de amistad. ¿Qué haces?',
              opciones: ['La acepto porque más amigos es mejor','La acepto si tiene foto de perfil','No la acepto y comento con mis padres si me parece extraño','La acepto si vivimos en la misma ciudad'],
              respuesta_correcta: 'No la acepto y comento con mis padres si me parece extraño',
              explicacion: 'Nunca debes aceptar solicitudes de personas que no conoces en la vida real.',
            },
            {
              pregunta: 'Antes de publicar algo en redes sociales, ¿qué debes preguntarte?',
              opciones: ['Si la foto tiene buenos filtros','Cuántos "me gusta" voy a recibir','¿Esta publicación podría afectar mi seguridad o revelar información privada?','Si el texto tiene la longitud correcta'],
              respuesta_correcta: '¿Esta publicación podría afectar mi seguridad o revelar información privada?',
              explicacion: 'Siempre piensa en las consecuencias antes de publicar. En internet la información puede quedarse para siempre.',
            },
          ],
        },
      },
      {
        nombre: 'El Ciberbullying',
        descripcion: 'Aprende a reconocer y detener el acoso en línea.',
        orden: 3,
        leccion: {
          nombre: 'Detén el Ciberbullying',
          descripcion: 'Conoce qué es el ciberbullying y cómo actuar.',
          contenido: `El ciberbullying es cuando alguien usa internet para molestar, amenazar o humillar a otra persona.

💔 ¿Cómo ocurre?
• Enviar mensajes crueles o humillantes
• Publicar fotos vergonzosas de alguien sin permiso
• Excluir a alguien de grupos en línea a propósito
• Difundir rumores o mentiras en internet

🛡️ Si TÚ eres víctima:
1. NO respondas a los mensajes de odio
2. GUARDA las pruebas con capturas de pantalla
3. BLOQUEA a quien te molesta
4. CUÉNTASELO a un adulto de confianza
5. REPORTA el contenido en la plataforma

💪 Si VES que le pasa a alguien más:
• No te rías ni compartas el contenido dañino
• Apoya a la persona afectada, hazle saber que no está sola`,
          orden: 1,
          ejercicios: [
            {
              pregunta: '¿Qué es el ciberbullying?',
              opciones: ['Un videojuego de aventuras muy popular','Acoso o burlas que ocurren a través de internet o dispositivos electrónicos','Una nueva aplicación de redes sociales','Un tipo de virus informático'],
              respuesta_correcta: 'Acoso o burlas que ocurren a través de internet o dispositivos electrónicos',
              explicacion: 'El ciberbullying es el acoso que ocurre en el mundo digital.',
            },
            {
              pregunta: 'Estás siendo víctima de ciberbullying. ¿Qué es lo más importante que debes hacer?',
              opciones: ['Responder con insultos para defenderte','Ignorarlo completamente','Guardar las pruebas y contarle a un adulto de confianza','Borrar todas tus redes sociales'],
              respuesta_correcta: 'Guardar las pruebas y contarle a un adulto de confianza',
              explicacion: 'No te quedes callado. Guarda evidencias y cuéntaselo a un adulto que pueda ayudarte.',
            },
            {
              pregunta: 'Tu compañero está siendo víctima de ciberbullying. ¿Cómo lo ayudas mejor?',
              opciones: ['Comparto los mensajes para que todos sepan','Me río porque no es mi problema','Lo apoyo, le digo que no está solo y lo ayudo a contarle a un adulto','Le digo que deje de usar internet'],
              respuesta_correcta: 'Lo apoyo, le digo que no está solo y lo ayudo a contarle a un adulto',
              explicacion: 'Apoyar a alguien que sufre ciberbullying es muy importante. Hazle saber que no está solo.',
            },
          ],
        },
      },
    ],
  },
];

// ──────────────────────────────────────────────────────────────────────────────
// Seed principal
// ──────────────────────────────────────────────────────────────────────────────
const seedData = async () => {
  try {
    await connectDB();
    console.log('🌱 Conectado a MongoDB\n');

    // Borrar TODA la base de datos para empezar limpio
    console.log('🗑️  Borrando todos los datos existentes...');
    await mongoose.connection.db.dropDatabase();
    console.log('   ✓ Base de datos limpia\n');

    // ── USUARIOS (plain text — el modelo los hashea via pre-save) ───────────
    const admin = await User.create({
      nombre: 'Administrador CyLearn',
      email: 'admin@cylearn.com',
      contrasena: 'Admin123!',
      rol: 'admin',
      puntos_totales: 0,
    });
    console.log('✅ Admin creado:', admin.email, '  contraseña: Admin123!');

    const estudiante = await User.create({
      nombre: 'Juan Estudiante',
      email: 'estudiante@cylearn.com',
      contrasena: 'Student123!',
      rol: 'student',
      puntos_totales: 0,
    });
    console.log('✅ Estudiante creado:', estudiante.email, '  contraseña: Student123!\n');

    // ── NIVELES, TEMAS, LECCIONES, EJERCICIOS ────────────────────────────────
    for (const nivelData of NIVELES) {
      const nivel = await Level.create({
        nombre:      nivelData.nombre,
        descripcion: nivelData.descripcion,
        numero:      nivelData.numero,
        orden:       nivelData.orden,
        dificultad:  nivelData.dificultad,
      });
      console.log(`📚 Nivel ${nivel.numero}: ${nivel.nombre}`);

      for (const temaData of nivelData.temas) {
        const tema = await Topic.create({
          nombre:      temaData.nombre,
          descripcion: temaData.descripcion,
          nivel_id:    nivel._id,
          orden:       temaData.orden,
        });

        const ld = temaData.leccion;
        const leccion = await Lesson.create({
          nombre:      ld.nombre,
          descripcion: ld.descripcion,
          tema_id:     tema._id,
          contenido:   ld.contenido,
          orden:       ld.orden,
        });

        for (let i = 0; i < ld.ejercicios.length; i++) {
          const ej = ld.ejercicios[i];
          await Exercise.create({
            pregunta:          ej.pregunta,
            tipo:              'seleccion_unica',
            opciones:          ej.opciones,
            respuesta_correcta: ej.respuesta_correcta,
            explicacion:       ej.explicacion,
            puntos:            10,
            leccion_id:        leccion._id,
            creado_por:        admin._id,
            orden:             i + 1,
          });
        }

        console.log(`   └─ Tema: ${tema.nombre}  →  Lección: "${leccion.nombre}"  (${ld.ejercicios.length} ejercicios)`);
      }
    }

    // ── PROGRESO INICIAL DEL ESTUDIANTE (vacío) ───────────────────────────────
    await Progreso.create({
      estudiante_id:         estudiante._id,
      lecciones_completadas: [],
      niveles_completados:   [],
    });
    console.log('\n✅ Progreso inicial del estudiante creado (sin completados)');

    // ── RESUMEN ───────────────────────────────────────────────────────────────
    const totalNiveles   = await Level.countDocuments();
    const totalTemas     = await Topic.countDocuments();
    const totalLecciones = await Lesson.countDocuments();
    const totalEjercicios = await Exercise.countDocuments();

    console.log('\n🎉 Seed completado exitosamente!');
    console.log('─'.repeat(45));
    console.log(`   Niveles:    ${totalNiveles}`);
    console.log(`   Temas:      ${totalTemas}`);
    console.log(`   Lecciones:  ${totalLecciones}`);
    console.log(`   Ejercicios: ${totalEjercicios}`);
    console.log('─'.repeat(45));
    console.log('   👤 admin@cylearn.com       →  Admin123!');
    console.log('   👤 estudiante@cylearn.com  →  Student123!');
    console.log('─'.repeat(45));

  } catch (error) {
    console.error('❌ Error durante el seed:', error);
    process.exit(1);
  } finally {
    await disconnectDB();
    process.exit(0);
  }
};

seedData();
