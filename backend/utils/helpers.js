// Respuesta de éxito estándar
const respuestaExito = (res, datos, mensaje = 'Operación exitosa', status = 200) => {
  return res.status(status).json({
    success: true,
    mensaje,
    datos,
  });
};

// Respuesta de error estándar
const respuestaError = (res, mensaje, status = 400, detalles = null) => {
  return res.status(status).json({
    success: false,
    mensaje,
    ...(detalles && { detalles }),
  });
};

// Calcular porcentaje de completado
const calcularPorcentaje = (correctas, total) => {
  if (total === 0) return 0;
  return Math.round((correctas / total) * 100);
};

// Paginar resultados
const paginar = (pagina, limite) => {
  const page = Math.max(1, parseInt(pagina) || 1);
  const limit = Math.min(
    Math.max(1, parseInt(limite) || 10),
    100
  );
  const skip = (page - 1) * limit;

  return { page, limit, skip };
};

// Formatear respuesta paginada
const respuestaPaginada = (datos, total, pagina, limite) => {
  const { page, limit } = paginar(pagina, limite);
  const totalPaginas = Math.ceil(total / limit);

  return {
    datos,
    paginacion: {
      pagina: page,
      limite: limit,
      total,
      totalPaginas,
    },
  };
};

// Obtener IP del cliente
const obtenerIP = (req) => {
  return (
    req.headers['x-forwarded-for']?.split(',')[0] ||
    req.headers['x-real-ip'] ||
    req.connection.remoteAddress ||
    'desconocida'
  );
};

// Normalizar resultado de respuesta
const normalizarRespuesta = (respuesta, respuestaCorrecta) => {
  return respuesta.trim().toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
};

// Comparar respuestas (insensible a acentos y mayúsculas)
const compararRespuestas = (respuestaIngresada, respuestaCorrecta) => {
  const normalizada = normalizarRespuesta(respuestaIngresada);
  const correcta = normalizarRespuesta(respuestaCorrecta);
  return normalizada === correcta;
};

module.exports = {
  respuestaExito,
  respuestaError,
  calcularPorcentaje,
  paginar,
  respuestaPaginada,
  obtenerIP,
  compararRespuestas,
  normalizarRespuesta,
};
