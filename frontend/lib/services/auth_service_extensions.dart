import '../config/api_config.dart';
import 'api_service.dart';

/// Extension methods for AuthService to add 2FA functionality
/// Import this file alongside auth_service.dart when 2FA features are needed
class AuthServiceExtensions {
  final ApiService _api = ApiService();

  /// Setup Two-Factor Authentication
  /// Returns QR code and secret for authenticator app
  Future<Map<String, dynamic>?> setup2FA() async {
    final response = await _api.post(ApiConfig.setup2faUrl);

    if (response.success && response.data['data'] != null) {
      return {
        'secret': response.data['data']['secret'],
        'qrCode': response.data['data']['qrCode'],
      };
    }

    return null;
  }

  /// Enable 2FA with verification code
  Future<bool> enable2FA(String code) async {
    final response = await _api.post(
      ApiConfig.enable2faUrl,
      body: {'token': code},
    );
    return response.success;
  }

  /// Disable 2FA
  Future<bool> disable2FA() async {
    final response = await _api.post(ApiConfig.disable2faUrl);
    return response.success;
  }

  /// Verify email with token from email link
  Future<bool> verifyEmail(String token) async {
    final response = await _api.get(
      ApiConfig.verifyEmailUrl(token),
      requireAuth: false,
    );
    return response.success;
  }

  /// Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    final response = await _api.patch(
      ApiConfig.resetPasswordUrl(token),
      body: {'password': password},
      requireAuth: false,
    );
    return response.success;
  }
}