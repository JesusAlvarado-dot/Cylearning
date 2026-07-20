const { OAuth2Client } = require('google-auth-library');

// Se usa el client ID del cliente OAuth tipo "Web" como audience, sin
// importar si el login vino de Android, Web o (a futuro) escritorio —
// en Android la app pide el idToken con serverClientId=este mismo valor,
// así el backend solo necesita confiar en UN audience.
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID_WEB);

// Verifica un idToken de Google y devuelve su payload (email, name, picture,
// sub). Lanza si el token es inválido, expiró o el audience no coincide.
async function verificarIdTokenGoogle(idToken) {
  const ticket = await client.verifyIdToken({
    idToken,
    audience: process.env.GOOGLE_CLIENT_ID_WEB,
  });
  return ticket.getPayload();
}

module.exports = { verificarIdTokenGoogle };
