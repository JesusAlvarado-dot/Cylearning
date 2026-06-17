# 🛡️ CyLearn Backend

API REST para la plataforma de educación en ciberseguridad **CyLearn**.

## 🚀 Instalación

### Requisitos
- Node.js 14+
- MongoDB (local o Atlas)

### Pasos

```bash
# 1. Instalar dependencias
npm install

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con tu configuración

# 3. Llenar base de datos con datos de ejemplo
npm run seed

# 4. Ejecutar el servidor
npm run dev  # Desarrollo (con nodemon)
npm start    # Producción
```

---

## 📦 Dependencias Principales

```json
{
  "express": "^4.18.2",
  "mongoose": "^7.0.0",
  "bcryptjs": "^2.4.3",
  "jsonwebtoken": "^9.0.0",
  "cors": "^2.8.5",
  "helmet": "^7.0.0",
  "express-validator": "^7.0.0",
  "morgan": "^1.10.0"
}
```

---

## 🗂️ Estructura del Proyecto

```
backend/
├── config/              # Configuración
│   ├── environment.js   # Variables de entorno
│   ├── database.js      # Conexión MongoDB
│   └── constants.js     # Constantes de la app
│
├── models/              # Modelos Mongoose
│   ├── User.js
│   ├── Level.js
│   ├── Topic.js
│   ├── Lesson.js
│   ├── Exercise.js
│   ├── StudentProgress.js
│   ├── ExerciseHistory.js
│   └── Log.js
│
├── controllers/         # Lógica de negocio
│   ├── authController.js
│   ├── userController.js
│   ├── levelController.js
│   ├── topicController.js
│   ├── lessonController.js
│   ├── exerciseController.js
│   ├── progressController.js
│   └── logController.js
│
├── routes/              # Rutas API
│   ├── authRoutes.js
│   ├── userRoutes.js
│   ├── adminRoutes.js
│   ├── studentRoutes.js
│   ├── exerciseRoutes.js
│   └── index.js
│
├── middlewares/         # Middlewares
│   ├── authMiddleware.js
│   ├── roleMiddleware.js
│   └── errorHandler.js
│
├── utils/               # Utilidades
│   ├── jwt.js
│   ├── validators.js
│   └── helpers.js
│
├── seed.js              # Datos iniciales
├── app.js               # Configuración Express
├── server.js            # Inicio servidor
└── package.json
```

---

## 📋 Datos de Ejemplo (Seed)

Al ejecutar `npm run seed` se crean:

### 👥 Usuarios
- **Admin**: `admin@cylearn.com` / `Admin123!`
- **Estudiante**: `estudiante@cylearn.com` / `Student123!`

### 📚 Niveles
1. **Nivel 1 - Principiante** (4 temas)
2. **Nivel 2 - Intermedio** (2 temas)
3. **Nivel 3 - Avanzado** (2 temas)

### 🎯 Total de Contenido
- 3 Niveles
- 8 Temas
- 12 Lecciones
- 15 Ejercicios

---

## 🔐 Autenticación

El API usa **JWT (JSON Web Tokens)** para autenticación.

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "admin@cylearn.com",
  "contrasena": "Admin123!"
}
```

**Respuesta:**
```json
{
  "success": true,
  "mensaje": "Inicio de sesión exitoso",
  "datos": {
    "usuario": { ... },
    "token": "eyJhbGc..."
  }
}
```

### Usar Token
Añadir el token al header `Authorization`:
```
Authorization: Bearer <token>
```

---

## 📚 Endpoints Principales

### 🔐 Autenticación
```
POST   /api/auth/registro          # Crear cuenta
POST   /api/auth/login              # Iniciar sesión
POST   /api/auth/logout             # Cerrar sesión
GET    /api/auth/me                 # Usuario actual
```

### 👨‍🎓 Estudiante
```
GET    /api/student/niveles         # Ver niveles
GET    /api/student/lecciones       # Ver lecciones
GET    /api/student/lecciones/:id/iniciar  # Iniciar lección
POST   /api/student/ejercicios/:id/responder  # Responder ejercicio
GET    /api/student/progreso        # Ver mi progreso
```

### 👑 Administrador
```
GET    /api/admin/niveles
POST   /api/admin/niveles
PUT    /api/admin/niveles/:id
DELETE /api/admin/niveles/:id

GET    /api/admin/ejercicios
POST   /api/admin/ejercicios
PUT    /api/admin/ejercicios/:id
DELETE /api/admin/ejercicios/:id

GET    /api/admin/logs
GET    /api/admin/ranking/estudiantes
```

---

## 🛡️ Roles

### Admin (`admin`)
- Crear, editar, eliminar niveles, temas, lecciones
- Crear y gestionar ejercicios
- Ver estadísticas de estudiantes
- Acceder a logs del sistema

### Estudiante (`student`)
- Ver lecciones disponibles
- Responder ejercicios
- Ver su progreso
- Ver ranking

---

## 💾 Base de Datos

### Modelos

**User** - Usuarios del sistema
- nombre, email, contrasena (hasheada), rol, puntos_totales

**Level** - Niveles de dificultad
- nombre, numero, dificultad, descripcion

**Topic** - Temas (Contraseñas, Phishing, etc.)
- nombre, descripcion, nivel_id

**Lesson** - Lecciones
- nombre, descripcion, tema_id, contenido

**Exercise** - Ejercicios
- pregunta, tipo, opciones, respuesta_correcta, puntos, leccion_id

**StudentProgress** - Progreso del estudiante
- estudiante_id, leccion_id, estado, puntos_obtenidos

**ExerciseHistory** - Historial de respuestas
- estudiante_id, ejercicio_id, respuesta_ingresada, estado

**Log** - Auditoría
- tipo, usuario_id, descripcion, entidad_tipo, detalles

---

## 🔒 Seguridad

✅ Contraseñas hasheadas con bcryptjs
✅ Autenticación JWT
✅ Validación de entrada
✅ CORS configurado
✅ Helmet para headers
✅ Logging de auditoría

---

## 📊 Variables de Entorno

```bash
# Database
MONGODB_URI=mongodb://localhost:27017/app-escuela
MONGODB_TEST_URI=mongodb://localhost:27017/app-escuela-test

# JWT
JWT_SECRET=tu_secret_key_muy_seguro
JWT_EXPIRE=7d

# Server
PORT=5000
NODE_ENV=development

# CORS
CORS_ORIGIN=http://localhost:3000

# Logging
LOG_LEVEL=info
```

---

## 🧪 Pruebas

```bash
# Ejecutar tests
npm test
```

---

## 🚢 Deployment

### Vercel / Heroku

1. Configurable variables de entorno
2. Asegurar MongoDB en la nube (Atlas)
3. Deploy automático desde Git

### Ejemplo Vercel
```bash
vercel --prod
```

---

## 📝 Desarrollo

### Agregar nuevo endpoint

1. Crear modelo en `models/`
2. Crear controller en `controllers/`
3. Crear rutas en `routes/`
4. Importar en `routes/index.js`

---

## 🤝 Contribuciones

Este proyecto es educativo. ¡Contribuciones bienvenidas!

---

## 📄 Licencia

MIT

---

## 👨‍💻 Autor

Desarrollado como plataforma de educación en ciberseguridad.

**CyLearn - Aprende seguridad digital de forma divertida** 🛡️
