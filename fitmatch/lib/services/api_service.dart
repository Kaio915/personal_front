import 'dart:convert';
import 'package:fitmatch/config/config.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL da API - altere conforme necessário
  static String baseUrl = Config.apiUrl;

  // Timeout padrão para requisições
  static const Duration timeout = Duration(seconds: 30);

  // Headers padrão
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // GET request
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {
      ..._headers,
      if (headers != null) ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .get(uri, headers: requestHeaders)
          .timeout(timeout);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {
      ..._headers,
      if (headers != null) ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // POST with form data (para OAuth2)
  static Future<http.Response> postForm(
    String endpoint, {
    required Map<String, String> body,
    Map<String, String>? headers,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
      if (headers != null) ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .post(uri, headers: requestHeaders, body: body)
          .timeout(timeout);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // PUT request
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {
      ..._headers,
      if (headers != null) ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {
      ..._headers,
      if (headers != null) ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .delete(uri, headers: requestHeaders)
          .timeout(timeout);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Verificar se a resposta foi bem sucedida
  static bool isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // Decodificar resposta JSON
  static dynamic decodeResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
