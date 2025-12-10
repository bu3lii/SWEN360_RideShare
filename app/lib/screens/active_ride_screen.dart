import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/booking_service.dart';
import '../services/location_service.dart';
import '../services/message_service.dart';
import '../widgets/widgets.dart';

class ActiveRideScreen extends StatefulWidget {
  final Booking booking;

  const ActiveRideScreen({super.key, required this.booking});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final BookingService _bookingService = BookingService();
  final MessageService _messageService = MessageService();

  Booking? _booking;
  bool _isLoading = true;
  Position? _currentPosition;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _initializeScreen();
    
    // Refresh booking status every 5 seconds to check for pickup
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshBookingStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _refreshBookingStatus() async {
    if (_booking == null) return;
    
    try {
      final updatedBooking = await _bookingService.getBooking(_booking!.id);
      if (updatedBooking != null && mounted) {
        final wasPickedUp = _booking?.pickedUpAt != null;
        final isNowPickedUp = updatedBooking.pickedUpAt != null;
        final wasCompleted = _booking?.status == 'completed';
        final isNowCompleted = updatedBooking.status == 'completed';
        
        setState(() {
          _booking = updatedBooking;
        });
        
        // If just picked up, show verification dialog
        if (!wasPickedUp && isNowPickedUp) {
          _showDriverCodeVerification();
        }
        
        // If just completed, navigate to payment screen
        if (!wasCompleted && isNowCompleted) {
          Navigator.pushReplacementNamed(
            context,
            '/payment',
            arguments: {
              'booking': updatedBooking,
              'isDriver': false,
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error refreshing booking status: $e');
    }
  }

  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);

    try {
      // Refresh booking to get latest status
      final updatedBooking = await _bookingService.getBooking(_booking!.id);
      if (updatedBooking != null) {
        setState(() => _booking = updatedBooking);
      }

      // Get current location
      final position = await _locationService.getCurrentLocation()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (position != null) {
        setState(() => _currentPosition = position);
      }

      // Fit map to show route
      _fitMapToRoute();
    } catch (e) {
      debugPrint('Error initializing: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _fitMapToRoute() {
    final ride = _booking?.ride;
    if (ride == null) return;

    final points = <LatLng>[
      LatLng(ride.startLocation.coordinates.lat, ride.startLocation.coordinates.lng),
      LatLng(ride.destination.coordinates.lat, ride.destination.coordinates.lng),
    ];

    if (_currentPosition != null) {
      points.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
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

  Future<void> _showDriverCodeVerification() async {
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

  Future<void> _messageDriver() async {
    if (_booking?.ride?.driver?.id == null) return;

    final conversations = await _messageService.getConversations();
    Conversation? existingConversation;

    for (var conv in conversations) {
      if (conv.participant?.oderId == _booking!.ride!.driver!.id) {
        existingConversation = conv;
        break;
      }
    }

    if (existingConversation != null) {
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: existingConversation,
        );
      }
    } else {
      final message = await _messageService.sendMessage(
        recipientId: _booking!.ride!.driver!.id,
        content: 'Hi!',
        rideId: _booking!.ride!.id,
      );

      if (message != null && mounted) {
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = _booking?.ride;
    if (ride == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Ride')),
        body: const Center(child: Text('Ride not found')),
      );
    }

    // Check if picked up by looking at pickedUpAt timestamp (status remains 'confirmed')
    final isPickedUp = _booking?.pickedUpAt != null;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                ride.startLocation.coordinates.lat,
                ride.startLocation.coordinates.lng,
              ),
              initialZoom: 13,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.uniride',
              ),
              MarkerLayer(
                markers: [
                  // Start location
                  Marker(
                    point: LatLng(ride.startLocation.coordinates.lat,
                        ride.startLocation.coordinates.lng),
                    width: 44,
                    height: 50,
                    child: _StartMarker(),
                  ),
                  // Destination
                  Marker(
                    point: LatLng(ride.destination.coordinates.lat,
                        ride.destination.coordinates.lng),
                    width: 44,
                    height: 50,
                    child: _DestinationMarker(),
                  ),
                  // Current location
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Iconsax.location, color: Colors.white, size: 20),
                      ),
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
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/safety-center'),
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
                      child: const Icon(Iconsax.shield_tick, color: AppColors.textPrimary),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your Ride',
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

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isPickedUp
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPickedUp ? Iconsax.tick_circle : Iconsax.clock,
                              color: isPickedUp ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isPickedUp
                                    ? 'You have been picked up!'
                                    : 'Waiting for driver to pick you up...',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Route info
                      _DetailRow(
                        icon: Iconsax.location,
                        iconColor: AppColors.primary,
                        label: 'From',
                        value: ride.startLocation.address,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Iconsax.location_tick,
                        iconColor: AppColors.success,
                        label: 'To',
                        value: ride.destination.address,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Iconsax.calendar,
                        iconColor: AppColors.secondary,
                        label: 'Departure',
                        value: DateFormat('MMM dd, yyyy • h:mm a').format(ride.departureTime),
                      ),

                      const SizedBox(height: 20),

                      // Driver info
                      if (ride.driver != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: ride.driver!.profilePicture != null
                                    ? ClipOval(
                                        child: Image.network(
                                          ride.driver!.profilePicture!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Text(
                                        ride.driver!.initials,
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
                                      ride.driver!.name,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Driver',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Driver Code Verification (if not picked up yet)
                      if (!isPickedUp) ...[
                        OutlinedButton.icon(
                          onPressed: _showDriverCodeVerification,
                          icon: const Icon(Iconsax.shield_tick),
                          label: const Text('Verify Driver Code'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Action button
                      PrimaryButton(
                        text: 'Message Driver',
                        icon: Iconsax.message,
                        onPressed: _messageDriver,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

