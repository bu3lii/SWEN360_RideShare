import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/ride.dart';
import '../providers/auth_provider.dart';
import '../services/ride_service.dart';
import '../services/location_service.dart';
import '../widgets/widgets.dart';
import '../widgets/location_picker.dart';

class PostRideScreen extends StatefulWidget {
  const PostRideScreen({super.key});

  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rideService = RideService();
  final _locationService = LocationService();
  final _notesController = TextEditingController();
  
  // Location data
  Location? _pickupLocation;
  Location? _destinationLocation;
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  
  // Route data
  RouteResult? _routeInfo;
  bool _isLoadingRoute = false;
  
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _availableSeats = 3;
  String _genderPreference = 'any';
  String _carModel = '';
  String _carColor = '';
  String _licensePlate = '';
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCarDetails();
  }

  void _loadCarDetails() {
    final user = context.read<AuthProvider>().user;
    if (user?.carDetails != null) {
      setState(() {
        _carModel = user!.carDetails!.model;
        _carColor = user.carDetails!.color;
        _licensePlate = user.carDetails!.licensePlate;
        _availableSeats = user.carDetails!.totalSeats;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectPickupLocation() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: 'Select Pickup',
          initialLocation: _pickupLatLng,
          initialAddress: _pickupLocation?.address,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _pickupLocation = result.location;
        _pickupLatLng = result.latLng;
      });
      _calculateRoute();
    }
  }

  Future<void> _selectDestinationLocation() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: 'Select Destination',
          initialLocation: _destinationLatLng,
          initialAddress: _destinationLocation?.address,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _destinationLocation = result.location;
        _destinationLatLng = result.latLng;
      });
      _calculateRoute();
    }
  }

  Future<void> _calculateRoute() async {
    if (_pickupLocation == null || _destinationLocation == null) return;

    setState(() => _isLoadingRoute = true);

    final route = await _locationService.calculateRoute(
      _pickupLocation!.coordinates,
      _destinationLocation!.coordinates,
    );

    if (mounted) {
      setState(() {
        _routeInfo = route;
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _handlePostRide() async {
    if (_pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup location'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select destination'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final departureTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final result = await _rideService.createRide(
      startLocation: _pickupLocation!,
      destination: _destinationLocation!,
      departureTime: departureTime,
      totalSeats: _availableSeats,
      genderPreference: _genderPreference,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      _showConfirmationDialog();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to post ride'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.tick_circle, size: 40, color: AppColors.success),
            ),
            const SizedBox(height: 24),
            Text('Ride Posted!', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Your ride has been posted successfully. Riders can now book seats.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'View My Rides',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/my-rides');
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              text: 'Back to Dashboard',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final hasCarDetails = user?.carDetails != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post a Ride', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: _isLoading,
          child: !hasCarDetails
              ? _buildNoCarDetailsView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        
                        Text(
                          'Share your trip details',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Route Map Preview
                        if (_pickupLatLng != null || _destinationLatLng != null)
                          _buildMapPreview().animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1, end: 0),
                        
                        // Pickup Location
                        _buildLocationSelector(
                          label: 'Pickup Location',
                          icon: Iconsax.location,
                          iconColor: AppColors.primary,
                          location: _pickupLocation,
                          onTap: _selectPickupLocation,
                          hint: 'Tap to select pickup point',
                        ).animate()
                          .fadeIn(duration: 300.ms, delay: 100.ms)
                          .slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        // Destination Location
                        _buildLocationSelector(
                          label: 'Destination',
                          icon: Iconsax.location_tick,
                          iconColor: AppColors.success,
                          location: _destinationLocation,
                          onTap: _selectDestinationLocation,
                          hint: 'Tap to select destination',
                        ).animate()
                          .fadeIn(duration: 300.ms, delay: 150.ms)
                          .slideY(begin: 0.1, end: 0),
                        
                        // Route Info
                        if (_routeInfo != null)
                          _buildRouteInfo().animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Date & Time
                        Row(
                          children: [
                            Expanded(
                              child: _DateTimeSelector(
                                label: 'Date',
                                value: DateFormat('MMM d, yyyy').format(_selectedDate),
                                icon: Iconsax.calendar,
                                onTap: _selectDate,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _DateTimeSelector(
                                label: 'Time',
                                value: _selectedTime.format(context),
                                icon: Iconsax.clock,
                                onTap: _selectTime,
                              ),
                            ),
                          ],
                        ).animate()
                          .fadeIn(duration: 300.ms, delay: 200.ms)
                          .slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Seats
                        _NumberSelector(
                          label: 'Available Seats',
                          value: _availableSeats,
                          min: 1,
                          max: 7,
                          onChanged: (v) => setState(() => _availableSeats = v),
                        ).animate()
                          .fadeIn(duration: 300.ms, delay: 250.ms)
                          .slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Gender Preference
                        Text('Gender Preference', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        Wrap(
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
                        ).animate()
                          .fadeIn(duration: 300.ms, delay: 350.ms)
                          .slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Notes
                        Text('Notes (Optional)', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Any additional info for passengers...',
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ).animate()
                          .fadeIn(duration: 300.ms, delay: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // Car Details Summary
                        _buildCarDetailsSummary().animate()
                          .fadeIn(duration: 300.ms, delay: 450.ms)
                          .slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 32),
                        
                        // Post Button
                        PrimaryButton(
                          text: 'Post Ride',
                          onPressed: _handlePostRide,
                          isLoading: _isLoading,
                        ).animate()
                          .fadeIn(duration: 300.ms, delay: 500.ms)
                          .slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _pickupLatLng ?? _destinationLatLng ?? const LatLng(26.0667, 50.5577),
                initialZoom: 12,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.uniride',
                ),
                // Route line
                if (_pickupLatLng != null && _destinationLatLng != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_pickupLatLng!, _destinationLatLng!],
                        strokeWidth: 4,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                // Markers
                MarkerLayer(
                  markers: [
                    if (_pickupLatLng != null)
                      Marker(
                        point: _pickupLatLng!,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Iconsax.location, color: Colors.white, size: 16),
                        ),
                      ),
                    if (_destinationLatLng != null)
                      Marker(
                        point: _destinationLatLng!,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Iconsax.location_tick, color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Loading overlay
            if (_isLoadingRoute)
              Container(
                color: Colors.white.withOpacity(0.7),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Location? location,
    required VoidCallback onTap,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: location != null
                  ? Border.all(color: iconColor.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    location?.address ?? hint,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: location != null 
                          ? AppColors.textPrimary 
                          : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _RouteInfoItem(
            icon: Iconsax.routing,
            label: 'Distance',
            value: _routeInfo!.distanceText,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.primary.withOpacity(0.2),
          ),
          _RouteInfoItem(
            icon: Iconsax.clock,
            label: 'Duration',
            value: _routeInfo!.durationText,
          ),
        ],
      ),
    );
  }

  Widget _buildCarDetailsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.car, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Your Car', style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              )),
            ],
          ),
          const SizedBox(height: 12),
          _CarDetailRow(label: 'Model', value: _carModel),
          const SizedBox(height: 8),
          _CarDetailRow(label: 'Color', value: _carColor),
          const SizedBox(height: 8),
          _CarDetailRow(label: 'License', value: _licensePlate),
        ],
      ),
    );
  }

  Widget _buildNoCarDetailsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.car, size: 50, color: AppColors.warning),
            ),
            const SizedBox(height: 24),
            Text('Complete Your Profile', style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'You need to add your car details before posting a ride.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Add Car Details',
              onPressed: () => Navigator.pushNamed(context, '/become-driver'),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widgets
class _RouteInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RouteInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        )),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        )),
      ],
    );
  }
}

class _DateTimeSelector extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateTimeSelector({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Text(value, style: AppTextStyles.input),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberSelector extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberSelector({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.people, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Text('$value', style: AppTextStyles.input),
              const Spacer(),
              IconButton(
                icon: const Icon(Iconsax.minus_cirlce),
                color: value > min ? AppColors.primary : AppColors.textSecondary,
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              IconButton(
                icon: const Icon(Iconsax.add_circle),
                color: value < max ? AppColors.primary : AppColors.textSecondary,
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceSelector extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _PriceSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.money, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Text(value.toStringAsFixed(1), style: AppTextStyles.input),
              const Spacer(),
              IconButton(
                icon: const Icon(Iconsax.minus_cirlce),
                color: value > 0.5 ? AppColors.primary : AppColors.textSecondary,
                onPressed: value > 0.5 ? () => onChanged(value - 0.5) : null,
              ),
              IconButton(
                icon: const Icon(Iconsax.add_circle),
                color: value < 10 ? AppColors.primary : AppColors.textSecondary,
                onPressed: value < 10 ? () => onChanged(value + 0.5) : null,
              ),
            ],
          ),
        ),
      ],
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CarDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _CarDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        )),
        Text(value, style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
        )),
      ],
    );
  }
}