import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/widgets.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() => _isLoading = true);

    final success = await _authService.resendVerificationEmail();

    setState(() {
      _isLoading = false;
      if (success) {
        _emailSent = true;
        _resendCooldown = 60;
        _startCooldownTimer();
      }
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send email. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startCooldownTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);

    await context.read<AuthProvider>().refreshUser();

    setState(() => _isLoading = false);

    if (mounted) {
      final user = context.read<AuthProvider>().user;
      if (user?.isEmailVerified == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/sign-in',
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.sms,
                  color: AppColors.primary,
                  size: 60,
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

              const SizedBox(height: 32),

              // Title
              Text(
                'Verify Your Email',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 12),

              // Description
              Text(
                'We\'ve sent a verification link to',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

              const SizedBox(height: 8),

              // Email
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user?.email ?? 'your email',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 40),

              // Instructions Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _InstructionItem(
                      number: '1',
                      text: 'Check your email inbox',
                    ),
                    _InstructionItem(
                      number: '2',
                      text: 'Click the verification link',
                    ),
                    _InstructionItem(
                      number: '3',
                      text: 'Come back here and tap "I\'ve Verified"',
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),

              // Check Status Button
              PrimaryButton(
                text: "I've Verified My Email",
                onPressed: _checkVerificationStatus,
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

              const SizedBox(height: 16),

              // Resend Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the email? ",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _resendCooldown > 0 ? null : _resendVerificationEmail,
                    child: Text(
                      _resendCooldown > 0
                          ? 'Resend in ${_resendCooldown}s'
                          : 'Resend',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _resendCooldown > 0
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 350.ms),

              const SizedBox(height: 32),

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
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
                          'Tips',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Check your spam or junk folder\n• Make sure you entered the correct email\n• The link expires after 24 hours',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}