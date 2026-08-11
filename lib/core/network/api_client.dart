import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';

class ApiClient {
  static Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final token = await SecureStorageService.getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String url) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Tiempo de espera agotado al conectar al servidor'),
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Tiempo de espera agotado al conectar al servidor'),
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> put(String url, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Tiempo de espera agotado al conectar al servidor'),
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> postMultipart(
    String url,
    Map<String, String> fields,
    String? filePath,
    String fileParamName,
  ) async {
    final headers = await _getHeaders(isMultipart: true);
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(headers);
    request.fields.addAll(fields);

    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(fileParamName, filePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _parseResponse(response);
  }

  static Map<String, dynamic> _parseResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    } else {
      final msg = body['message'] ?? 'Error en la petición (Código: ${response.statusCode})';
      throw Exception(msg);
    }
  }
}
