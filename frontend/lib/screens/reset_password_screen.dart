import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../services/auth_service_extensions.dart';
import '../widgets/widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authExtensions = AuthServiceExtensions();
  
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _authExtensions.resetPassword(
      token: widget.token,
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
      _isSuccess = success;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reset password. The link may have expired.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.tick_circle,
                    color: AppColors.success,
                    size: 60,
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 32),

                Text(
                  'Password Reset Successful!',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                const SizedBox(height: 12),

                Text(
                  'Your password has been updated. You can now sign in with your new password.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

                const SizedBox(height: 40),

                PrimaryButton(
                  text: 'Sign In',
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/sign-in',
                      (route) => false,
                    );
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.lock,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create New Password',
                        style: AppTextStyles.h2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your new password must be different from previously used passwords.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

                const SizedBox(height: 40),

                // Form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Password', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter new password',
                          prefixIcon: const Icon(Iconsax.lock, color: AppColors.inputIcon),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword ? Iconsax.eye : Iconsax.eye_slash,
                              color: AppColors.inputIcon,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                            return 'Password must contain uppercase, lowercase, and number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      Text('Confirm Password', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          hintText: 'Confirm new password',
                          prefixIcon: const Icon(Iconsax.lock, color: AppColors.inputIcon),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            icon: Icon(
                              _obscureConfirmPassword ? Iconsax.eye : Iconsax.eye_slash,
                              color: AppColors.inputIcon,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Password Requirements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password must contain:',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _RequirementCheck(
                        text: 'At least 8 characters',
                        isValid: _passwordController.text.length >= 8,
                      ),
                      _RequirementCheck(
                        text: 'One uppercase letter',
                        isValid: RegExp(r'[A-Z]').hasMatch(_passwordController.text),
                      ),
                      _RequirementCheck(
                        text: 'One lowercase letter',
                        isValid: RegExp(r'[a-z]').hasMatch(_passwordController.text),
                      ),
                      _RequirementCheck(
                        text: 'One number',
                        isValid: RegExp(r'\d').hasMatch(_passwordController.text),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Reset Password',
                  onPressed: _resetPassword,
                  isLoading: _isLoading,
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequirementCheck extends StatelessWidget {
  final String text;
  final bool isValid;

  const _RequirementCheck({
    required this.text,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            isValid ? Iconsax.tick_circle : Iconsax.close_circle,
            size: 16,
            color: isValid ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: isValid ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}