import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedGender = 'male';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _universityIdController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      universityId: _universityIdController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim(),
      gender: _selectedGender,
    );

    if (success && mounted) {
      // Check if email is verified
      final user = authProvider.user;
      if (user != null && user.isEmailVerified) {
        // Email already verified, go to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Email not verified, go to verification screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please verify your email.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacementNamed(context, '/email-verification');
      }
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Create Account',
                        style: AppTextStyles.h1,
                      ).animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Join Uni Ride Today!',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideX(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 32),
                      
                      // Full Name
                      CustomTextField(
                        label: 'Full Name',
                        hintText: 'Ahmed',
                        controller: _nameController,
                        prefixIcon: Iconsax.user,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 150.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // Email
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
                          if (!value.endsWith('@aubh.edu.bh')) {
                            return 'Please use your AUBH email';
                          }
                          return null;
                        },
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // University ID
                      CustomTextField(
                        label: 'University ID',
                        hintText: 'f10000000',
                        controller: _universityIdController,
                        prefixIcon: Iconsax.card,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your university ID';
                          }
                          return null;
                        },
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 250.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // Password
                      CustomTextField(
                        label: 'Password',
                        hintText: 'Create a password',
                        controller: _passwordController,
                        prefixIcon: Iconsax.lock,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
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
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // Phone Number
                      CustomTextField(
                        label: 'Phone Number',
                        hintText: '+973-000-0000',
                        controller: _phoneController,
                        prefixIcon: Iconsax.call,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (!RegExp(r'^\+973\d{8}$').hasMatch(value.replaceAll('-', ''))) {
                            return 'Please enter a valid Bahrain number (+973XXXXXXXX)';
                          }
                          return null;
                        },
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 350.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // Gender Selection
                      Text(
                        'Gender',
                        style: AppTextStyles.label,
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 400.ms),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _GenderOption(
                              label: 'Male',
                              icon: Iconsax.man,
                              isSelected: _selectedGender == 'male',
                              onTap: () => setState(() => _selectedGender = 'male'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GenderOption(
                              label: 'Female',
                              icon: Iconsax.woman,
                              isSelected: _selectedGender == 'female',
                              onTap: () => setState(() => _selectedGender = 'female'),
                            ),
                          ),
                        ],
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 450.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 32),
                      
                      // Create Account Button
                      PrimaryButton(
                        text: 'Create Account',
                        onPressed: _handleSignUp,
                        isLoading: authProvider.isLoading,
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Sign In Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Sign in',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 550.ms),
                      
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

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}