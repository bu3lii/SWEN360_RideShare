import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../services/location_service.dart';
import '../widgets/widgets.dart';

class LiveMapScreen extends StatefulWidget {
  final Ride? selectedRide;

  const LiveMapScreen({super.key, this.selectedRide});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final RideService _rideService = RideService();
  
  Position? _currentPosition;
  List<Ride> _nearbyRides = [];
  bool _isLoading = true;
  bool _isTrackingLocation = false;
  StreamSubscription<Position>? _positionSubscription;
  Ride? _selectedRide;
  Timer? _refreshTimer;
  List<LatLng> _selectedRoutePoints = []; // Route points for selected ride

  // Bahrain center coordinates
  static const LatLng _bahrainCenter = LatLng(26.0667, 50.5577);

  @override
  void initState() {
    super.initState();
    _selectedRide = widget.selectedRide;
    _initializeMap();
    
    // Refresh rides every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadNearbyRides();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    try {
      final position = await _locationService.getCurrentLocation()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (position != null) {
        _currentPosition = position;
      }
      await _loadNearbyRides();
    } catch (e) {
      debugPrint('Error initializing map: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (_selectedRide != null) {
        _centerOnRide(_selectedRide!);
      } else if (_currentPosition != null) {
        _centerOnCurrentLocation();
      }
    }
  }

  Future<void> _loadNearbyRides() async {
    try {
      final rides = await _rideService.getAvailableRides(
        startLat: _currentPosition?.latitude ?? _bahrainCenter.latitude,
        startLng: _currentPosition?.longitude ?? _bahrainCenter.longitude,
      );
      if (mounted) {
        setState(() => _nearbyRides = rides);
      }
    } catch (e) {
      debugPrint('Error loading rides: $e');
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        14,
      );
    }
  }

  void _centerOnRide(Ride ride) {
    final centerLat = (ride.startLocation.coordinates.lat + 
                       ride.destination.coordinates.lat) / 2;
    final centerLng = (ride.startLocation.coordinates.lng + 
                       ride.destination.coordinates.lng) / 2;
    _mapController.move(LatLng(centerLat, centerLng), 12);
  }

  void _toggleLocationTracking() {
    if (_isTrackingLocation) {
      _positionSubscription?.cancel();
      setState(() => _isTrackingLocation = false);
    } else {
      _positionSubscription = _locationService.startLocationTracking().listen(
        (position) {
          if (mounted) {
            setState(() => _currentPosition = position);
            _mapController.move(
              LatLng(position.latitude, position.longitude),
              _mapController.camera.zoom,
            );
          }
        },
      );
      setState(() => _isTrackingLocation = true);
      _centerOnCurrentLocation();
    }
  }

  void _onRideMarkerTap(Ride ride) {
    setState(() => _selectedRide = ride);
    _calculateRouteForRide(ride);
    _showRideBottomSheet(ride);
  }

  Future<void> _calculateRouteForRide(Ride ride) async {
    try {
      final route = await _locationService.calculateRoute(
        ride.startLocation.coordinates,
        ride.destination.coordinates,
      );
      if (route != null && mounted) {
        setState(() {
          _selectedRoutePoints = route.routePoints
              .map((c) => LatLng(c.lat, c.lng))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
      // Fallback to straight line
      setState(() {
        _selectedRoutePoints = [
          LatLng(ride.startLocation.coordinates.lat, ride.startLocation.coordinates.lng),
          LatLng(ride.destination.coordinates.lat, ride.destination.coordinates.lng),
        ];
      });
    }
  }

  void _showRideBottomSheet(Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RideDetailsSheet(
        ride: ride,
        onBook: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/booking-confirmation', arguments: ride);
        },
        onViewDriver: () {
          Navigator.pop(context);
          if (ride.driver != null) {
            Navigator.pushNamed(context, '/user-profile', arguments: ride.driver!.id);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _bahrainCenter,
              initialZoom: 13,
              minZoom: 10,
              maxZoom: 18,
              onTap: (_, __) => setState(() {
                _selectedRide = null;
                _selectedRoutePoints = [];
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.uniride',
              ),
              
              // Route polyline for selected ride
              if (_selectedRide != null && _selectedRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _selectedRoutePoints,
                      strokeWidth: 4,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              
              // All markers
              MarkerLayer(
                markers: [
                  // Current location marker
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 40,
                      height: 40,
                      child: _CurrentLocationMarker(isTracking: _isTrackingLocation),
                    ),
                  
                  // Ride pickup markers
                  ..._nearbyRides.map((ride) => Marker(
                    point: LatLng(ride.startLocation.coordinates.lat,
                                  ride.startLocation.coordinates.lng),
                    width: _selectedRide?.id == ride.id ? 60 : 44,
                    height: _selectedRide?.id == ride.id ? 60 : 44,
                    child: GestureDetector(
                      onTap: () => _onRideMarkerTap(ride),
                      child: _RideMarker(
                        ride: ride, 
                        isSelected: _selectedRide?.id == ride.id,
                      ),
                    ),
                  )),
                  
                  // Selected ride destination marker
                  if (_selectedRide != null)
                    Marker(
                      point: LatLng(_selectedRide!.destination.coordinates.lat,
                                    _selectedRide!.destination.coordinates.lng),
                      width: 44,
                      height: 50,
                      child: const _DestinationMarker(),
                    ),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(child: LoadingIndicator()),
            ),

          // Top bar with back button and search
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Search bar
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/available-rides'),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Iconsax.search_normal, 
                              color: AppColors.textSecondary, 
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Where to?',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FABs on right side
          Positioned(
            right: 16,
            bottom: _selectedRide != null ? 220 : 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Refresh button
                FloatingActionButton.small(
                  heroTag: 'refresh',
                  backgroundColor: Colors.white,
                  elevation: 4,
                  onPressed: () {
                    _loadNearbyRides();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshing rides...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(Iconsax.refresh, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                // Location tracking button
                FloatingActionButton.small(
                  heroTag: 'tracking',
                  backgroundColor: _isTrackingLocation ? AppColors.primary : Colors.white,
                  elevation: 4,
                  onPressed: _toggleLocationTracking,
                  child: Icon(
                    _isTrackingLocation ? Iconsax.gps5 : Iconsax.gps,
                    color: _isTrackingLocation ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                // Center on location button
                FloatingActionButton.small(
                  heroTag: 'center',
                  backgroundColor: Colors.white,
                  elevation: 4,
                  onPressed: _centerOnCurrentLocation,
                  child: const Icon(Iconsax.location, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Bottom card - ride count or selected ride
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: _selectedRide == null
                ? _RideCountCard(
                    count: _nearbyRides.length,
                    onViewAll: () => Navigator.pushNamed(context, '/available-rides'),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0)
                : _QuickRideCard(
                    ride: _selectedRide!,
                    onTap: () => _showRideBottomSheet(_selectedRide!),
                    onBook: () {
                      Navigator.pushNamed(
                        context, 
                        '/booking-confirmation', 
                        arguments: _selectedRide,
                      );
                    },
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM MARKERS
// ============================================================================

class _CurrentLocationMarker extends StatelessWidget {
  final bool isTracking;

  const _CurrentLocationMarker({required this.isTracking});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse animation when tracking
        if (isTracking)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.2),
            ),
          ).animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1000.ms)
            .fadeOut(duration: 1000.ms),
        // Main dot
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RideMarker extends StatelessWidget {
  final Ride ride;
  final bool isSelected;

  const _RideMarker({required this.ride, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isSelected ? 10 : 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(isSelected ? 16 : 12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? AppColors.primary : Colors.black).withOpacity(0.2),
            blurRadius: isSelected ? 15 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.car,
            size: isSelected ? 22 : 18,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          if (isSelected) ...[
            const SizedBox(height: 2),
            Text(
              '${ride.pricePerSeat.toStringAsFixed(1)} BD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Iconsax.flag, color: Colors.white, size: 18),
        ),
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BOTTOM CARDS
// ============================================================================

class _RideCountCard extends StatelessWidget {
  final int count;
  final VoidCallback onViewAll;

  const _RideCountCard({required this.count, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.car, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count > 0 ? '$count rides nearby' : 'No rides available',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  count > 0 ? 'Tap a marker to view details' : 'Check back later or post a ride',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onViewAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }
}

class _QuickRideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const _QuickRideCard({
    required this.ride,
    required this.onTap,
    required this.onBook,
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Driver info row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    ride.driver?.initials ?? 'D',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.driver?.name ?? 'Driver',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Iconsax.star1, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            ride.driver?.rating?.average.toStringAsFixed(1) ?? '0.0',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Iconsax.clock, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('h:mm a').format(ride.departureTime),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${ride.pricePerSeat.toStringAsFixed(1)} BD',
                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                    ),
                    Text(
                      '${ride.availableSeats} seats',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Route info row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Iconsax.location, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ride.startLocation.address,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Iconsax.arrow_right_3, size: 16, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Iconsax.location_tick, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ride.destination.address,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ride.availableSeats > 0 ? onBook : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.3),
                ),
                child: Text(ride.availableSeats > 0 ? 'Book Now' : 'Fully Booked'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// RIDE DETAILS BOTTOM SHEET
// ============================================================================

class _RideDetailsSheet extends StatelessWidget {
  final Ride ride;
  final VoidCallback onBook;
  final VoidCallback onViewDriver;

  const _RideDetailsSheet({
    required this.ride,
    required this.onBook,
    required this.onViewDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Driver info section
            GestureDetector(
              onTap: onViewDriver,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: ride.driver?.profilePicture != null
                        ? ClipOval(
                            child: Image.network(
                              ride.driver!.profilePicture!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                ride.driver?.initials ?? 'D',
                                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                              ),
                            ),
                          )
                        : Text(
                            ride.driver?.initials ?? 'D',
                            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ride.driver?.name ?? 'Driver',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (ride.driver?.isDriver == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Verified',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Iconsax.star1, size: 16, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              '${ride.driver?.rating?.average.toStringAsFixed(1) ?? '0.0'} (${ride.driver?.rating?.count ?? 0} reviews)',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Iconsax.arrow_right_3, color: AppColors.textSecondary),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Route info container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Pickup
                  _RoutePoint(
                    icon: Iconsax.location,
                    iconColor: AppColors.primary,
                    label: 'Pickup',
                    address: ride.startLocation.address,
                  ),
                  // Connection line
                  Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 30,
                          color: AppColors.border,
                        ),
                      ],
                    ),
                  ),
                  // Destination
                  _RoutePoint(
                    icon: Iconsax.location_tick,
                    iconColor: AppColors.success,
                    label: 'Destination',
                    address: ride.destination.address,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Trip details row
            Row(
              children: [
                _TripDetail(icon: Iconsax.calendar, label: DateFormat('MMM d').format(ride.departureTime)),
                const SizedBox(width: 8),
                _TripDetail(icon: Iconsax.clock, label: DateFormat('h:mm a').format(ride.departureTime)),
                const SizedBox(width: 8),
                _TripDetail(icon: Iconsax.people, label: '${ride.availableSeats} seats'),
                const SizedBox(width: 8),
                _TripDetail(icon: Iconsax.car, label: ride.driver?.carDetails?.model ?? 'Car'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Price and book button row
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price per seat',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${ride.pricePerSeat.toStringAsFixed(2)} BHD',
                      style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: ride.availableSeats > 0 ? onBook : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    child: Text(
                      ride.availableSeats > 0 ? 'Book Ride' : 'Fully Booked',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  const _RoutePoint({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
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
              Text(
                address,
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TripDetail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}