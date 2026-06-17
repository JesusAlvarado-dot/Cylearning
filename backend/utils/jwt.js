const jwt = require('jsonwebtoken');
const environment = require('../config/environment');

// Generar token JWT
const generarToken = (usuarioId, rol) => {
  try {
    const payload = {
      id: usuarioId,
      rol: rol,
    };

    const token = jwt.sign(payload, environment.jwt.secret, {
      expiresIn: environment.jwt.expiresIn,
    });

    return token;
  } catch (error) {
    throw new Error(`Error al generar token: ${error.message}`);
  }
};

// Verificar token JWT
const verificarToken = (token) => {
  try {
    const decoded = jwt.verify(token, environment.jwt.secret);
    return decoded;
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new Error('Token expirado');
    }
    if (error.name === 'JsonWebTokenError') {
      throw new Error('Token inválido');
    }
    throw new Error(`Error al verificar token: ${error.message}`);
  }
};

// Decodificar token sin verificar
const decodificarToken = (token) => {
  try {
    return jwt.decode(token);
  } catch (error) {
    throw new Error(`Error al decodificar token: ${error.message}`);
  }
};

module.exports = {
  generarToken,
  verificarToken,
  decodificarToken,
};
