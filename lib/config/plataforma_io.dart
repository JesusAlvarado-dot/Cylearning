import 'dart:io' show Platform;

// Versión para plataformas nativas (Android/Windows/iOS/macOS/Linux).
bool get esAndroidNativo => Platform.isAndroid;
