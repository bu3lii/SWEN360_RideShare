import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../config/theme.dart';
import '../models/models.dart';
import '../services/booking_service.dart';
import '../widgets/widgets.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _bookingService = BookingService();
  List<Booking> _bookings = [];
  BookingStats? _stats;
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadBookings();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    switch (_tabController.index) {
      case 0:
        _selectedStatus = 'all';
        break;
      case 1:
        _selectedStatus = 'pending';
        break;
      case 2:
        _selectedStatus = 'confirmed';
        break;
      case 3:
        _selectedStatus = 'completed';
        break;
    }
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    final bookings = await _bookingService.getMyBookings(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
    );

    if (mounted) {
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    final stats = await _bookingService.getBookingStats();
    if (mounted && stats != null) {
      setState(() => _stats = stats);
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelBookingDialog(),
    );

    if (reason == null) return;

    final success = await _bookingService.cancelBooking(
      booking.id,
      reason: reason,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadBookings();
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Summary
          if (_stats != null)
            Container(
              margin: const EdgeInsets.all(16),
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
                  Expanded(
                    child: _StatItem(
                      label: 'Total',
                      value: _stats!.totalBookings.toString(),
                      color: AppColors.primary,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: _StatItem(
                      label: 'Completed',
                      value: _stats!.completedBookings.toString(),
                      color: AppColors.success,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: _StatItem(
                      label: 'Spent',
                      value: '${_stats!.totalSpent.toStringAsFixed(1)} BHD',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

          // Bookings List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadBookings,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: LoadingIndicator())
                  : _bookings.isEmpty
                      ? _EmptyState(status: _selectedStatus)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            return _BookingCard(
                              booking: booking,
                              onCancel: () => _cancelBooking(booking),
                              onReview: () => Navigator.pushNamed(
                                context,
                                '/create-review',
                                arguments: booking,
                              ),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/booking-details',
                                arguments: booking,
                              ),
                            ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.1, end: 0);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCancel;
  final VoidCallback onReview;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.onReview,
    required this.onTap,
  });

  Color get _statusColor {
    switch (booking.status) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeago.format(booking.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Route Info
            if (booking.ride != null) ...[
              Row(
                children: [
                  const Icon(
                    Iconsax.location,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.ride!.startLocation.address,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: 2,
                  height: 16,
                  color: AppColors.border,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Iconsax.location_tick,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.ride!.destination.address,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date & Details
              Row(
                children: [
                  const Icon(
                    Iconsax.calendar,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy • HH:mm').format(booking.ride!.departureTime),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Iconsax.people,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${booking.seatsBooked} seat${booking.seatsBooked > 1 ? 's' : ''}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 24),

            // Bottom Row
            Row(
              children: [
                Text(
                  booking.formattedAmount,
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
                const Spacer(),
                if (booking.canCancel)
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                if (booking.canReview)
                  TextButton(
                    onPressed: onReview,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Review'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String status;

  const _EmptyState({required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.receipt_2,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            status == 'all'
                ? 'No bookings yet'
                : 'No $status bookings',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your bookings will appear here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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