import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../config/theme.dart';
import '../models/models.dart';
import '../services/ride_service.dart';
import '../services/location_service.dart';
import '../widgets/widgets.dart';

class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({super.key});

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  final _rideService = RideService();
  final _locationService = LocationService();
  final _searchController = TextEditingController();
  
  static const double _maxDestinationKm = 10.0; // discard rides if destination is too far

  List<Ride> _rides = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state
  Location? _pickupLocation; // REQUIRED
  Location? _destinationLocation;
  double _radiusKm = 5.0; // Default 5km
  DateTime? _selectedDate;
  int? _minSeats;
  String? _genderPreference;

  int get _activeFilterCount {
    int count = 0;
    if (_destinationLocation != null) count++;
    if (_radiusKm != 5.0) count++;
    if (_selectedDate != null) count++;
    if (_minSeats != null) count++;
    if (_genderPreference != null && _genderPreference != 'any') count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _initializeWithCurrentLocation();
  }

  Future<void> _initializeWithCurrentLocation() async {
    try {
      // Try to get current location
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        // Reverse geocode to get address
        final address = await _locationService.reverseGeocode(
          position.latitude,
          position.longitude,
        );
        
        // Use reverse geocoded address or fallback to coordinates
        final locationAddress = address ?? 
            'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        
        setState(() {
          _pickupLocation = Location(
            address: locationAddress,
            coordinates: Coordinates(
              lat: position.latitude,
              lng: position.longitude,
            ),
          );
        });
        // Load rides with current location
        _loadRides();
      } else {
        // No location available, set loading to false
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // If location fails, just set loading to false
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    // Pickup location is required
    if (_pickupLocation == null) {
      setState(() {
        _rides = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rides = await _rideService.getAvailableRides(
        startLat: _pickupLocation!.coordinates.lat,
        startLng: _pickupLocation!.coordinates.lng,
        destLat: _destinationLocation?.coordinates.lat,
        destLng: _destinationLocation?.coordinates.lng,
        date: _selectedDate != null 
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        minSeats: _minSeats,
        genderPreference: _genderPreference,
        radius: (_radiusKm * 1000).round(), // Convert km to meters
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _rides = rides;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  List<Ride> get _filteredRides {
    if (_searchController.text.isEmpty) return _rides;
    
    final query = _searchController.text.toLowerCase();
    return _rides.where((ride) {
      return ride.startLocation.address.toLowerCase().contains(query) ||
             ride.destination.address.toLowerCase().contains(query) ||
             (ride.driver?.name.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  bool get _hasDestination => _destinationLocation != null;

  List<Ride> get _matchedRides {
    if (!_hasDestination) return _filteredRides;

    final distanceCalc = const Distance();
    final userDest = LatLng(_destinationLocation!.coordinates.lat, _destinationLocation!.coordinates.lng);

    return _filteredRides.where((ride) {
      final rideEnd = LatLng(ride.destination.coordinates.lat, ride.destination.coordinates.lng);
      final destinationDistanceKm =
          (ride.distanceToDestination ?? distanceCalc(rideEnd, userDest)) / 1000;
      return destinationDistanceKm <= _maxDestinationKm;
    }).toList();
  }

  Ride? get _bestMatch {
    if (!_hasDestination) return null; // Require destination to rank best match
    final rides = _matchedRides;
    if (rides.isEmpty || _pickupLocation == null) return null;
    final sorted = List<Ride>.from(rides)
      ..sort((a, b) => _rideScore(a).compareTo(_rideScore(b)));
    return sorted.first;
  }

  List<Ride> get _otherRides {
    if (!_hasDestination) return _matchedRides; // fallback: show all if no destination
    final rides = _matchedRides;
    if (rides.length <= 1 || _pickupLocation == null) return [];
    final sorted = List<Ride>.from(rides)
      ..sort((a, b) => _rideScore(a).compareTo(_rideScore(b)));
    return sorted.sublist(1);
  }

  double _rideScore(Ride ride) {
    final distanceCalc = const Distance();

    final userPickup = LatLng(_pickupLocation!.coordinates.lat, _pickupLocation!.coordinates.lng);
    final rideStart = LatLng(ride.startLocation.coordinates.lat, ride.startLocation.coordinates.lng);
    final rideEnd = LatLng(ride.destination.coordinates.lat, ride.destination.coordinates.lng);

    // Prefer server-provided distances if available, else compute
    final pickupDistanceKm = (ride.distanceFromStart ?? distanceCalc(rideStart, userPickup)) / 1000;
    double destinationDistanceKm = 0;
    if (_destinationLocation != null) {
      final userDest = LatLng(_destinationLocation!.coordinates.lat, _destinationLocation!.coordinates.lng);
      destinationDistanceKm = (ride.distanceToDestination ?? distanceCalc(rideEnd, userDest)) / 1000;
    }

    // Prefer departures closer to now (future only). Past departures penalized heavily.
    final now = DateTime.now();
    final minutesDiff = math.max(0, ride.departureTime.difference(now).inMinutes);

    // Weighted score: lower is better
    // When destination is set, prioritize destination matching (3x more important than pickup)
    // This ensures rides going to the user's destination are preferred even if pickup is slightly further
    if (_destinationLocation != null) {
      // Destination is most important (weight: 3.0), then pickup (weight: 1.0), then time (weight: 0.1)
      return (destinationDistanceKm * 3.0) + 
             (pickupDistanceKm * 1.0) + 
             (minutesDiff * 0.1);
    } else {
      // No destination: just use pickup distance and time
      return (pickupDistanceKm * 1.0) + (minutesDiff * 0.1);
    }
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        pickupLocation: _pickupLocation,
        destinationLocation: _destinationLocation,
        radiusKm: _radiusKm,
        selectedDate: _selectedDate,
        minSeats: _minSeats,
        genderPreference: _genderPreference ?? 'any',
      ),
    );

    if (result != null) {
      setState(() {
        _pickupLocation = result['pickupLocation'] as Location?;
        _destinationLocation = result['destinationLocation'] as Location?;
        _radiusKm = result['radiusKm'] as double;
        _selectedDate = result['selectedDate'] as DateTime?;
        _minSeats = result['minSeats'] as int?;
        _genderPreference = result['genderPreference'] as String?;
      });
      _loadRides();
    }
  }

  void _clearFilters() {
    setState(() {
      _pickupLocation = null;
      _destinationLocation = null;
      _radiusKm = 5.0;
      _selectedDate = null;
      _minSeats = null;
      _genderPreference = null;
    });
    _loadRides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Available Rides',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Iconsax.filter, color: AppColors.textPrimary),
                onPressed: _showFilterSheet,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_destinationLocation == null)
            Container(
              width: double.infinity,
              color: AppColors.warning.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Iconsax.route_square, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add your destination to get the best match',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _showFilterSheet,
                    child: Text(
                      'Add destination',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),

          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by location or driver name...',
                prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ).animate()
            .fadeIn(duration: 300.ms),
          
          // Active Filters Bar
          if (_activeFilterCount > 0)
            Container(
              color: AppColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Iconsax.filter, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '$_activeFilterCount filter${_activeFilterCount > 1 ? 's' : ''} active',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Clear All',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          
          // Rides List
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _matchedRides.isEmpty
                        ? _buildEmptyView()
                        : RefreshIndicator(
                            onRefresh: _loadRides,
                            color: AppColors.primary,
                            child: _hasDestination
                                ? ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: [
                                      if (_bestMatch != null) ...[
                                        Text(
                                          'Best Match',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _RideCard(
                                          ride: _bestMatch!,
                                          onTap: () => _showRideDetails(_bestMatch!),
                                        ).animate()
                                          .fadeIn(duration: 300.ms)
                                          .slideY(begin: 0.05, end: 0),
                                        const SizedBox(height: 16),
                                      ],
                                      if (_otherRides.isNotEmpty) ...[
                                        Text(
                                          'Other options',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ..._otherRides.asMap().entries.map((entry) {
                                          final idx = entry.key;
                                          final ride = entry.value;
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: _RideCard(
                                              ride: ride,
                                              onTap: () => _showRideDetails(ride),
                                            ).animate()
                                              .fadeIn(
                                                duration: 250.ms,
                                                delay: Duration(milliseconds: 40 * idx),
                                              )
                                              .slideY(begin: 0.08, end: 0),
                                          );
                                        }),
                                      ],
                                    ],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _matchedRides.length,
                                    itemBuilder: (context, index) {
                                      final ride = _matchedRides[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _RideCard(
                                          ride: ride,
                                          onTap: () => _showRideDetails(ride),
                                        ).animate()
                                          .fadeIn(
                                            duration: 250.ms,
                                            delay: Duration(milliseconds: 40 * index),
                                          )
                                          .slideY(begin: 0.08, end: 0),
                                      );
                                    },
                                  ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 64,
              color: AppColors.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Try Again',
              onPressed: _loadRides,
              width: 150,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'No Rides Available',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 8),
            Text(
              _pickupLocation == null
                  ? 'Please select a pickup location to search for rides'
                  : _activeFilterCount > 0
                      ? 'No rides found matching your filters. Try adjusting your search criteria.'
                      : _searchController.text.isNotEmpty
                          ? 'No rides found matching your search'
                          : 'No rides found in this area. Try adjusting the search radius.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_pickupLocation == null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Select Pickup Location',
                onPressed: _showFilterSheet,
                width: 200,
              ),
            ] else if (_activeFilterCount > 0) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _clearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                ),
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRideDetails(Ride ride) {
    Navigator.pushNamed(
      context,
      '/booking-confirmation',
      arguments: ride,
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final Location? pickupLocation;
  final Location? destinationLocation;
  final double radiusKm;
  final DateTime? selectedDate;
  final int? minSeats;
  final String genderPreference;

  const _FilterBottomSheet({
    this.pickupLocation,
    this.destinationLocation,
    this.radiusKm = 5.0,
    this.selectedDate,
    this.minSeats,
    this.genderPreference = 'any',
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Location? _pickupLocation;
  late Location? _destinationLocation;
  late double _radiusKm;
  late DateTime? _selectedDate;
  late int? _minSeats;
  late String _genderPreference;
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _pickupLocation = widget.pickupLocation;
    _destinationLocation = widget.destinationLocation;
    _radiusKm = widget.radiusKm;
    _selectedDate = widget.selectedDate;
    _minSeats = widget.minSeats;
    _genderPreference = widget.genderPreference;
  }

  Future<void> _selectPickupLocation() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: 'Select Pickup Location',
          initialLocation: _pickupLocation != null
              ? LatLng(
                  _pickupLocation!.coordinates.lat,
                  _pickupLocation!.coordinates.lng,
                )
              : null,
          initialAddress: _pickupLocation?.address,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _pickupLocation = result.location;
      });
    }
  }

  Future<void> _selectDestinationLocation() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: 'Select Destination',
          initialLocation: _destinationLocation != null
              ? LatLng(
                  _destinationLocation!.coordinates.lat,
                  _destinationLocation!.coordinates.lng,
                )
              : null,
          initialAddress: _destinationLocation?.address,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _destinationLocation = result.location;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Rides',
                          style: AppTextStyles.h2,
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.close_circle),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Pickup Location (REQUIRED)
                    _FilterSection(
                      title: 'Pickup Location *',
                      child: InkWell(
                        onTap: _selectPickupLocation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _pickupLocation != null
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.location,
                                color: _pickupLocation != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _pickupLocation?.address ?? 'Select pickup location',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: _pickupLocation != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (_pickupLocation != null)
                                IconButton(
                                  icon: const Icon(Iconsax.close_circle, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _pickupLocation = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Radius (only shown if pickup is selected)
                    if (_pickupLocation != null) ...[
                      _FilterSection(
                        title: 'Search Radius: ${_radiusKm.toStringAsFixed(1)} km',
                        child: Column(
                          children: [
                            Slider(
                              value: _radiusKm,
                              min: 1.0,
                              max: 50.0,
                              divisions: 49,
                              label: '${_radiusKm.toStringAsFixed(1)} km',
                              onChanged: (value) {
                                setState(() {
                                  _radiusKm = value;
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '1 km',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '50 km',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Destination (Optional)
                    _FilterSection(
                      title: 'Destination (Optional)',
                      child: InkWell(
                        onTap: _selectDestinationLocation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _destinationLocation != null
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.location_tick,
                                color: _destinationLocation != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _destinationLocation?.address ?? 'Select destination (optional)',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: _destinationLocation != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (_destinationLocation != null)
                                IconButton(
                                  icon: const Icon(Iconsax.close_circle, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _destinationLocation = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date
                    _FilterSection(
                      title: 'Date',
                      child: InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedDate != null
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.calendar,
                                color: _selectedDate != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate != null
                                      ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)
                                      : 'Select date (optional)',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: _selectedDate != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (_selectedDate != null)
                                IconButton(
                                  icon: const Icon(Iconsax.close_circle, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Min Seats
                    _FilterSection(
                      title: 'Minimum Seats',
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Any',
                                filled: true,
                                fillColor: AppColors.inputBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              controller: TextEditingController(
                                text: _minSeats?.toString() ?? '',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _minSeats = value.isEmpty ? null : int.tryParse(value);
                                });
                              },
                            ),
                          ),
                          if (_minSeats != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Iconsax.close_circle, size: 20),
                              onPressed: () {
                                setState(() {
                                  _minSeats = null;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gender Preference
                    _FilterSection(
                      title: 'Gender Preference',
                      child: Wrap(
                        spacing: 12,
                        children: [
                          _GenderChip(
                            label: 'Any',
                            isSelected: _genderPreference == 'any',
                            onTap: () => setState(() => _genderPreference = 'any'),
                          ),
                          _GenderChip(
                            label: 'Male Only',
                            isSelected: _genderPreference == 'male',
                            onTap: () => setState(() => _genderPreference = 'male'),
                          ),
                          _GenderChip(
                            label: 'Female Only',
                            isSelected: _genderPreference == 'female',
                            onTap: () => setState(() => _genderPreference = 'female'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              // Apply Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: PrimaryButton(
                    text: 'Apply Filters',
                    onPressed: _pickupLocation == null
                        ? null
                        : () {
                            Navigator.pop(context, {
                        'pickupLocation': _pickupLocation,
                        'destinationLocation': _destinationLocation,
                        'radiusKm': _radiusKm,
                        'selectedDate': _selectedDate,
                        'minSeats': _minSeats,
                        'genderPreference': _genderPreference == 'any' ? null : _genderPreference,
                      });
                          },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onTap;

  const _RideCard({
    required this.ride,
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
            // Driver Info Row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: ride.driver?.profilePicture != null
                      ? ClipOval(
                          child: Image.network(
                            ride.driver!.profilePicture!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          ride.driver?.initials ?? 'U',
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
                        ride.driver?.name ?? 'Driver',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (ride.driver?.phoneNumber != null)
                        Text(
                          ride.driver!.phoneNumber,
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
                        ride.driver?.rating?.average.toStringAsFixed(1) ?? '0.0',
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
            
            const Divider(height: 24),
            
            // Location Info
            Row(
              children: [
                Column(
                  children: [
                    Icon(Iconsax.location, size: 18, color: AppColors.primary),
                    Container(
                      width: 1,
                      height: 24,
                      color: AppColors.border,
                    ),
                    Icon(Iconsax.location_tick, size: 18, color: AppColors.success),
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
            
            // Time and Seats Row
            Row(
              children: [
                _InfoChip(
                  icon: Iconsax.clock,
                  label: DateFormat('h:mm a').format(ride.departureTime),
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Iconsax.people,
                  label: ride.seatsDisplay,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Book Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text('Book Seat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
