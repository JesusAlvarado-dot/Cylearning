const mongoose = require('mongoose');
const environment = require('./environment');

const connectDB = async () => {
  try {
    const uri = environment.server.nodeEnv === 'test' 
      ? environment.mongodb.testUri 
      : environment.mongodb.uri;

    await mongoose.connect(uri);

    // No mostrar la URI completa: contiene credenciales
    console.log(`MongoDB conectado en ${environment.server.nodeEnv}: ${uri.replace(/\/\/[^@]+@/, '//***:***@')}`);
    return mongoose.connection;
  } catch (error) {
    console.error('Error al conectar MongoDB:', error.message);
    process.exit(1);
  }
};

const disconnectDB = async () => {
  try {
    await mongoose.disconnect();
    console.log('MongoDB desconectado');
  } catch (error) {
    console.error('Error al desconectar MongoDB:', error.message);
    process.exit(1);
  }
};

module.exports = {
  connectDB,
  disconnectDB,
};
