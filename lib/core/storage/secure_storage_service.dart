import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyUserData = 'user_data';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> saveUserData(String jsonString) async {
    await _storage.write(key: _keyUserData, value: jsonString);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: _keyUserData);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
