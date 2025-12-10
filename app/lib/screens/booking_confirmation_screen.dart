import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../models/ride.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/message_service.dart';
import '../widgets/widgets.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Ride ride;

  const BookingConfirmationScreen({
    super.key,
    required this.ride,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _bookingService = BookingService();
  final _messageService = MessageService();
  final _mapController = MapController();
  int _seatsToBook = 1;
  bool _isLoading = false;
  bool _isBooked = false;
  String? _bookingId;
  List<Booking> _rideBookings = [];
  bool _isLoadingBookings = false;

  @override
  void initState() {
    super.initState();
    _loadRideBookings();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRideBookings() async {
    setState(() => _isLoadingBookings = true);
    try {
      final bookings = await _bookingService.getRideBookings(widget.ride.id);
      if (mounted) {
        setState(() {
          _rideBookings = bookings;
          _isLoadingBookings = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
    }
  }

  void _fitMapBounds() {
    final points = <LatLng>[];
    
    // Add start location
    points.add(LatLng(
      widget.ride.startLocation.coordinates.lat,
      widget.ride.startLocation.coordinates.lng,
    ));
    
    // Add all pickup locations from bookings
    for (final booking in _rideBookings) {
      if (booking.pickupLocation != null) {
        points.add(LatLng(
          booking.pickupLocation!.coordinates.lat,
          booking.pickupLocation!.coordinates.lng,
        ));
      }
    }
    
    // Add destination
    points.add(LatLng(
      widget.ride.destination.coordinates.lat,
      widget.ride.destination.coordinates.lng,
    ));
    
    if (points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  Future<void> _handleBookSeat() async {
    setState(() => _isLoading = true);

    final result = await _bookingService.createBooking(
      rideId: widget.ride.id,
      seatsBooked: _seatsToBook,
    );

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      setState(() {
        _isBooked = true;
        _bookingId = result.id;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to book seat'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleCancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && _bookingId != null) {
      setState(() => _isLoading = true);

      final success = await _bookingService.cancelBooking(_bookingId!);

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel booking'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _textDriver() async {
    if (widget.ride.driver?.id == null) return;
    
    // Find existing conversation or create new one
    final conversations = await _messageService.getConversations();
    Conversation? existingConversation;
    
    for (var conv in conversations) {
      if (conv.participant?.oderId == widget.ride.driver!.id) {
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
        recipientId: widget.ride.driver!.id,
        content: 'Hi! I booked a seat on your ride.',
        rideId: widget.ride.id,
      );
      
      if (message != null && mounted) {
        // Reload conversations to get the new one
        final updatedConversations = await _messageService.getConversations();
        final newConversation = updatedConversations.firstWhere(
          (conv) => conv.participant?.oderId == widget.ride.driver?.id,
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

  Widget _buildRouteMap() {
    final startPoint = LatLng(
      widget.ride.startLocation.coordinates.lat,
      widget.ride.startLocation.coordinates.lng,
    );
    final endPoint = LatLng(
      widget.ride.destination.coordinates.lat,
      widget.ride.destination.coordinates.lng,
    );

    // Collect all waypoints: start + pickup locations + destination
    final waypoints = <LatLng>[startPoint];
    
    // Add pickup locations from bookings
    for (final booking in _rideBookings) {
      if (booking.pickupLocation != null) {
        waypoints.add(LatLng(
          booking.pickupLocation!.coordinates.lat,
          booking.pickupLocation!.coordinates.lng,
        ));
      }
    }
    
    // Add destination
    waypoints.add(endPoint);

    // Parse polyline if available
    List<LatLng>? routePoints;
    if (widget.ride.route?.polyline != null) {
      try {
        final polylineData = widget.ride.route!.polyline;
        if (polylineData != null && polylineData.isNotEmpty) {
          // Parse JSON array of coordinates [[lng, lat], ...]
          final coords = (polylineData is String 
              ? (polylineData.startsWith('[') 
                  ? jsonDecode(polylineData) 
                  : null)
              : polylineData) as List?;
          if (coords != null) {
            routePoints = coords.map((c) {
              if (c is List && c.length >= 2) {
                return LatLng(c[1].toDouble(), c[0].toDouble()); // GeoJSON is [lng, lat]
              }
              return null;
            }).whereType<LatLng>().toList();
          }
        }
      } catch (e) {
        // If parsing fails, use waypoints
        routePoints = null;
      }
    }

    // Use waypoints if no polyline
    if (routePoints == null || routePoints.isEmpty) {
      routePoints = waypoints;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: startPoint,
        initialZoom: 12.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.uniride',
        ),
        // Route polyline
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: AppColors.primary,
              ),
            ],
          ),
        // Markers
        MarkerLayer(
          markers: [
            // Start marker
            Marker(
              point: startPoint,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            // Pickup location markers
            ..._rideBookings.where((b) => b.pickupLocation != null).map((booking) {
              final point = LatLng(
                booking.pickupLocation!.coordinates.lat,
                booking.pickupLocation!.coordinates.lng,
              );
              return Marker(
                point: point,
                width: 35,
                height: 35,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.user,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              );
            }),
            // Destination marker
            Marker(
              point: endPoint,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.location_tick,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isBooked ? 'Ride Confirmed!' : 'Booking Confirmation',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isBooked) ...[
                // Success Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.tick_circle,
                        size: 48,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Booking Request Sent!',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Waiting for driver approval. You will be notified once confirmed.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                
                const SizedBox(height: 24),
              ] else ...[
                Text(
                  'Confirm Seat Booking!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate()
                  .fadeIn(duration: 300.ms),
                
                const SizedBox(height: 24),
              ],
              
              // Booking Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
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
                      _isBooked ? 'Booking Details:' : 'Trip Details:',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Driver Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: widget.ride.driver?.profilePicture != null
                              ? ClipOval(
                                  child: Image.network(
                                    widget.ride.driver!.profilePicture!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  widget.ride.driver?.initials ?? 'U',
                                  style: AppTextStyles.bodyLarge.copyWith(
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
                                widget.ride.driver?.name ?? 'Driver',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                widget.ride.driver?.phoneNumber ?? '',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.star1,
                                size: 14,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.ride.driver?.rating?.average.toStringAsFixed(1) ?? '0.0',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    // Route Info
                    _DetailRow(
                      icon: Iconsax.location,
                      iconColor: AppColors.primary,
                      label: 'Pickup Point',
                      value: widget.ride.startLocation.address,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _DetailRow(
                      icon: Iconsax.location_tick,
                      iconColor: AppColors.success,
                      label: 'Destination',
                      value: widget.ride.destination.address,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _DetailRow(
                      icon: Iconsax.clock,
                      iconColor: AppColors.secondary,
                      label: 'Departure Time',
                      value: DateFormat('h:mm a').format(widget.ride.departureTime),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _DetailRow(
                      icon: Iconsax.people,
                      iconColor: AppColors.secondary,
                      label: 'Number of Seats Occupied',
                      value: widget.ride.bookedSeats.toString(),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _DetailRow(
                      icon: Iconsax.people,
                      iconColor: AppColors.primary,
                      label: 'Number of Seats Left',
                      value: widget.ride.availableSeats.toString(),
                    ),
                    
                    const Divider(height: 32),
                    
                    // Route Map
                    Text(
                      'Route Map',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildRouteMap(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Divider(height: 32),
                    
                    // Car Details
                    _DetailRow(
                      icon: Iconsax.car,
                      iconColor: AppColors.secondary,
                      label: 'Car Model & Color',
                      value: widget.ride.driver?.carDetails != null
                          ? '${widget.ride.driver!.carDetails!.model} - ${widget.ride.driver!.carDetails!.color}'
                          : 'N/A',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _DetailRow(
                      icon: Iconsax.card,
                      iconColor: AppColors.secondary,
                      label: 'License Plate',
                      value: widget.ride.driver?.carDetails?.licensePlate ?? 'N/A',
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 24),
              
              if (_isBooked) ...[
                // Info message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.info_circle, color: AppColors.warning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your booking is pending driver approval. You can message the driver or cancel if needed.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 12),
                
                // Contact Button
                PrimaryButton(
                  text: 'Message Driver',
                  icon: Iconsax.message,
                  onPressed: _textDriver,
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 250.ms)
                  .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 12),
                
                // Cancel Booking Button
                DangerButton(
                  text: 'Cancel Booking',
                  icon: Iconsax.close_circle,
                  onPressed: _handleCancelBooking,
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 250.ms)
                  .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 16),
                
                // Back to Dashboard
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/dashboard',
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Back to Dashboard',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms),
              ] else ...[
                // Seats Selector
                if (widget.ride.availableSeats > 1) ...[
                  Text(
                    'Number of Seats',
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text('$_seatsToBook', style: AppTextStyles.bodyLarge),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Iconsax.minus_cirlce),
                          color: _seatsToBook > 1 ? AppColors.primary : AppColors.textSecondary,
                          onPressed: _seatsToBook > 1 
                              ? () => setState(() => _seatsToBook--) 
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.add_circle),
                          color: _seatsToBook < widget.ride.availableSeats && _seatsToBook < 4
                              ? AppColors.primary 
                              : AppColors.textSecondary,
                          onPressed: _seatsToBook < widget.ride.availableSeats && _seatsToBook < 4
                              ? () => setState(() => _seatsToBook++) 
                              : null,
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(duration: 400.ms, delay: 150.ms)
                    .slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 16),
                ],
                
                // Price Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.info_circle, color: AppColors.warning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Price will be calculated after the ride is completed based on duration.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 24),
                
                // Book Button
                PrimaryButton(
                  text: 'Book Seat',
                  onPressed: _handleBookSeat,
                  isLoading: _isLoading,
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 250.ms)
                  .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 16),
                
                // Back to Available Rides
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Back to Available Rides',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms),
              ],
              
              const SizedBox(height: 40),
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
        Icon(icon, size: 18, color: iconColor),
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