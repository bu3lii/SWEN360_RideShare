import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service_extensions.dart';
import '../widgets/widgets.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _authExtensions = AuthServiceExtensions();
  final _codeController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSettingUp = false;
  String? _secret;
  String? _qrCodeUrl;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _setup2FA() async {
    setState(() => _isLoading = true);

    final result = await _authExtensions.setup2FA();

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      setState(() {
        _isSettingUp = true;
        _secret = result['secret'];
        _qrCodeUrl = result['qrCode'];
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to setup 2FA'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _enable2FA() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit code'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _authExtensions.enable2FA(code);

    setState(() => _isLoading = false);

    if (success && mounted) {
      await context.read<AuthProvider>().refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-Factor Authentication enabled!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid code. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _disable2FA() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable 2FA'),
        content: const Text(
          'Are you sure you want to disable Two-Factor Authentication? This will make your account less secure.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final success = await _authExtensions.disable2FA();

    setState(() => _isLoading = false);

    if (success && mounted) {
      await context.read<AuthProvider>().refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-Factor Authentication disabled'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final is2FAEnabled = user?.twoFactorEnabled ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: is2FAEnabled
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: is2FAEnabled
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: is2FAEnabled ? AppColors.success : AppColors.warning,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        is2FAEnabled ? Iconsax.shield_tick : Iconsax.shield_cross,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            is2FAEnabled ? 'Enabled' : 'Disabled',
                            style: AppTextStyles.h3.copyWith(
                              color: is2FAEnabled ? AppColors.success : AppColors.warning,
                            ),
                          ),
                          Text(
                            is2FAEnabled
                                ? 'Your account is protected with 2FA'
                                : 'Add an extra layer of security',
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

              const SizedBox(height: 24),

              if (!is2FAEnabled && !_isSettingUp) ...[
                // Benefits Section
                Text('Why use 2FA?', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                _BenefitItem(
                  icon: Iconsax.lock,
                  title: 'Enhanced Security',
                  description: 'Protect your account even if your password is compromised',
                ),
                _BenefitItem(
                  icon: Iconsax.mobile,
                  title: 'Easy to Use',
                  description: 'Use any authenticator app like Google Authenticator',
                ),
                _BenefitItem(
                  icon: Iconsax.shield_tick,
                  title: 'Industry Standard',
                  description: 'TOTP-based authentication used by major companies',
                ),

                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Enable Two-Factor Authentication',
                  onPressed: _setup2FA,
                  icon: Iconsax.shield_tick,
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              ],

              if (_isSettingUp) ...[
                // Setup Flow
                Text('Setup Instructions', style: AppTextStyles.h3),
                const SizedBox(height: 16),

                // Step 1
                _SetupStep(
                  number: '1',
                  title: 'Download an Authenticator App',
                  description: 'Install Google Authenticator, Authy, or any TOTP app',
                ),

                // Step 2
                _SetupStep(
                  number: '2',
                  title: 'Scan QR Code or Enter Secret',
                  description: 'Use your authenticator app to scan the code below',
                ),

                const SizedBox(height: 16),

                // QR Code placeholder (you'd use qr_flutter package in production)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.scan_barcode,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'QR Code',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Can't scan? Enter this code manually:",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          if (_secret != null) {
                            Clipboard.setData(ClipboardData(text: _secret!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Secret copied to clipboard')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _secret ?? 'XXXX XXXX XXXX XXXX',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Iconsax.copy,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Step 3
                _SetupStep(
                  number: '3',
                  title: 'Enter Verification Code',
                  description: 'Enter the 6-digit code from your authenticator app',
                ),

                const SizedBox(height: 16),

                // Code Input
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: AppTextStyles.h2.copyWith(
                          letterSpacing: 8,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: AppTextStyles.h2.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 8,
                          ),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                PrimaryButton(
                  text: 'Verify and Enable',
                  onPressed: _enable2FA,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isSettingUp = false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],

              if (is2FAEnabled) ...[
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Iconsax.warning_2,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Danger Zone',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Disabling 2FA will make your account less secure.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DangerButton(
                        text: 'Disable Two-Factor Authentication',
                        onPressed: _disable2FA,
                        icon: Iconsax.shield_cross,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _SetupStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}