import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../services/ride_service.dart';
import '../widgets/widgets.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _rideService = RideService();
  List<Ride> _rides = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadRides();
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
        _selectedStatus = 'scheduled';
        break;
      case 2:
        _selectedStatus = 'in_progress';
        break;
      case 3:
        _selectedStatus = 'completed';
        break;
    }
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() => _isLoading = true);

    final rides = await _rideService.getMyRides(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
    );

    if (mounted) {
      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    }
  }

  Future<void> _startRide(Ride ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Ride'),
        content: const Text('Are you sure you want to start this ride?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _rideService.startRide(ride.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride started!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadRides();
      }
    }
  }

  Future<void> _completeRide(Ride ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Ride'),
        content: const Text('Are you sure you want to mark this ride as completed?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _rideService.completeRide(ride.id);

      if (mounted) {
        if (result != null) {
          // Show completion summary screen for driver
          Navigator.pushReplacementNamed(
            context,
            '/ride-completion',
            arguments: {
              'ride': result['ride'] as Ride,
              'totalEarnings': result['driverTotalEarnings'] as double,
              'bookings': result['bookings'] as List<Booking>,
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to complete ride'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelRide(Ride ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text(
          'Are you sure you want to cancel this ride? All passengers will be notified.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Ride'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _rideService.cancelRide(ride.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride cancelled'),
            backgroundColor: AppColors.warning,
          ),
        );
        _loadRides();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Rides'),
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
            Tab(text: 'Scheduled'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/post-ride'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.add),
        label: const Text('Post Ride'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRides,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: LoadingIndicator())
            : _rides.isEmpty
                ? _EmptyState(status: _selectedStatus)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rides.length,
                    itemBuilder: (context, index) {
                      final ride = _rides[index];
                      return _RideCard(
                        ride: ride,
                        onStart: () => _startRide(ride),
                        onComplete: () => _completeRide(ride),
                        onCancel: () => _cancelRide(ride),
                        onViewBookings: () => Navigator.pushNamed(
                          context,
                          '/ride-bookings',
                          arguments: ride,
                        ),
                        onEdit: () => Navigator.pushNamed(
                          context,
                          '/edit-ride',
                          arguments: ride,
                        ),
                        onViewMap: () => Navigator.pushNamed(
                          context,
                          '/driver-ride',
                          arguments: ride,
                        ),
                      ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.1, end: 0);
                    },
                  ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onViewBookings;
  final VoidCallback onEdit;
  final VoidCallback onViewMap;

  const _RideCard({
    required this.ride,
    required this.onStart,
    required this.onComplete,
    required this.onCancel,
    required this.onViewBookings,
    required this.onEdit,
    required this.onViewMap,
  });

  Color get _statusColor {
    switch (ride.status) {
      case 'scheduled':
        return AppColors.primary;
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _statusText {
    switch (ride.status) {
      case 'scheduled':
        return 'SCHEDULED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return ride.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Padding(
            padding: const EdgeInsets.all(16),
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
                        _statusText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      ride.formattedPrice,
                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Route
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          color: AppColors.border,
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.startLocation.address,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            ride.destination.address,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Details Row
                Row(
                  children: [
                    _DetailChip(
                      icon: Iconsax.calendar,
                      text: DateFormat('MMM dd').format(ride.departureTime),
                    ),
                    const SizedBox(width: 8),
                    _DetailChip(
                      icon: Iconsax.clock,
                      text: DateFormat('HH:mm').format(ride.departureTime),
                    ),
                    const SizedBox(width: 8),
                    _DetailChip(
                      icon: Iconsax.people,
                      text: '${ride.bookedSeats}/${ride.totalSeats}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (ride.status == 'scheduled') ...[
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onViewMap,
                      icon: const Icon(Iconsax.map, size: 18),
                      label: const Text('Map'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Iconsax.play, size: 18),
                      label: const Text('Start'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Iconsax.close_circle, size: 18),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
                ] else if (ride.status == 'in_progress') ...[
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onViewMap,
                      icon: const Icon(Iconsax.map, size: 18),
                      label: const Text('Navigate'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onViewBookings,
                      icon: const Icon(Iconsax.people, size: 18),
                      label: const Text('Passengers'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Iconsax.tick_circle, size: 18),
                      label: const Text('Complete'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onViewBookings,
                      icon: const Icon(Iconsax.people, size: 18),
                      label: const Text('View Passengers'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
            Iconsax.car,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            status == 'all'
                ? 'No rides posted yet'
                : 'No ${status.replaceAll('_', ' ')} rides',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Post a ride to get started',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/post-ride'),
            icon: const Icon(Iconsax.add),
            label: const Text('Post a Ride'),
          ),
        ],
      ),
    );
  }
}