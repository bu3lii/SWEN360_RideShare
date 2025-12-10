import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.forgotPassword(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return LoadingOverlay(
              isLoading: authProvider.isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _emailSent ? _buildSuccessContent() : _buildFormContent(authProvider),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormContent(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.lock_1,
              size: 40,
              color: AppColors.primary,
            ),
          ).animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          
          const SizedBox(height: 32),
          
          // Header
          Text(
            'Forgot Password?',
            style: AppTextStyles.h1,
          ).animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideX(begin: -0.2, end: 0),
          
          const SizedBox(height: 8),
          
          Text(
            "No worries! Enter your email address and we'll send you a link to reset your password.",
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate()
            .fadeIn(duration: 400.ms, delay: 150.ms)
            .slideX(begin: -0.2, end: 0),
          
          const SizedBox(height: 40),
          
          // Email Field
          CustomTextField(
            label: 'Email',
            hintText: 'your.email@university.edu',
            controller: _emailController,
            prefixIcon: Iconsax.sms,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleResetPassword(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ).animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 32),
          
          // Reset Button
          PrimaryButton(
            text: 'Send Reset Link',
            onPressed: _handleResetPassword,
            isLoading: authProvider.isLoading,
          ).animate()
            .fadeIn(duration: 400.ms, delay: 300.ms)
            .slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 24),
          
          // Back to Sign In
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.arrow_left_2,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Back to Sign In',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ).animate()
            .fadeIn(duration: 400.ms, delay: 400.ms),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        
        // Success Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Iconsax.tick_circle,
            size: 50,
            color: AppColors.success,
          ),
        ).animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        
        const SizedBox(height: 32),
        
        // Success Message
        Text(
          'Check Your Email',
          style: AppTextStyles.h1,
          textAlign: TextAlign.center,
        ).animate()
          .fadeIn(duration: 400.ms, delay: 100.ms),
        
        const SizedBox(height: 12),
        
        Text(
          'We have sent a password reset link to\n${_emailController.text}',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate()
          .fadeIn(duration: 400.ms, delay: 150.ms),
        
        const SizedBox(height: 40),
        
        // Back to Sign In Button
        PrimaryButton(
          text: 'Back to Sign In',
          onPressed: () => Navigator.pop(context),
        ).animate()
          .fadeIn(duration: 400.ms, delay: 200.ms)
          .slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 16),
        
        // Resend Link
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            "Didn't receive the email? Try again",
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ).animate()
          .fadeIn(duration: 400.ms, delay: 300.ms),
        
        const SizedBox(height: 40),
      ],
    );
  }
}