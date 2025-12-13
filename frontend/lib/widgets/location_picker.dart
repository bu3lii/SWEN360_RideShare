import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../models/ride.dart';
import '../services/location_service.dart';

/// A full-screen map picker for selecting a location
class LocationPickerScreen extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;
  bool _isSearching = false;
  List<PlaceResult> _searchResults = [];

  // Bahrain bounds
  static const LatLng _bahrainCenter = LatLng(26.0667, 50.5577);
  static const double _defaultZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _selectedAddress = widget.initialAddress;
    
    if (_selectedLocation == null) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        final location = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedLocation = location;
        });
        _mapController.move(location, _defaultZoom);
        _reverseGeocode(location);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    final address = await _locationService.reverseGeocode(
      location.latitude,
      location.longitude,
    );
    
    if (mounted && address != null) {
      setState(() {
        _selectedAddress = address;
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await _locationService.searchPlaces(
      query,
      near: _selectedLocation != null
          ? Coordinates(
              lat: _selectedLocation!.latitude,
              lng: _selectedLocation!.longitude,
            )
          : null,
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(PlaceResult place) {
    final location = LatLng(
      place.coordinates.lat,
      place.coordinates.lng,
    );
    
    setState(() {
      _selectedLocation = location;
      _selectedAddress = place.address;
      _searchResults = [];
      _searchController.clear();
    });
    
    _mapController.move(location, 16.0);
    FocusScope.of(context).unfocus();
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
      _selectedAddress = null;
    });
    _reverseGeocode(location);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, LocationPickerResult(
        location: Location(
          address: _selectedAddress ?? 'Selected Location',
          coordinates: Coordinates(
            lat: _selectedLocation!.latitude,
            lng: _selectedLocation!.longitude,
          ),
        ),
        latLng: _selectedLocation!,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? _bahrainCenter,
              initialZoom: _defaultZoom,
              onTap: _onMapTap,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.uniride',
              ),
              // Selected location marker
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: const _LocationPin(),
                    ),
                  ],
                ),
            ],
          ),

          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchPlaces,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Iconsax.close_circle, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                // Search results
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
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
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Iconsax.location, 
                            color: AppColors.primary,
                            size: 20,
                          ),
                          title: Text(
                            place.name,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            place.address,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Current location button
          Positioned(
            right: 16,
            bottom: 160,
            child: FloatingActionButton.small(
              heroTag: 'currentLocation',
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.gps, color: AppColors.primary),
            ),
          ),

          // Bottom card with address and confirm button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.location,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Location',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedAddress ?? 'Tap on map to select',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedLocation != null ? _confirmLocation : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                        ),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPin extends StatelessWidget {
  const _LocationPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Iconsax.location,
            color: Colors.white,
            size: 20,
          ),
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

class LocationPickerResult {
  final Location location;
  final LatLng latLng;

  LocationPickerResult({
    required this.location,
    required this.latLng,
  });
}