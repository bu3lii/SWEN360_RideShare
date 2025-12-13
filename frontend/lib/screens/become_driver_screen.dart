import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../widgets/widgets.dart';

class BecomeDriverScreen extends StatefulWidget {
  const BecomeDriverScreen({super.key});

  @override
  State<BecomeDriverScreen> createState() => _BecomeDriverScreenState();
}

class _BecomeDriverScreenState extends State<BecomeDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _userService = UserService();
  int _totalSeats = 4;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _modelController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = await _userService.becomeDriver(
      model: _modelController.text.trim(),
      color: _colorController.text.trim(),
      licensePlate: _licensePlateController.text.trim().toUpperCase(),
      totalSeats: _totalSeats,
    );

    setState(() => _isLoading = false);

    if (user != null && mounted) {
      context.read<AuthProvider>().updateUser(user);
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.tick_circle,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Congratulations!',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 8),
              Text(
                'You are now a driver. Start posting rides and earn money!',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Start Driving'),
              ),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to register as driver. Please verify your email first.'),
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
        title: const Text('Become a Driver'),
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
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.car,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Start Earning as a Driver',
                        style: AppTextStyles.h2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share your rides and help fellow students while earning money',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

                const SizedBox(height: 32),

                // Benefits Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver Benefits',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BenefitItem(
                        icon: Iconsax.money_recive,
                        text: 'Earn money on your daily commute',
                      ),
                      _BenefitItem(
                        icon: Iconsax.calendar,
                        text: 'Flexible schedule - drive when you want',
                      ),
                      _BenefitItem(
                        icon: Iconsax.people,
                        text: 'Meet fellow university students',
                      ),
                      _BenefitItem(
                        icon: Iconsax.global,
                        text: 'Help reduce traffic and emissions',
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Car Details Form
                Text(
                  'Car Details',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 16),

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car Model
                      Text('Car Model', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _modelController,
                        hintText: 'e.g., Toyota Camry 2022',
                        prefixIcon: Iconsax.car,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your car model';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Car Color
                      Text('Car Color', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _colorController,
                        hintText: 'e.g., White',
                        prefixIcon: Iconsax.colorfilter,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your car color';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // License Plate
                      Text('License Plate', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _licensePlateController,
                        hintText: 'e.g., 123456',
                        prefixIcon: Iconsax.card,
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your license plate';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Total Seats
                      Text('Available Seats for Passengers', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _totalSeats > 1
                                ? () => setState(() => _totalSeats--)
                                : null,
                            icon: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _totalSeats > 1
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Iconsax.minus,
                                color: _totalSeats > 1
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '$_totalSeats',
                                style: AppTextStyles.h1.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _totalSeats < 7
                                ? () => setState(() => _totalSeats++)
                                : null,
                            icon: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _totalSeats < 7
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Iconsax.add,
                                color: _totalSeats < 7
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: Text(
                          'seats available for passengers',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Driver Terms & Conditions',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Safety Guidelines',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                const SizedBox(height: 24),

                // Submit Button
                PrimaryButton(
                  text: 'Register as Driver',
                  onPressed: _submitRequest,
                  isLoading: _isLoading,
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}