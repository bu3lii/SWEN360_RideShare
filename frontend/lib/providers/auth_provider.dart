import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _requiresTwoFactor = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  bool get requiresTwoFactor => _requiresTwoFactor;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _user = await _authService.getCurrentUser();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String universityId,
    required String password,
    required String phoneNumber,
    required String gender,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      name: name,
      email: email,
      universityId: universityId,
      password: password,
      phoneNumber: phoneNumber,
      gender: gender,
    );

    _isLoading = false;

    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
      return true;
    }

    _errorMessage = result.errorMessage ?? 'Registration failed';
    notifyListeners();
    return false;
  }

  Future<bool> login({
    required String email,
    required String password,
    String? twoFactorCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _requiresTwoFactor = false;
    notifyListeners();

    final result = await _authService.login(
      email: email,
      password: password,
      twoFactorCode: twoFactorCode,
    );

    _isLoading = false;

    if (result.requiresTwoFactor) {
      _requiresTwoFactor = true;
      notifyListeners();
      return false;
    }

    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
      return true;
    }

    _errorMessage = result.errorMessage ?? 'Login failed';
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    
    _user = null;
    _isLoading = false;
    _requiresTwoFactor = false;
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _authService.forgotPassword(email);

    _isLoading = false;
    notifyListeners();

    return success;
  }

  Future<void> refreshUser() async {
    _user = await _authService.getCurrentUser();
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}