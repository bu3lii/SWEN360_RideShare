import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/widgets.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _twoFactorController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      twoFactorCode: authProvider.requiresTwoFactor 
          ? _twoFactorController.text.trim() 
          : null,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
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
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return LoadingOverlay(
              isLoading: authProvider.isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      
                      // Header
                      Text(
                        'Welcome Back!',
                        style: AppTextStyles.h1,
                      ).animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Sign in to continue',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideX(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 48),
                      
                      // Email Field
                      CustomTextField(
                        label: 'Email',
                        hintText: 'your.email@university.edu',
                        controller: _emailController,
                        prefixIcon: Iconsax.sms,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
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
                      
                      const SizedBox(height: 20),
                      
                      // Password Field
                      CustomTextField(
                        label: 'Password',
                        hintText: 'Enter your password',
                        controller: _passwordController,
                        prefixIcon: Iconsax.lock,
                        isPassword: true,
                        textInputAction: authProvider.requiresTwoFactor 
                            ? TextInputAction.next 
                            : TextInputAction.done,
                        onSubmitted: authProvider.requiresTwoFactor 
                            ? null 
                            : (_) => _handleSignIn(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      // 2FA Field (shown when required)
                      if (authProvider.requiresTwoFactor) ...[
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: '2FA Code',
                          hintText: 'Enter your 2FA code',
                          controller: _twoFactorController,
                          prefixIcon: Iconsax.shield_tick,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleSignIn(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your 2FA code';
                            }
                            return null;
                          },
                        ).animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2, end: 0),
                      ],
                      
                      const SizedBox(height: 12),
                      
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot-password');
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 400.ms),
                      
                      const SizedBox(height: 32),
                      
                      // Sign In Button
                      PrimaryButton(
                        text: 'Sign In',
                        onPressed: _handleSignIn,
                        isLoading: authProvider.isLoading,
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/sign-up');
                            },
                            child: Text(
                              'Sign up',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 600.ms),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}