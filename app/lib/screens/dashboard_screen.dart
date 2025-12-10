import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../services/ride_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _userService = UserService();
  final _rideService = RideService();
  final _notificationService = NotificationService();
  final _locationService = LocationService();
  
  DashboardData? _dashboardData;
  bool _isLoading = true;
  int _unreadNotifications = 0;
  int _nearbyRidesCount = 0;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadNotificationCount();
    _loadLocationAndNearbyRides();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    
    final result = await _userService.getDashboard();
    
    if (mounted) {
      setState(() {
        _dashboardData = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotificationCount() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() => _unreadNotifications = count);
    }
  }

  Future<void> _loadLocationAndNearbyRides() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Load nearby rides using getAvailableRides with location params
      final rides = await _rideService.getAvailableRides(
        startLat: position.latitude,
        startLng: position.longitude,
      );
      
      if (mounted) {
        setState(() => _nearbyRidesCount = rides.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadDashboard();
            await _loadNotificationCount();
            await _loadLocationAndNearbyRides();
          },
          color: AppColors.primary,
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back!',
                                  style: AppTextStyles.h2.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Where would you like to go?',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Notifications
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/notifications'),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Iconsax.notification,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (_unreadNotifications > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            _unreadNotifications > 9 
                                                ? '9+' 
                                                : _unreadNotifications.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Messages
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/messages'),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Iconsax.message,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Profile
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/profile'),
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: user?.profilePicture != null
                                          ? ClipOval(
                                              child: Image.network(
                                                user!.profilePicture!,
                                                width: 44,
                                                height: 44,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Text(
                                              user?.initials ?? 'U',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.2, end: 0),
                      
                      const SizedBox(height: 24),

                      // Live Map Ribbon
                      MapRibbon(
                        onTap: () => Navigator.pushNamed(context, '/live-map'),
                        nearbyRidesCount: _nearbyRidesCount,
                        currentLocation: _currentLocation,
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 50.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 20),
                      
                      // Current Active Ride Widget
                      if (_dashboardData?.activeRideAsDriver != null) ...[
                        _CurrentRideCard(
                          isDriver: true,
                          ride: _dashboardData!.activeRideAsDriver!,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/driver-ride',
                            arguments: _dashboardData!.activeRideAsDriver!,
                          ),
                        ).animate()
                          .fadeIn(duration: 400.ms, delay: 60.ms)
                          .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 20),
                      ] else if (_dashboardData?.activeRideAsPassenger != null) ...[
                        _CurrentRideCard(
                          isDriver: false,
                          booking: _dashboardData!.activeRideAsPassenger!,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/active-ride',
                            arguments: _dashboardData!.activeRideAsPassenger!,
                          ),
                        ).animate()
                          .fadeIn(duration: 400.ms, delay: 60.ms)
                          .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 20),
                      ],
                      
                      // Action Cards
                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Iconsax.car,
                              title: 'Post a Ride',
                              subtitle: 'Share your trip',
                              color: AppColors.primary,
                              onTap: () => Navigator.pushNamed(context, '/post-ride'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Iconsax.search_normal,
                              title: 'Find Rides',
                              subtitle: 'Search available',
                              color: AppColors.secondary,
                              onTap: () => Navigator.pushNamed(context, '/available-rides'),
                            ),
                          ),
                        ],
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 12),
                      
                      // Quick Actions Row
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Iconsax.receipt_2,
                              label: 'My Bookings',
                              onTap: () => Navigator.pushNamed(context, '/my-bookings'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Iconsax.clock,
                              label: 'History',
                              onTap: () => Navigator.pushNamed(context, '/ride-history'),
                            ),
                          ),
                          if (user?.isDriver == true) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Iconsax.routing,
                                label: 'My Rides',
                                onTap: () => Navigator.pushNamed(context, '/my-rides'),
                              ),
                            ),
                          ],
                        ],
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 150.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 12),
                      
                      // Safety Center Button
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Iconsax.shield_tick,
                              label: 'Safety Center',
                              onTap: () => Navigator.pushNamed(context, '/safety-center'),
                            ),
                          ),
                        ],
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Your Impact Section
                      Text(
                        'Your Impact',
                        style: AppTextStyles.h3,
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms),
                      
                      const SizedBox(height: 12),
                      
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
                        child: Row(
                          children: [
                            Expanded(
                              child: _ImpactItem(
                                icon: Iconsax.car,
                                label: 'Total Rides',
                                value: _dashboardData?.impact.totalRides.toString() ?? '0',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _ImpactItem(
                                icon: Iconsax.money,
                                label: 'Saved',
                                value: '${_dashboardData?.impact.moneySaved.toStringAsFixed(0) ?? '0'} BHD',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _ImpactItem(
                                icon: Iconsax.global,
                                label: 'CO₂ Saved',
                                value: '${_dashboardData?.impact.co2Saved} kg',
                              ),
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 250.ms)
                        .slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Upcoming Rides Section
                      if (_dashboardData?.upcomingRidesAsPassenger.isNotEmpty ?? false) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Upcoming Rides',
                              style: AppTextStyles.h3,
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/my-bookings'),
                              child: const Text('View All'),
                            ),
                          ],
                        ).animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms),
                        
                        const SizedBox(height: 8),
                        
                        ..._dashboardData!.upcomingRidesAsPassenger.take(3).map(
                          (booking) => _UpcomingRideCard(
                            booking: booking,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/booking-details',
                              arguments: booking,
                            ),
                          ).animate()
                            .fadeIn(duration: 400.ms, delay: 350.ms)
                            .slideX(begin: 0.1, end: 0),
                        ),
                      ],

                      // Driver Section
                      if (user?.isDriver == true && 
                          (_dashboardData?.upcomingRidesAsDriver.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Posted Rides',
                              style: AppTextStyles.h3,
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/my-rides'),
                              child: const Text('View All'),
                            ),
                          ],
                        ).animate()
                          .fadeIn(duration: 400.ms, delay: 400.ms),
                        
                        const SizedBox(height: 8),
                        
                        ..._dashboardData!.upcomingRidesAsDriver.take(2).map(
                          (ride) => _DriverRideCard(
                            ride: ride,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/driver-ride',
                              arguments: ride,
                            ),
                          ).animate()
                            .fadeIn(duration: 400.ms, delay: 450.ms)
                            .slideX(begin: 0.1, end: 0),
                        ),
                      ],

                      // Become Driver Banner
                      if (user?.isDriver != true) ...[
                        const SizedBox(height: 24),
                        _BecomeDriverBanner(
                          onTap: () => Navigator.pushNamed(context, '/become-driver'),
                        ).animate()
                          .fadeIn(duration: 400.ms, delay: 500.ms)
                          .slideY(begin: 0.2, end: 0),
                      ],
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ImpactItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(color: AppColors.primary),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _UpcomingRideCard extends StatelessWidget {
  final dynamic booking;
  final VoidCallback onTap;

  const _UpcomingRideCard({
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
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
              child: const Icon(
                Iconsax.car,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Ride',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap to view details',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverRideCard extends StatelessWidget {
  final dynamic ride;
  final VoidCallback onTap;

  const _DriverRideCard({
    required this.ride,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
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
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.driving,
                color: AppColors.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Posted Ride',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Manage passengers',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _BecomeDriverBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _BecomeDriverBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Iconsax.car,
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
                    'Become a Driver',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Earn money on your commute',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.arrow_right_3,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentRideCard extends StatelessWidget {
  final bool isDriver;
  final Ride? ride;
  final Booking? booking;
  final VoidCallback onTap;

  const _CurrentRideCard({
    required this.isDriver,
    this.ride,
    this.booking,
    required this.onTap,
  }) : assert((isDriver && ride != null) || (!isDriver && booking != null));

  @override
  Widget build(BuildContext context) {
    final rideData = isDriver ? ride : booking?.ride;
    if (rideData == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.car,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDriver ? 'Your Ride' : 'Your Booking',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${rideData.startLocation.address.split(',').first} → ${rideData.destination.address.split(',').first}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}