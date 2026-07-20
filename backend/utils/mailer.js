// Envío de correos desde la cuenta oficial (cylearnoficial@gmail.com).
//
// Requiere en el .env:
//   EMAIL_USER=cylearnoficial@gmail.com
//   EMAIL_APP_PASSWORD=<contraseña de aplicación de Gmail>
//
// La "contraseña de aplicación" NO es la contraseña normal de la cuenta:
// se genera en https://myaccount.google.com/apppasswords (requiere tener
// verificación en dos pasos activada). Sin estas variables, los correos
// simplemente no se envían y la API lo reporta en la respuesta.
const nodemailer = require('nodemailer');

function configurado() {
  return !!(process.env.EMAIL_USER && process.env.EMAIL_APP_PASSWORD);
}

function transporte() {
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_APP_PASSWORD,
    },
  });
}

const ESTILO_BASE = `
  font-family: Arial, Helvetica, sans-serif;
  max-width: 560px; margin: 0 auto; padding: 24px;
  color: #1C1140; line-height: 1.6;`;

function plantillaAceptada(solicitud) {
  return `
  <div style="${ESTILO_BASE}">
    <h1 style="color:#059669">🎉 ¡Bienvenidos a CyLearn!</h1>
    <p>Hola, equipo de <strong>${solicitud.nombre_organizacion}</strong>:</p>
    <p>¡Buenas noticias! Su solicitud para unirse a CyLearn fue
    <strong style="color:#059669">ACEPTADA</strong>.</p>
    <p>En breve les compartiremos el <strong>código de organización</strong>
    y los links de invitación para que sus estudiantes y profesores puedan
    registrarse y acceder a su contenido exclusivo.</p>
    <p>Si tienen cualquier duda, respondan directamente a este correo.</p>
    <p style="margin-top:28px">— El equipo de <strong>CyLearn</strong> 🛡️</p>
  </div>`;
}

function plantillaRechazada(solicitud) {
  return `
  <div style="${ESTILO_BASE}">
    <h1 style="color:#1C1140">Sobre su solicitud a CyLearn</h1>
    <p>Hola, equipo de <strong>${solicitud.nombre_organizacion}</strong>:</p>
    <p>Gracias por su interés en CyLearn. Después de revisar su solicitud,
    lamentamos informarles que <strong>no fue aprobada</strong> en esta ocasión.</p>
    <p>Esto puede deberse a información incompleta o a que por el momento no
    podemos atender su sector. Pueden volver a enviar una solicitud más
    adelante, o responder a este correo si creen que se trata de un error.</p>
    <p style="margin-top:28px">— El equipo de <strong>CyLearn</strong> 🛡️</p>
  </div>`;
}

// Envía el resultado de la solicitud a la organización.
// Devuelve { enviado, motivo? } — nunca lanza (el correo no debe romper la API).
async function enviarResultadoSolicitud(solicitud, aceptada) {
  if (!configurado()) {
    return {
      enviado: false,
      motivo: 'Correo no configurado: falta EMAIL_APP_PASSWORD en el .env del servidor',
    };
  }
  try {
    await transporte().sendMail({
      from: `"CyLearn" <${process.env.EMAIL_USER}>`,
      to: solicitud.email,
      subject: aceptada
        ? '🎉 Tu solicitud a CyLearn fue aceptada'
        : 'Sobre tu solicitud a CyLearn',
      html: aceptada ? plantillaAceptada(solicitud) : plantillaRechazada(solicitud),
    });
    return { enviado: true };
  } catch (error) {
    return { enviado: false, motivo: `Error al enviar: ${error.message}` };
  }
}

module.exports = { enviarResultadoSolicitud, configurado };
