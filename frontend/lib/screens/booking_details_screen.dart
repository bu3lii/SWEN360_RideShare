import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/booking_service.dart';
import '../services/message_service.dart';
import '../widgets/widgets.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _bookingService = BookingService();
  final _messageService = MessageService();
  Booking? _booking;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
    
    // Refresh booking status every 5 seconds to check for pickup
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadBookingDetails();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookingDetails() async {
    setState(() => _isLoading = true);

    final booking = await _bookingService.getBooking(widget.booking.id);

    if (mounted) {
      final wasCompleted = _booking?.status == 'completed';
      final isNowCompleted = booking?.status == 'completed';
      final user = context.read<AuthProvider>().user;
      final isRider = booking?.passengerId == user?.id;
      
      setState(() {
        _booking = booking ?? widget.booking;
        _isLoading = false;
      });
      
      // If just completed and user is a rider, navigate to payment screen
      if (!wasCompleted && isNowCompleted && isRider && booking != null) {
        Navigator.pushReplacementNamed(
          context,
          '/payment',
          arguments: {
            'booking': booking,
            'isDriver': false,
          },
        );
      }
      
      // If payment status changed to paid and user is a rider, navigate to review
      final wasPaid = _booking?.paymentStatus == 'paid';
      final isNowPaid = booking?.paymentStatus == 'paid';
      if (!wasPaid && isNowPaid && isRider && booking != null && booking.ride != null) {
        // Navigate to review screen
        Navigator.pushNamed(
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

  Future<void> _messageDriver() async {
    if (_booking?.ride?.driver?.id == null) return;

    // Find existing conversation or create new one
    final conversations = await _messageService.getConversations();
    Conversation? existingConversation;

    for (var conv in conversations) {
      if (conv.participant?.oderId == _booking!.ride!.driver!.id) {
        existingConversation = conv;
        break;
      }
    }

    if (existingConversation != null) {
      // Navigate to existing conversation
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: existingConversation,
        );
      }
    } else {
      // Create new conversation by sending an initial message
      final message = await _messageService.sendMessage(
        recipientId: _booking!.ride!.driver!.id,
        content: 'Hi! I have a question about my booking.',
        rideId: _booking!.ride!.id,
      );

      if (message != null && mounted) {
        // Reload conversations to get the new one
        final updatedConversations = await _messageService.getConversations();
        final newConversation = updatedConversations.firstWhere(
          (conv) => conv.participant?.oderId == _booking!.ride!.driver?.id,
          orElse: () => updatedConversations.first,
        );

        Navigator.pushNamed(
          context,
          '/chat',
          arguments: newConversation,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start conversation'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _verifyDriverCode() async {
    if (_booking == null) return;

    final driverCodeController = TextEditingController();
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Iconsax.shield_tick, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text('Verify Driver Code'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the 4-digit code shown by the driver to verify their identity.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Code (Show to Driver)',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    _booking!.riderSafeCode ?? 'N/A',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Driver Code',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: driverCodeController,
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
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: errorMessage != null
                          ? AppColors.error
                          : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: errorMessage != null
                          ? AppColors.error
                          : AppColors.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  counterText: '',
                ),
                onChanged: (value) {
                  setDialogState(() {
                    errorMessage = null;
                  });
                },
              ),
              if (errorMessage != null) ...[
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
                          errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = driverCodeController.text.trim();
                
                if (code.isEmpty) {
                  setDialogState(() {
                    errorMessage = 'Please enter the driver code';
                  });
                  return;
                }
                
                if (code.length != 4) {
                  setDialogState(() {
                    errorMessage = 'Code must be 4 digits';
                  });
                  return;
                }
                
                // Verify driver code
                if (code != _booking!.driverSafeCode) {
                  setDialogState(() {
                    errorMessage = 'Invalid code. Please verify with the driver.';
                  });
                  return;
                }
                
                // Code is correct
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Driver code verified!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelBookingDialog(),
    );

    if (reason == null) return;

    final success = await _bookingService.cancelBooking(
      _booking!.id,
      reason: reason,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadBookingDetails();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel booking'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color get _statusColor {
    switch (_booking?.status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _statusText {
    // Check if picked up (even if status is still 'confirmed')
    if (_booking?.pickedUpAt != null) {
      return 'Picked Up';
    }
    
    switch (_booking?.status) {
      case 'pending':
        return 'Pending Driver Approval';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking ?? widget.booking;
    final ride = booking.ride;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadBookingDetails();
            // Small delay to show refresh animation
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _booking?.status == 'pending'
                            ? Iconsax.clock
                            : _booking?.status == 'confirmed'
                                ? Iconsax.tick_circle
                                : _booking?.status == 'completed'
                                    ? Iconsax.check
                                    : Iconsax.close_circle,
                        color: _statusColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusText,
                              style: AppTextStyles.h3.copyWith(
                                color: _statusColor,
                              ),
                            ),
                            if (_booking?.status == 'pending')
                              Text(
                                'Waiting for driver to accept your booking request',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              )
                            else if (_booking?.pickedUpAt != null)
                              Text(
                                'You were picked up on ${DateFormat('MMM dd, yyyy • h:mm a').format(_booking!.pickedUpAt!)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              )
                            else if (_booking?.status == 'confirmed')
                              Text(
                                'Your booking is confirmed. Waiting for pickup.',
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

                // Ride Details Card
                if (ride != null) ...[
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
                        const SizedBox(height: 20),

                        // Route
                        _DetailRow(
                          icon: Iconsax.location,
                          iconColor: AppColors.success,
                          label: 'Pickup',
                          value: ride.startLocation.address,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: Iconsax.location_tick,
                          iconColor: AppColors.error,
                          label: 'Destination',
                          value: ride.destination.address,
                        ),
                        const Divider(height: 32),
                        _DetailRow(
                          icon: Iconsax.calendar,
                          iconColor: AppColors.primary,
                          label: 'Departure Time',
                          value: DateFormat('MMM dd, yyyy • h:mm a')
                              .format(ride.departureTime),
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Iconsax.people,
                          iconColor: AppColors.secondary,
                          label: 'Seats Booked',
                          value: '${booking.seatsBooked} seat${booking.seatsBooked > 1 ? 's' : ''}',
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Iconsax.dollar_circle,
                          iconColor: AppColors.warning,
                          label: 'Total Amount',
                          value: booking.formattedAmount,
                        ),
                      ],
                    ),
                  ).animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  // Driver Info Card
                  if (ride.driver != null)
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
                            'Driver',
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: ride.driver!.profilePicture != null
                                    ? ClipOval(
                                        child: Image.network(
                                          ride.driver!.profilePicture!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Text(
                                        ride.driver!.initials,
                                        style: AppTextStyles.h3.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ride.driver!.name,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Iconsax.star1,
                                          color: AppColors.rating,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${ride.driver!.rating.average.toStringAsFixed(1)} (${ride.driver!.rating.count})',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (ride.driver!.carDetails != null) ...[
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Iconsax.car,
                              iconColor: AppColors.secondary,
                              label: 'Car',
                              value:
                                  '${ride.driver!.carDetails!.model} - ${ride.driver!.carDetails!.color}',
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Iconsax.card,
                              iconColor: AppColors.secondary,
                              label: 'License Plate',
                              value: ride.driver!.carDetails!.licensePlate,
                            ),
                          ],
                        ],
                      ),
                    ).animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),
                ],

                // Pickup Location (if different)
                if (booking.pickupLocation != null &&
                    booking.pickupLocation!.address != ride?.startLocation.address)
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
                          'Your Pickup Location',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Iconsax.location,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                booking.pickupLocation!.address,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Action Buttons
                // Show "View Active Ride" if ride is in progress
                if (ride?.status == 'in_progress' && 
                    (booking.status == 'confirmed' || booking.status == 'picked_up')) ...[
                  PrimaryButton(
                    text: 'View Active Ride',
                    icon: Iconsax.map,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/active-ride',
                        arguments: booking,
                      );
                    },
                  ).animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms)
                    .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                ] else if (booking.status == 'pending' || booking.status == 'confirmed') ...[
                  PrimaryButton(
                    text: 'Message Driver',
                    icon: Iconsax.message,
                    onPressed: _messageDriver,
                  ).animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms)
                    .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                ],

                // Verify Driver Code Button (when ride is in progress and not picked up)
                if (booking.status == 'confirmed' && 
                    ride?.status == 'in_progress' && 
                    booking.pickedUpAt == null &&
                    context.read<AuthProvider>().user?.id == booking.passengerId) ...[
                  OutlinedButton.icon(
                    onPressed: _verifyDriverCode,
                    icon: const Icon(Iconsax.shield_tick),
                    label: const Text('Verify Driver Code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ).animate()
                      .fadeIn(duration: 400.ms, delay: 450.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                ],

                // Safe Code Button (available when confirmed or completed)
                if (booking.status == 'confirmed' || booking.status == 'completed') ...[
                  PrimaryButton(
                    text: 'View Safe Code',
                    icon: Iconsax.shield_tick,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/safe-code',
                        arguments: booking,
                      );
                    },
                  ).animate()
                      .fadeIn(duration: 400.ms, delay: 500.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                ],

                // Payment Button (available when completed)
                if (booking.status == 'completed') ...[
                  PrimaryButton(
                    text: 'View Payment',
                    icon: Iconsax.wallet_money,
                    onPressed: () {
                      final user = context.read<AuthProvider>().user;
                      final isDriver = ride?.driverId == user?.id;
                      Navigator.pushNamed(
                        context,
                        '/payment',
                        arguments: {
                          'booking': booking,
                          'isDriver': isDriver,
                        },
                      );
                    },
                  ).animate()
                      .fadeIn(duration: 400.ms, delay: 500.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                ],

                if (booking.canCancel) ...[
                  DangerButton(
                    text: 'Cancel Booking',
                    icon: Iconsax.close_circle,
                    onPressed: _cancelBooking,
                  ).animate()
                      .fadeIn(duration: 400.ms, delay: 550.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                ],

                if (booking.canReview) ...[
                  PrimaryButton(
                    text: 'Leave Review',
                    icon: Iconsax.star,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/create-review',
                        arguments: {
                          'rideId': booking.rideId,
                          'bookingId': booking.id,
                          'revieweeId': ride?.driver?.id,
                          'revieweeName': ride?.driver?.name,
                        },
                      );
                    },
                  ).animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms)
                      .slideY(begin: 0.2, end: 0),
                ],

                const SizedBox(height: 20),
              ],
            ),
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
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CancelBookingDialog extends StatefulWidget {
  @override
  State<_CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<_CancelBookingDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Booking'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please provide a reason for cancellation:'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter reason...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Booking'),
        ),
        TextButton(
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide a reason')),
              );
              return;
            }
            Navigator.pop(context, reason);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Cancel Booking'),
        ),
      ],
    );
  }
}

