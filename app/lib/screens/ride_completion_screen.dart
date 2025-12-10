import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/booking_service.dart';

class RideCompletionScreen extends StatefulWidget {
  final Ride ride;
  final double totalEarnings;
  final List<Booking> bookings;

  const RideCompletionScreen({
    super.key,
    required this.ride,
    required this.totalEarnings,
    required this.bookings,
  });

  @override
  State<RideCompletionScreen> createState() => _RideCompletionScreenState();
}

class _RideCompletionScreenState extends State<RideCompletionScreen> {
  final _bookingService = BookingService();
  bool _isMarkingPaid = false;

  Future<void> _markPaid(Booking booking) async {
    if (_isMarkingPaid) return;
    setState(() => _isMarkingPaid = true);

    final success = await _bookingService.markPaid(booking.id);

    if (!mounted) return;
    setState(() => _isMarkingPaid = false);

    if (success) {
      setState(() {
        final idx = widget.bookings.indexWhere((b) => b.id == booking.id);
        if (idx != -1) {
          widget.bookings[idx] = Booking(
            id: booking.id,
            ride: booking.ride,
            rideId: booking.rideId,
            passenger: booking.passenger,
            passengerId: booking.passengerId,
            seatsBooked: booking.seatsBooked,
            pickupLocation: booking.pickupLocation,
            totalAmount: booking.totalAmount,
            paymentStatus: 'paid',
            paymentMethod: booking.paymentMethod,
            status: booking.status,
            cancellationReason: booking.cancellationReason,
            cancelledBy: booking.cancelledBy,
            cancelledAt: booking.cancelledAt,
            confirmedAt: booking.confirmedAt,
            confirmedBy: booking.confirmedBy,
            pickedUpAt: booking.pickedUpAt,
            droppedOffAt: booking.droppedOffAt,
            hasReviewed: booking.hasReviewed,
            reviewId: booking.reviewId,
            specialRequests: booking.specialRequests,
            riderSafeCode: booking.riderSafeCode,
            driverSafeCode: booking.driverSafeCode,
            createdAt: booking.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment marked as received. Please leave a review.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushNamed(
        context,
        '/create-review',
        arguments: {
          'rideId': booking.rideId ?? booking.ride?.id ?? '',
          'bookingId': booking.id,
          'revieweeId': booking.passengerId ?? booking.passenger?.id ?? '',
          'revieweeName': booking.passenger?.name,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark as paid'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.tick_circle,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ride Completed!',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you for driving safely',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

              const SizedBox(height: 32),

              // Earnings Summary
              Text(
                'Earnings Summary',
                style: AppTextStyles.h2,
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Earnings',
                          style: AppTextStyles.h3,
                        ),
                        Text(
                          '${widget.totalEarnings.toStringAsFixed(2)} BHD',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    if (widget.bookings.isNotEmpty) ...[
                      Text(
                        'Breakdown by Rider',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...widget.bookings.map((booking) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: booking.passenger?.profilePicture != null
                                          ? ClipOval(
                                              child: Image.network(
                                                booking.passenger!.profilePicture!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Text(
                                              booking.passenger?.initials ?? 'R',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            booking.passenger?.name ?? 'Rider',
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${booking.seatsBooked} seat${booking.seatsBooked > 1 ? 's' : ''}',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${booking.totalAmount.toStringAsFixed(2)} BHD',
                                          style: AppTextStyles.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: booking.paymentStatus == 'paid'
                                                ? AppColors.success.withOpacity(0.1)
                                                : AppColors.warning.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            booking.paymentStatus == 'paid' ? 'Paid' : 'Unpaid',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: booking.paymentStatus == 'paid'
                                                  ? AppColors.success
                                                  : AppColors.warning,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (booking.paymentStatus != 'paid') ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _isMarkingPaid ? null : () => _markPaid(booking),
                                      icon: const Icon(Iconsax.wallet_money),
                                      label: Text(_isMarkingPaid ? 'Marking...' : 'Mark as Paid'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(color: AppColors.primary),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Ride Details
              Text(
                'Ride Details',
                style: AppTextStyles.h2,
              ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
              const SizedBox(height: 16),
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
                    _DetailRow(
                      icon: Iconsax.location,
                      iconColor: AppColors.primary,
                      label: 'From',
                      value: widget.ride.startLocation.address,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Iconsax.location_tick,
                      iconColor: AppColors.success,
                      label: 'To',
                      value: widget.ride.destination.address,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Iconsax.calendar,
                      iconColor: AppColors.secondary,
                      label: 'Date',
                      value: DateFormat('MMM dd, yyyy • h:mm a').format(widget.ride.departureTime),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Iconsax.dollar_circle,
                      iconColor: AppColors.warning,
                      label: 'Price per seat',
                      value: '${widget.ride.pricePerSeat.toStringAsFixed(2)} BHD',
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),

              // Action Buttons
              PrimaryButton(
                text: 'View Payment Details',
                icon: Iconsax.wallet_money,
                onPressed: () {
                  // Navigate to payment screen with first booking (driver view)
                  if (widget.bookings.isNotEmpty) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/payment',
                      arguments: {
                        'booking': widget.bookings.first,
                        'isDriver': true,
                      },
                    );
                  }
                },
              ).animate().fadeIn(duration: 300.ms, delay: 500.ms),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back to Dashboard'),
              ).animate().fadeIn(duration: 300.ms, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

