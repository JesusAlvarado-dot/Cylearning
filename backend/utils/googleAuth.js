// Verifica un access token de Google llamando al endpoint de userinfo y
// devuelve el perfil (sub, email, name, picture). Se usa access token en
// vez de idToken porque, desde que Google migró a Identity Services (2023),
// el flujo imperativo de signIn() en Web solo entrega access token — el
// idToken únicamente lo emite el botón oficial de Google renderizado por
// ellos, que no usamos porque tenemos un botón propio. El access token sí
// es confiable en Android y Web por igual.
async function obtenerPerfilGoogle(accessToken) {
  const respuesta = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!respuesta.ok) {
    throw new Error('Token de acceso de Google inválido o expirado');
  }
  const perfil = await respuesta.json();
  if (perfil.email_verified !== true) {
    throw new Error('El email de la cuenta de Google no está verificado');
  }
  return perfil;
}

module.exports = { obtenerPerfilGoogle };
