import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<AuthResult> register({
    required String name,
    required String email,
    required String universityId,
    required String password,
    required String phoneNumber,
    required String gender,
  }) async {
    final response = await _api.post(
      ApiConfig.registerUrl,
      body: {
        'name': name,
        'email': email,
        'universityId': universityId,
        'password': password,
        'phoneNumber': phoneNumber,
        'gender': gender,
      },
      requireAuth: false,
    );

    debugPrint('Register response: ${response.data}');

    if (response.success && response.data['token'] != null) {
      debugPrint('Register token: ${response.data['token']}');
      await _api.setToken(response.data['token']);
      final user = User.fromJson(response.data['data']['user']);
      return AuthResult.success(user, response.data['token']);
    }

    return AuthResult.failure(response.message ?? 'Registration failed');
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    String? twoFactorCode,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };

    if (twoFactorCode != null) {
      body['twoFactorCode'] = twoFactorCode;
    }

    final response = await _api.post(
      ApiConfig.loginUrl,
      body: body,
      requireAuth: false,
    );

    debugPrint('Login response success: ${response.success}');
    debugPrint('Login response data: ${response.data}');
    debugPrint('Login response data type: ${response.data.runtimeType}');

    if (response.success) {
      if (response.data['requiresTwoFactor'] == true) {
        debugPrint('2FA required');
        return AuthResult.requiresTwoFactor();
      }

      final token = response.data['token'];
      debugPrint('Token from response: $token');
      
      if (token != null) {
        debugPrint('Setting token...');
        await _api.setToken(token);
        debugPrint('Token set successfully');
        
        final userData = response.data['data']?['user'];
        debugPrint('User data: $userData');
        
        if (userData != null) {
          final user = User.fromJson(userData);
          debugPrint('User parsed: ${user.email}');
          return AuthResult.success(user, token);
        } else {
          debugPrint('ERROR: User data is null');
          return AuthResult.failure('User data not found in response');
        }
      } else {
        debugPrint('ERROR: Token is null in response');
      }
    }

    debugPrint('Login failed: ${response.message}');
    return AuthResult.failure(response.message ?? 'Login failed');
  }

  Future<bool> logout() async {
    final response = await _api.post(ApiConfig.logoutUrl);
    await _api.clearToken();
    return response.success;
  }

  Future<User?> getCurrentUser() async {
    debugPrint('Getting current user...');
    final response = await _api.get(ApiConfig.meUrl);

    debugPrint('getCurrentUser response success: ${response.success}');
    
    if (response.success && response.data['data'] != null) {
      return User.fromJson(response.data['data']['user']);
    }

    debugPrint('getCurrentUser failed: ${response.message}');
    return null;
  }

  Future<bool> forgotPassword(String email) async {
    final response = await _api.post(
      ApiConfig.forgotPasswordUrl,
      body: {'email': email},
      requireAuth: false,
    );

    return response.success;
  }

  Future<AuthResult> resetPassword({
    required String token,
    required String password,
    required String passwordConfirm,
  }) async {
    final response = await _api.patch(
      ApiConfig.resetPasswordUrl(token),
      body: {
        'password': password,
        'passwordConfirm': passwordConfirm,
      },
      requireAuth: false,
    );

    if (response.success && response.data['token'] != null) {
      await _api.setToken(response.data['token']);
      final user = User.fromJson(response.data['data']['user']);
      return AuthResult.success(user, response.data['token']);
    }

    return AuthResult.failure(response.message ?? 'Password reset failed');
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _api.patch(
      ApiConfig.updatePasswordUrl,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );

    return response.success;
  }

  Future<bool> resendVerificationEmail() async {
    final response = await _api.post(ApiConfig.resendVerificationUrl);
    return response.success;
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.token;
    debugPrint('isLoggedIn check - token: ${token != null ? "exists" : "null"}');
    return token != null;
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? errorMessage;
  final bool requiresTwoFactor;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.errorMessage,
    this.requiresTwoFactor = false,
  });

  factory AuthResult.success(User user, String token) {
    return AuthResult(
      success: true,
      user: user,
      token: token,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      errorMessage: message,
    );
  }

  factory AuthResult.requiresTwoFactor() {
    return AuthResult(
      success: false,
      requiresTwoFactor: true,
    );
  }
}