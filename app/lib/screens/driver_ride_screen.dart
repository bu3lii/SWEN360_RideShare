import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../services/ride_service.dart';
import '../services/booking_service.dart';
import '../services/location_service.dart';
import '../services/message_service.dart';
import '../widgets/widgets.dart';

class DriverRideScreen extends StatefulWidget {
  final Ride ride;

  const DriverRideScreen({super.key, required this.ride});

  @override
  State<DriverRideScreen> createState() => _DriverRideScreenState();
}

class _DriverRideScreenState extends State<DriverRideScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final RideService _rideService = RideService();
  final BookingService _bookingService = BookingService();
  final MessageService _messageService = MessageService();

  late Ride _ride;
  Position? _currentPosition;
  List<Booking> _bookings = [];
  bool _isLoading = true;
  bool _isTrackingLocation = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _refreshTimer;
  
  // Route data
  RouteResult? _routeInfo;
  Booking? _selectedBooking;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _initializeScreen();
    
    // Refresh bookings every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadBookings();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);

    try {
      // Refresh ride status to get latest state
      final updatedRide = await _rideService.getRide(_ride.id);
      if (updatedRide != null) {
        setState(() => _ride = updatedRide);
      }

      // Get current location
      final position = await _locationService.getCurrentLocation()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (position != null) {
        _currentPosition = position;
      }

      // Load bookings for this ride
      await _loadBookings();

      // Calculate route
      await _calculateRoute();
    } catch (e) {
      debugPrint('Error initializing: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _fitMapToRoute();
    }
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await _bookingService.getRideBookings(_ride.id);
      if (mounted) {
        setState(() {
          _bookings = bookings.where((b) => 
            b.status == 'pending' || b.status == 'confirmed' || b.status == 'picked_up'
          ).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    }
  }

  Future<void> _calculateRoute() async {
    final route = await _locationService.calculateRoute(
      _ride.startLocation.coordinates,
      _ride.destination.coordinates,
    );
    
    if (mounted && route != null) {
      setState(() => _routeInfo = route);
    }
  }

  void _fitMapToRoute() {
    // Calculate bounds to fit start, end, and current location
    final points = <LatLng>[
      LatLng(_ride.startLocation.coordinates.lat, _ride.startLocation.coordinates.lng),
      LatLng(_ride.destination.coordinates.lat, _ride.destination.coordinates.lng),
    ];
    
    if (_currentPosition != null) {
      points.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    }
    
    // Add passenger pickup locations
    for (final booking in _bookings) {
      if (booking.pickupLocation != null) {
        points.add(LatLng(
          booking.pickupLocation!.coordinates.lat,
          booking.pickupLocation!.coordinates.lng,
        ));
      }
    }

    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
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
          }
        },
      );
      setState(() => _isTrackingLocation = true);
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15,
      );
    }
  }

  // Navigate to location on onboard map
  Future<void> _openNavigation(double lat, double lng, String label) async {
    // Center map on destination and zoom in
    _mapController.move(
      LatLng(lat, lng),
      16,
    );
    
    // Calculate route from current position to destination if available
    if (_currentPosition != null) {
      try {
        final route = await _locationService.calculateRoute(
          Coordinates(
            lat: _currentPosition!.latitude,
            lng: _currentPosition!.longitude,
          ),
          Coordinates(lat: lat, lng: lng),
        );
        
        if (mounted && route != null) {
          setState(() {
            _routeInfo = route;
          });
        }
      } catch (e) {
        debugPrint('Error calculating route: $e');
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigating to $label'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _startRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Ride'),
        content: const Text('Are you ready to start this ride? All passengers will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _rideService.startRide(_ride.id);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride started! Navigate to pickup points.'),
              backgroundColor: AppColors.success,
            ),
          );
          // Refresh ride status
          final updatedRide = await _rideService.getRide(_ride.id);
          if (updatedRide != null) {
            setState(() => _ride = updatedRide);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start ride'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Ride'),
        content: const Text('Have all passengers been dropped off at the destination?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _rideService.completeRide(_ride.id);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (result != null) {
          // Navigate to completion summary screen
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

  Future<void> _markPassengerPaid(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text(
          'Confirm that ${booking.passenger?.name ?? 'the passenger'} has paid ${booking.totalAmount.toStringAsFixed(2)} BHD in person?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _bookingService.markPaid(booking.id);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          // Refresh bookings
          await _loadBookings();
          
          // Navigate driver to review screen
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
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment marked as received. Please leave a review.'),
              backgroundColor: AppColors.success,
            ),
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
    }
  }

  Future<void> _markPassengerPickedUp(Booking booking) async {
    debugPrint('_markPassengerPickedUp called for booking: ${booking.id}');
    try {
      // Ensure we have the latest booking data with safe codes
      debugPrint('Fetching updated booking data...');
      final updatedBooking = await _bookingService.getBooking(booking.id);
      if (updatedBooking == null) {
        debugPrint('Failed to fetch updated booking');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load booking details'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      debugPrint('Booking fetched. Driver code: ${updatedBooking.driverSafeCode}, Rider code: ${updatedBooking.riderSafeCode}');

      // Navigate to pickup confirmation screen
      debugPrint('Pushing pickup confirmation screen...');
      final result = await Navigator.pushNamed<bool>(
        context,
        '/pickup-confirmation',
        arguments: updatedBooking,
      );

      debugPrint('Pickup confirmation result: $result');

      if (result == true && mounted) {
        debugPrint('Pickup confirmed, refreshing bookings...');
        // Refresh bookings after successful pickup
        await _loadBookings();
        setState(() => _selectedBooking = null);
      }
    } catch (e, stackTrace) {
      debugPrint('Error navigating to pickup confirmation: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markNoShow(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark No-Show'),
        content: Text('Mark ${booking.passenger?.name ?? 'passenger'} as no-show? They will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('No-Show'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _bookingService.markNoShow(booking.id);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          await _loadBookings();
        }
      }
    }
  }

  Future<void> _acceptBooking(Booking booking) async {
    final success = await _bookingService.acceptBooking(booking.id);
    if (success && mounted) {
      await _loadBookings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking accepted'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept booking'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking?'),
        content: const Text('Are you sure you want to reject this booking request?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _bookingService.rejectBooking(booking.id);
      if (success && mounted) {
        await _loadBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject booking'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPassengerDetails(Booking booking) {
    setState(() => _selectedBooking = booking);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PassengerDetailsSheet(
        booking: booking,
        rideStatus: _ride.status,
        onNavigate: () {
          Navigator.pop(context);
          if (booking.pickupLocation != null) {
            // Navigate to pickup point and center map
            _openNavigation(
              booking.pickupLocation!.coordinates.lat,
              booking.pickupLocation!.coordinates.lng,
              booking.passenger?.name ?? 'Pickup',
            );
            // Also select the booking to highlight it on the map
            setState(() => _selectedBooking = booking);
          }
        },
        onPickedUp: () async {
          debugPrint('Picked Up button clicked for booking: ${booking.id}');
          Navigator.pop(context);
          // Small delay to ensure bottom sheet is fully closed
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            debugPrint('Navigating to pickup confirmation screen');
            _markPassengerPickedUp(booking);
          } else {
            debugPrint('Widget not mounted, cannot navigate');
          }
        },
        onNoShow: () {
          Navigator.pop(context);
          _markNoShow(booking);
        },
        onAccept: () {
          Navigator.pop(context);
          _acceptBooking(booking);
        },
        onReject: () {
          Navigator.pop(context);
          _rejectBooking(booking);
        },
        onMarkPaid: () {
          Navigator.pop(context);
          _markPassengerPaid(booking);
        },
        onMessage: () async {
          Navigator.pop(context);
          if (booking.passenger?.id == null) return;
          
          // Find existing conversation or create new one
          final conversations = await _messageService.getConversations();
          Conversation? existingConversation;
          
          for (var conv in conversations) {
            if (conv.participant?.oderId == booking.passenger?.id) {
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
              recipientId: booking.passenger!.id,
              content: 'Hi!',
              rideId: _ride.id,
            );
            
            if (message != null && mounted) {
              // Reload conversations to get the new one
              final updatedConversations = await _messageService.getConversations();
              final newConversation = updatedConversations.firstWhere(
                (conv) => conv.participant?.oderId == booking.passenger?.id,
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
              initialCenter: LatLng(
                _ride.startLocation.coordinates.lat,
                _ride.startLocation.coordinates.lng,
              ),
              initialZoom: 13,
              minZoom: 10,
              maxZoom: 18,
              onTap: (_, __) => setState(() => _selectedBooking = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.uniride',
              ),
              
              // Route polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routeInfo?.routePoints.map((c) => 
                      LatLng(c.lat, c.lng)
                    ).toList() ?? [
                      LatLng(_ride.startLocation.coordinates.lat, 
                             _ride.startLocation.coordinates.lng),
                      LatLng(_ride.destination.coordinates.lat, 
                             _ride.destination.coordinates.lng),
                    ],
                    strokeWidth: 5,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ],
              ),
              
              // Markers
              MarkerLayer(
                markers: [
                  // Current location
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 50,
                      height: 50,
                      child: _DriverMarker(isTracking: _isTrackingLocation),
                    ),
                  
                  // Start location
                  Marker(
                    point: LatLng(_ride.startLocation.coordinates.lat, 
                                  _ride.startLocation.coordinates.lng),
                    width: 44,
                    height: 50,
                    child: _StartMarker(),
                  ),
                  
                  // Destination
                  Marker(
                    point: LatLng(_ride.destination.coordinates.lat, 
                                  _ride.destination.coordinates.lng),
                    width: 44,
                    height: 50,
                    child: _DestinationMarker(),
                  ),
                  
                  // Passenger pickup locations
                  ..._bookings.map((booking) {
                    if (booking.pickupLocation == null) return null;
                    return Marker(
                      point: LatLng(
                        booking.pickupLocation!.coordinates.lat,
                        booking.pickupLocation!.coordinates.lng,
                      ),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showPassengerDetails(booking),
                        child: _PassengerMarker(
                          booking: booking,
                          isSelected: _selectedBooking?.id == booking.id,
                        ),
                      ),
                    );
                  }).whereType<Marker>(),
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

          // Top bar
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
                  colors: [Colors.white, Colors.white.withOpacity(0)],
                ),
              ),
              child: Row(
                children: [
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
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          _StatusBadge(status: _ride.status),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your Ride • ${_bookings.length} passengers',
                              style: AppTextStyles.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FABs
          Positioned(
            right: 16,
            bottom: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'fit',
                  backgroundColor: Colors.white,
                  onPressed: _fitMapToRoute,
                  child: const Icon(Iconsax.maximize_4, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'tracking',
                  backgroundColor: _isTrackingLocation ? AppColors.primary : Colors.white,
                  onPressed: _toggleLocationTracking,
                  child: Icon(
                    _isTrackingLocation ? Iconsax.gps5 : Iconsax.gps,
                    color: _isTrackingLocation ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'center',
                  backgroundColor: Colors.white,
                  onPressed: _centerOnCurrentLocation,
                  child: const Icon(Iconsax.location, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _DriverBottomPanel(
              ride: _ride,
              routeInfo: _routeInfo,
              bookings: _bookings,
              onStartRide: _ride.status == 'scheduled' ? _startRide : null,
              onCompleteRide: _ride.status == 'in_progress' ? _completeRide : null,
              onNavigateToStart: () => _openNavigation(
                _ride.startLocation.coordinates.lat,
                _ride.startLocation.coordinates.lng,
                'Start',
              ),
              onNavigateToDestination: () => _openNavigation(
                _ride.destination.coordinates.lat,
                _ride.destination.coordinates.lng,
                'Destination',
              ),
              onPassengerTap: _showPassengerDetails,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MARKERS
// ============================================================================

class _DriverMarker extends StatelessWidget {
  final bool isTracking;

  const _DriverMarker({required this.isTracking});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isTracking)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.2),
            ),
          ).animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1000.ms)
            .fadeOut(duration: 1000.ms),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Iconsax.car, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

class _StartMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Iconsax.location, color: Colors.white, size: 18),
        ),
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _DestinationMarker extends StatelessWidget {
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

class _PassengerMarker extends StatelessWidget {
  final Booking booking;
  final bool isSelected;

  const _PassengerMarker({required this.booking, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isPickedUp = booking.status == 'picked_up';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSelected ? 10 : 8),
            decoration: BoxDecoration(
              color: isPickedUp ? AppColors.success : AppColors.warning,
              borderRadius: BorderRadius.circular(isSelected ? 14 : 10),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: (isPickedUp ? AppColors.success : AppColors.warning).withOpacity(0.3),
                  blurRadius: isSelected ? 15 : 8,
                ),
              ],
            ),
            child: Icon(
              isPickedUp ? Iconsax.tick_circle : Iconsax.user,
              color: Colors.white,
              size: isSelected ? 22 : 18,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                booking.passenger?.name?.split(' ').first ?? 'Passenger',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATUS BADGE
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    
    switch (status) {
      case 'scheduled':
        color = AppColors.warning;
        text = 'Scheduled';
        break;
      case 'in_progress':
        color = AppColors.primary;
        text = 'In Progress';
        break;
      case 'completed':
        color = AppColors.success;
        text = 'Completed';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'Cancelled';
        break;
      default:
        color = AppColors.textSecondary;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM PANEL
// ============================================================================

class _DriverBottomPanel extends StatelessWidget {
  final Ride ride;
  final RouteResult? routeInfo;
  final List<Booking> bookings;
  final VoidCallback? onStartRide;
  final VoidCallback? onCompleteRide;
  final VoidCallback onNavigateToStart;
  final VoidCallback onNavigateToDestination;
  final Function(Booking) onPassengerTap;

  const _DriverBottomPanel({
    required this.ride,
    this.routeInfo,
    required this.bookings,
    this.onStartRide,
    this.onCompleteRide,
    required this.onNavigateToStart,
    required this.onNavigateToDestination,
    required this.onPassengerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route info
                  Row(
                    children: [
                      Expanded(
                        child: _RouteInfoCard(
                          icon: Iconsax.location,
                          iconColor: AppColors.primary,
                          label: 'From',
                          address: ride.startLocation.address,
                          onNavigate: onNavigateToStart,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Iconsax.arrow_right_3, color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: _RouteInfoCard(
                          icon: Iconsax.flag,
                          iconColor: AppColors.success,
                          label: 'To',
                          address: ride.destination.address,
                          onNavigate: onNavigateToDestination,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Trip stats
                  Row(
                    children: [
                      _TripStat(
                        icon: Iconsax.clock,
                        label: DateFormat('h:mm a').format(ride.departureTime),
                      ),
                      _TripStat(
                        icon: Iconsax.routing,
                        label: routeInfo?.distanceText ?? '--',
                      ),
                      _TripStat(
                        icon: Iconsax.timer_1,
                        label: routeInfo?.durationText ?? '--',
                      ),
                      _TripStat(
                        icon: Iconsax.people,
                        label: '${bookings.length} passengers',
                      ),
                    ],
                  ),
                  
                  // Passengers list
                  if (bookings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Passengers',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return _PassengerChip(
                            booking: booking,
                            onTap: () => onPassengerTap(booking),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  if (onStartRide != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onStartRide,
                        icon: const Icon(Iconsax.play),
                        label: const Text('Start Ride'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  
                  if (onCompleteRide != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onCompleteRide,
                        icon: const Icon(Iconsax.tick_circle),
                        label: const Text('Complete Ride'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;
  final VoidCallback onNavigate;

  const _RouteInfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNavigate,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 4),
                Text(label, style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                )),
                const Spacer(),
                Icon(Iconsax.export_3, size: 14, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              address,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TripStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PassengerChip extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _PassengerChip({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPickedUp = booking.status == 'picked_up';
    final isPending = booking.status == 'pending';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPickedUp 
              ? AppColors.success.withOpacity(0.1) 
              : isPending
                  ? AppColors.warning.withOpacity(0.1)
                  : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPickedUp 
                ? AppColors.success 
                : isPending
                    ? AppColors.warning
                    : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isPickedUp 
                  ? AppColors.success 
                  : AppColors.primary.withOpacity(0.1),
              child: isPickedUp
                  ? const Icon(Iconsax.tick_circle, color: Colors.white, size: 16)
                  : Text(
                      booking.passenger?.initials ?? '?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.passenger?.name?.split(' ').first ?? 'Passenger',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PASSENGER DETAILS SHEET
// ============================================================================

class _PassengerDetailsSheet extends StatelessWidget {
  final Booking booking;
  final String rideStatus;
  final VoidCallback onNavigate;
  final VoidCallback onPickedUp;
  final VoidCallback onNoShow;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback onMessage;
  final VoidCallback? onMarkPaid;

  const _PassengerDetailsSheet({
    required this.booking,
    required this.rideStatus,
    required this.onNavigate,
    required this.onPickedUp,
    required this.onNoShow,
    this.onAccept,
    this.onReject,
    required this.onMessage,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final isPickedUp = booking.pickedUpAt != null;
    final isPending = booking.status == 'pending';
    final isInProgress = rideStatus == 'in_progress';
    final isCompleted = booking.status == 'completed';
    final isPaid = booking.paymentStatus == 'paid';
    
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Passenger info
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    booking.passenger?.initials ?? '?',
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
                            booking.passenger?.name ?? 'Passenger',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isPending) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Pending',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ] else if (isPickedUp) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Picked Up',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${booking.seatsBooked} seat${booking.seatsBooked > 1 ? 's' : ''} booked',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (booking.pickupLocation != null && !isPickedUp) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.location, size: 20, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup Location',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            booking.pickupLocation!.address,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Action buttons
            if (isPending && onAccept != null && onReject != null) ...[
              // Accept/Reject buttons for pending bookings
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Iconsax.close_circle),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Iconsax.tick_circle),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Iconsax.message),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Normal buttons for confirmed bookings
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMessage,
                      icon: const Icon(Iconsax.message),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onNavigate,
                      icon: const Icon(Iconsax.routing_2),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (isInProgress && !isPickedUp) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNoShow,
                        icon: const Icon(Iconsax.close_circle),
                        label: const Text('No-Show'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          debugPrint('Picked Up button onPressed triggered');
                          onPickedUp();
                        },
                        icon: const Icon(Iconsax.tick_circle),
                        label: const Text('Picked Up'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Mark as Paid button (when ride is completed and not yet paid)
              if (isCompleted && !isPaid && onMarkPaid != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onMarkPaid,
                    icon: const Icon(Iconsax.wallet_money),
                    label: const Text('Mark as Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
              
              // Payment status indicator
              if (isPaid) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.tick_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Payment received',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}