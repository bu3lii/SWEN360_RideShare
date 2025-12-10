import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/booking_service.dart';
import '../widgets/widgets.dart';

class SafeCodeScreen extends StatefulWidget {
  final Booking booking;

  const SafeCodeScreen({
    super.key,
    required this.booking,
  });

  @override
  State<SafeCodeScreen> createState() => _SafeCodeScreenState();
}

class _SafeCodeScreenState extends State<SafeCodeScreen> {
  final _bookingService = BookingService();
  Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    setState(() => _isLoading = true);

    final booking = await _bookingService.getBooking(widget.booking.id);

    if (mounted) {
      setState(() {
        _booking = booking ?? widget.booking;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking ?? widget.booking;
    final user = context.watch<AuthProvider>().user;
    
    // Determine if current user is the rider (passenger) or driver
    // Check both passengerId field and passenger object's id
    final passengerId = booking.passengerId ?? booking.passenger?.id;
    // Check both driverId field and ride.driver object's id
    final driverId = booking.ride?.driverId ?? booking.ride?.driver?.id;
    
    final isRider = passengerId == user?.id;
    final isDriver = driverId == user?.id;
    
    // Driver should see their own code (driverSafeCode), rider should see their own code (riderSafeCode)
    final safeCode = isRider ? booking.riderSafeCode : booking.driverSafeCode;
    final otherCode = isRider ? booking.driverSafeCode : booking.riderSafeCode;
    
    // Debug: Log to help identify issues
    debugPrint('Safe Code Screen - User ID: ${user?.id}');
    debugPrint('Safe Code Screen - Passenger ID: $passengerId (from field: ${booking.passengerId}, from object: ${booking.passenger?.id})');
    debugPrint('Safe Code Screen - Driver ID: $driverId (from field: ${booking.ride?.driverId}, from object: ${booking.ride?.driver?.id})');
    debugPrint('Safe Code Screen - isRider: $isRider, isDriver: $isDriver');
    debugPrint('Safe Code Screen - Rider code: ${booking.riderSafeCode}, Driver code: ${booking.driverSafeCode}');
    debugPrint('Safe Code Screen - Showing code: $safeCode, Other code: $otherCode');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safe Code'),
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
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.shield_tick,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Security Verification',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your code with ${isRider ? 'the driver' : 'the rider'} to verify your identity',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Your Code Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                  children: [
                    Text(
                      'Your Safe Code',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          safeCode ?? 'N/A',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primary,
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Show this code to ${isRider ? 'your driver' : 'your rider'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Verification Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'How to verify',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _VerificationStep(
                      step: 1,
                      text: 'Share your code with ${isRider ? 'the driver' : 'the rider'}',
                    ),
                    const SizedBox(height: 8),
                    _VerificationStep(
                      step: 2,
                      text: 'Ask them to share their code with you',
                    ),
                    const SizedBox(height: 8),
                    _VerificationStep(
                      step: 3,
                      text: 'Match the codes to verify each other\'s identity',
                    ),
                  ],
                ),
              ).animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Other Party's Code (if available)
              if (otherCode != null)
                Container(
                  width: double.infinity,
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
                      Text(
                        '${isRider ? 'Driver' : 'Rider'}\'s Code',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            otherCode,
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.success,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Iconsax.tick_circle,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Codes match! Identity verified',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate()
                    .fadeIn(duration: 400.ms, delay: 300.ms)
                    .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  final int step;
  final String text;

  const _VerificationStep({
    required this.step,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
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
    );
  }
}

