import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;

  // Always get fresh token - don't cache null
  Future<String?> get token async {
    // Always read from storage to ensure we have the latest token
    _token = await _storage.read(key: 'auth_token');
    debugPrint('ApiService.token: $_token');
    return _token;
  }

  Future<void> setToken(String token) async {
    debugPrint('ApiService.setToken: $token');
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    debugPrint('ApiService.clearToken');
    _token = null;
    await _storage.delete(key: 'auth_token');
  }

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final authToken = await token;
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
        debugPrint('Adding auth header: Bearer ${authToken.substring(0, 20)}...');
      } else {
        debugPrint('WARNING: No auth token available for authenticated request');
      }
    }

    return headers;
  }

  Future<ApiResponse> get(String url, {bool requireAuth = true}) async {
    try {
      debugPrint('GET $url (requireAuth: $requireAuth)');
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      debugPrint('GET $url -> ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET $url ERROR: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> post(
    String url, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    try {
      debugPrint('POST $url (requireAuth: $requireAuth)');
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);

      debugPrint('POST $url -> ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST $url ERROR: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> patch(
    String url, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    try {
      debugPrint('PATCH $url (requireAuth: $requireAuth)');
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http
          .patch(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);

      debugPrint('PATCH $url -> ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PATCH $url ERROR: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> delete(
    String url, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    try {
      debugPrint('DELETE $url (requireAuth: $requireAuth)');
      final headers = await _getHeaders(requireAuth: requireAuth);
      final request = http.Request('DELETE', Uri.parse(url));
      request.headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await request.send().timeout(ApiConfig.receiveTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('DELETE $url -> ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE $url ERROR: $e');
      return ApiResponse.error(e.toString());
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.success(body);
    } else {
      final message = body['message'] ?? 'An error occurred';
      debugPrint('API Error: $message (${response.statusCode})');
      return ApiResponse.error(message, statusCode: response.statusCode, data: body);
    }
  }
}

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: 200,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode, dynamic data}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }
}