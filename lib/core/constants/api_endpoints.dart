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


  // Rutas Auth
  static String get login => '$baseUrl/login';
  static String get logout => '$baseUrl/logout';
  static String get mobileMenu => '$baseUrl/mobile/menu';

  // Rutas Existencias & Conteos
  static String get existencias => '$baseUrl/existencias';
  static String get importarExcel => '$baseUrl/existencias/importar-excel';
  static String get adicional => '$baseUrl/existencias/adicional';

  static String registrarConteo(int id) => '$baseUrl/existencias/$id/conteo';
  static String subirImagen(int id) => '$baseUrl/existencias/$id/imagen';
  static String registrarSustento(int id) => '$baseUrl/existencias/$id/sustento';
  static String historial(int id) => '$baseUrl/existencias/$id/historial';
}
