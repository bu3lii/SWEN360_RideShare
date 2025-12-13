import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _authService.updatePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current password is incorrect'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Change Password'),
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
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.lock,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure Your Account',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Use a strong password with letters, numbers, and symbols',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

                const SizedBox(height: 32),

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
                      // Current Password
                      Text('Current Password', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        decoration: InputDecoration(
                          hintText: 'Enter current password',
                          prefixIcon: const Icon(Iconsax.lock, color: AppColors.inputIcon),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                            icon: Icon(
                              _obscureCurrentPassword ? Iconsax.eye : Iconsax.eye_slash,
                              color: AppColors.inputIcon,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // New Password
                      Text('New Password', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        decoration: InputDecoration(
                          hintText: 'Enter new password',
                          prefixIcon: const Icon(Iconsax.lock_1, color: AppColors.inputIcon),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                            icon: Icon(
                              _obscureNewPassword ? Iconsax.eye : Iconsax.eye_slash,
                              color: AppColors.inputIcon,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
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

                      // Confirm New Password
                      Text('Confirm New Password', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          hintText: 'Confirm new password',
                          prefixIcon: const Icon(Iconsax.lock_1, color: AppColors.inputIcon),
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
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
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
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Iconsax.info_circle,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Password Requirements',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _RequirementItem(text: 'At least 8 characters'),
                      _RequirementItem(text: 'At least one uppercase letter'),
                      _RequirementItem(text: 'At least one lowercase letter'),
                      _RequirementItem(text: 'At least one number'),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                const SizedBox(height: 32),

                // Submit Button
                PrimaryButton(
                  text: 'Change Password',
                  onPressed: _changePassword,
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

class _RequirementItem extends StatelessWidget {
  final String text;

  const _RequirementItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}