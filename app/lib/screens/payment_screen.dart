import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/booking_service.dart';
import '../widgets/widgets.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  final bool isDriver;

  const PaymentScreen({
    super.key,
    required this.booking,
    this.isDriver = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _bookingService = BookingService();
  Booking? _booking;
  bool _isLoading = true;
  List<Booking>? _allBookings;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadBookingData();
    
    // Refresh booking status every 3 seconds to check for payment status changes
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadBookingData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookingData() async {
    // Don't show loading spinner on refresh (only on initial load)
    if (_booking == null) {
      setState(() => _isLoading = true);
    }

    final booking = await _bookingService.getBooking(widget.booking.id);
    
    if (widget.isDriver && booking?.ride != null) {
      // Load all bookings for the ride to show driver's total
      _allBookings = await _bookingService.getRideBookings(booking!.ride!.id);
    }

    if (mounted) {
      final user = context.read<AuthProvider>().user;
      final isRider = !widget.isDriver && booking?.passengerId == user?.id;
      final wasPaid = _booking?.paymentStatus == 'paid';
      final isNowPaid = booking?.paymentStatus == 'paid';
      
      setState(() {
        _booking = booking ?? widget.booking;
        _isLoading = false;
      });
      
      // If payment status changed to paid and user is a rider, navigate to review
      if (!wasPaid && isNowPaid && isRider && booking != null && booking.ride != null) {
        // Cancel refresh timer since we're navigating away
        _refreshTimer?.cancel();
        
        // Navigate to review screen
        Navigator.pushReplacementNamed(
          context,
          '/create-review',
          arguments: {
            'rideId': booking.ride!.id,
            'bookingId': booking.id,
            'revieweeId': booking.ride!.driverId ?? booking.ride!.driver?.id ?? '',
            'revieweeName': booking.ride!.driver?.name,
          },
        );
      }
    }
  }

  double _calculateDriverTotal() {
    if (_allBookings == null) return 0.0;
    return _allBookings!
        .where((b) => b.status == 'completed')
        .fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking ?? widget.booking;
    final user = context.watch<AuthProvider>().user;
    final isRider = !widget.isDriver && booking.passengerId == user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Details'),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.wallet_money,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isDriver ? 'Driver Earnings' : 'Your Payment',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.status == 'completed'
                          ? 'Ride completed'
                          : 'Payment pending',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Payment Details Card
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
                      'Payment Summary',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 20),

                    if (widget.isDriver) ...[
                      // Driver view - show total from all riders
                      _PaymentRow(
                        label: 'Total from all riders',
                        value: _calculateDriverTotal(),
                        isTotal: true,
                      ),
                      const Divider(height: 32),
                      if (_allBookings != null && _allBookings!.isNotEmpty) ...[
                        Text(
                          'Breakdown by Rider',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._allBookings!
                            .where((b) => b.status == 'completed')
                            .map((b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              b.passenger?.name ?? 'Rider',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '${b.seatsBooked} seat${b.seatsBooked > 1 ? 's' : ''}',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${b.totalAmount.toStringAsFixed(2)} BHD',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                      ],
                    ] else ...[
                      // Rider view - show their share
                      _PaymentRow(
                        label: 'Seats booked',
                        value: booking.seatsBooked.toDouble(),
                        isValue: false,
                        suffix: ' seat${booking.seatsBooked > 1 ? 's' : ''}',
                      ),
                      const SizedBox(height: 12),
                      _PaymentRow(
                        label: 'Price per seat',
                        value: booking.ride?.pricePerSeat ?? 0.0,
                        suffix: ' BHD',
                      ),
                      const Divider(height: 32),
                      _PaymentRow(
                        label: 'Subtotal',
                        value: booking.totalAmount,
                        isTotal: true,
                      ),
                    ],
                  ],
                ),
              ).animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Ride Info Card
              if (booking.ride != null)
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
                        'Ride Information',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Iconsax.location,
                        label: 'From',
                        value: booking.ride!.startLocation.address,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Iconsax.location_tick,
                        label: 'To',
                        value: booking.ride!.destination.address,
                      ),
                      if (booking.pickedUpAt != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Iconsax.clock,
                          label: 'Picked up at',
                          value: booking.pickedUpAt!
                              .toString()
                              .substring(0, 16),
                        ),
                      ],
                      if (booking.droppedOffAt != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Iconsax.tick_circle,
                          label: 'Dropped off at',
                          value: booking.droppedOffAt!
                              .toString()
                              .substring(0, 16),
                        ),
                      ],
                    ],
                  ),
                ).animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Payment Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: booking.paymentStatus == 'paid'
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: booking.paymentStatus == 'paid'
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      booking.paymentStatus == 'paid'
                          ? Iconsax.tick_circle
                          : Iconsax.clock,
                      color: booking.paymentStatus == 'paid'
                          ? AppColors.success
                          : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        booking.paymentStatus == 'paid'
                            ? 'Payment completed'
                            : 'Payment pending',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: booking.paymentStatus == 'paid'
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

class _PaymentRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final bool isValue;
  final String? suffix;

  const _PaymentRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isValue = true,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          isValue
              ? '${value.toStringAsFixed(2)}${suffix ?? ' BHD'}'
              : '${value.toInt()}${suffix ?? ''}',
          style: AppTextStyles.bodyLarge.copyWith(
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 20 : 16,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

