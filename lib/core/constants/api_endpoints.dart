import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // 🤖 Para Emulador Android: usa http://10.0.2.2:8000/api/v1 (IP del localhost de la PC)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  // Rutas Auth Generales
  static String get login => '$baseUrl/login';
  static String get logout => '$baseUrl/logout';
  static String sucursales([int? empresaId]) =>
      empresaId != null ? '$baseUrl/sucursales?empresa_id=$empresaId' : '$baseUrl/sucursales';

  // 📱 Rutas Módulo Exclusivo Móvil (/api/v1/mobile/...)
  static String get mobileMenu => '$baseUrl/mobile/menu';
  static String mobileMenuUrl([int? empresaId]) =>
      empresaId != null ? '$baseUrl/mobile/menu?empresa_id=$empresaId' : '$baseUrl/mobile/menu';
  static String get existencias => '$baseUrl/mobile/existencias';
  static String get adicional => '$baseUrl/mobile/existencias/adicional';

  static String registrarConteo(int id) => '$baseUrl/mobile/existencias/$id/conteo';
  static String subirImagen(int id) => '$baseUrl/mobile/existencias/$id/imagen';
  static String historial(int id) => '$baseUrl/mobile/existencias/$id/historial';
  static String modificarHistorial(int id) => '$baseUrl/mobile/existencias/historial/$id';

  /// Convierte una ruta relativa de imagen (/uploads/...) a una URL absoluta según el entorno
  static String? resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final rootHost = baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$rootHost$cleanPath';
  }
}
