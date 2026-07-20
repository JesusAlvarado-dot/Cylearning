// Validación de fotos de perfil (usuarios y organizaciones).
// Se aceptan dos formatos:
//   - data URI base64 (subida desde la app, ya comprimida por el cliente)
//   - URL https (foto de Google/Facebook)
// Devuelve null si es válida, o el mensaje de error.
function validarFoto(foto) {
  if (foto === '') return null; // '' = quitar la foto
  if (typeof foto !== 'string') return 'Foto inválida';
  if (foto.startsWith('https://')) {
    if (foto.length > 2048) return 'La URL de la foto es demasiado larga';
    return null;
  }
  if (/^data:image\/(jpeg|jpg|png|webp);base64,/.test(foto)) {
    // ~400KB en base64 ≈ 300KB reales; el body limit del server es 1MB
    if (foto.length > 400 * 1024) {
      return 'La foto es demasiado grande (máximo ~300KB)';
    }
    return null;
  }
  return 'Formato de foto no soportado';
}

module.exports = { validarFoto };
