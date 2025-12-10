import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../services/booking_service.dart';
import '../widgets/widgets.dart';

class PickupConfirmationScreen extends StatefulWidget {
  final Booking booking;

  const PickupConfirmationScreen({
    super.key,
    required this.booking,
  });

  @override
  State<PickupConfirmationScreen> createState() => _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  final _bookingService = BookingService();
  final _riderCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _riderCodeController.dispose();
    super.dispose();
  }

  Future<void> _confirmPickup() async {
    final riderCode = _riderCodeController.text.trim();

    if (riderCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the rider code';
      });
      return;
    }

    if (riderCode.length != 4) {
      setState(() {
        _errorMessage = 'Code must be 4 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _bookingService.markPickedUp(
        widget.booking.id,
        riderCode: riderCode,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passenger marked as picked up successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Invalid code. Please verify with the passenger.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Confirm Pickup',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Security Verification',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter the 4-digit code provided by the passenger to confirm pickup. The passenger will also verify your code.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 32),

            // Passenger Info
            Text(
              'Passenger Details',
              style: AppTextStyles.h3,
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: widget.booking.passenger?.profilePicture != null
                        ? ClipOval(
                            child: Image.network(
                              widget.booking.passenger!.profilePicture!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            widget.booking.passenger?.initials ?? 'P',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.booking.passenger?.name ?? 'Passenger',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.booking.passenger?.phoneNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.booking.passenger!.phoneNumber!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

            const SizedBox(height: 32),

            // Your Code (Driver's Code)
            Text(
              'Your Code (Show to Passenger)',
              style: AppTextStyles.h3,
            ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.booking.driverSafeCode ?? 'N/A',
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.success,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Show this code to the passenger',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  // Debug info (can be removed later)
                  if (widget.booking.driverSafeCode == null || widget.booking.riderSafeCode == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Warning: Safe codes not loaded properly',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms),

            const SizedBox(height: 32),

            // Enter Rider Code
            Text(
              'Enter Passenger Code',
              style: AppTextStyles.h3,
            ).animate().fadeIn(duration: 300.ms, delay: 500.ms),
            const SizedBox(height: 12),
            TextField(
              controller: _riderCodeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '0000',
                hintStyle: AppTextStyles.h2.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _errorMessage != null
                        ? AppColors.error
                        : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _errorMessage != null
                        ? AppColors.error
                        : AppColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                counterText: '',
              ),
              onChanged: (value) {
                setState(() {
                  _errorMessage = null;
                });
              },
            ).animate().fadeIn(duration: 300.ms, delay: 600.ms),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms),
            ],

            const SizedBox(height: 32),

            // Confirm Button
            PrimaryButton(
              text: 'Confirm Pickup',
              icon: Iconsax.tick_circle,
              onPressed: _isLoading ? null : _confirmPickup,
              isLoading: _isLoading,
            ).animate().fadeIn(duration: 300.ms, delay: 700.ms),
          ],
        ),
      ),
    );
  }
}

