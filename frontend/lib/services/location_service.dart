import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/ride.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _api = ApiService();
  StreamSubscription<Position>? _positionSubscription;
  
  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // Start tracking location
  Stream<Position> startLocationTracking() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  // Stop tracking
  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Search places - GET /api/v1/location/search?q=query
  Future<List<PlaceResult>> searchPlaces(String query, {Coordinates? near}) async {
    // Backend expects 'q' not 'query'
    var url = '${ApiConfig.searchPlacesUrl}?q=${Uri.encodeComponent(query)}';
    if (near != null) {
      url += '&lat=${near.lat}&lng=${near.lng}';
    }

    debugPrint('Searching places: $url');
    final response = await _api.get(url, requireAuth: false);

    if (response.success && response.data['data'] != null) {
      final places = response.data['data'] as List;
      return places.map((p) => PlaceResult.fromJson(p)).toList();
    }

    return [];
  }

  // Reverse geocode - POST /api/v1/location/reverse-geocode with body {lat, lng}
  Future<String?> reverseGeocode(double lat, double lng) async {
    debugPrint('Reverse geocoding: $lat, $lng');
    
    // Backend expects POST with body, not GET with query params
    final response = await _api.post(
      ApiConfig.reverseGeocodeUrl,
      body: {
        'lat': lat,
        'lng': lng,
      },
      requireAuth: false,
    );

    debugPrint('Reverse geocode response: ${response.success}, ${response.data}');

    if (response.success && response.data['data'] != null) {
      // Backend returns {address, location, displayName}
      final data = response.data['data'];
      return data['displayName'] ?? data['address'] ?? 'Unknown location';
    }

    // Fallback: return formatted coordinates if API fails
    return 'Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  // Calculate route between two points - POST /api/v1/location/route
  Future<RouteResult?> calculateRoute(
    Coordinates origin,
    Coordinates destination,
  ) async {
    debugPrint('Calculating route from (${origin.lat}, ${origin.lng}) to (${destination.lat}, ${destination.lng})');
    
    // Backend expects {start: {lat, lng}, end: {lat, lng}} NOT origin/destination
    final response = await _api.post(
      ApiConfig.calculateRouteUrl,
      body: {
        'start': {'lat': origin.lat, 'lng': origin.lng},
        'end': {'lat': destination.lat, 'lng': destination.lng},
      },
      requireAuth: false,
    );

    debugPrint('Route response: ${response.success}, ${response.data}');

    if (response.success && response.data['data'] != null) {
      return RouteResult.fromJson(response.data['data']);
    }

    // Fallback: calculate approximate distance using Haversine formula
    final distanceKm = _calculateHaversineDistance(
      origin.lat, origin.lng,
      destination.lat, destination.lng,
    );
    
    // Estimate duration (assuming 40 km/h average speed)
    final durationSeconds = (distanceKm / 40) * 3600;
    
    return RouteResult(
      routePoints: [origin, destination], // Straight line fallback
      distance: distanceKm * 1000, // convert km to meters
      duration: durationSeconds,
      waypoints: [origin, destination],
    );
  }

  // Haversine formula for distance calculation (fallback)
  double _calculateHaversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      (math.sin(dLat / 2) * math.sin(dLat / 2)) +
      (math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * 
       math.sin(dLon / 2) * math.sin(dLon / 2));
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * (math.pi / 180);

  // Get ETA - POST /api/v1/location/eta
  Future<EtaResult?> getEta(
    Coordinates origin,
    Coordinates destination,
  ) async {
    final response = await _api.post(
      ApiConfig.etaUrl,
      body: {
        'start': {'lat': origin.lat, 'lng': origin.lng},
        'end': {'lat': destination.lat, 'lng': destination.lng},
      },
      requireAuth: false,
    );

    if (response.success && response.data['data'] != null) {
      return EtaResult.fromJson(response.data['data']);
    }

    return null;
  }

  // Check if location is in service area - POST /api/v1/location/validate
  Future<bool> isInServiceArea(double lat, double lng) async {
    final response = await _api.post(
      ApiConfig.validateLocationUrl,
      body: {
        'lat': lat,
        'lng': lng,
      },
      requireAuth: false,
    );

    if (response.success && response.data['data'] != null) {
      return response.data['data']['isValid'] ?? false;
    }

    // Fallback: check if within Bahrain bounds manually
    return _isWithinBahrainBounds(lat, lng);
  }

  // Manual Bahrain bounds check
  bool _isWithinBahrainBounds(double lat, double lng) {
    const minLat = 25.5;
    const maxLat = 26.4;
    const minLng = 50.2;
    const maxLng = 50.9;
    
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }
}

class PlaceResult {
  final String placeId;
  final String name;
  final String address;
  final Coordinates coordinates;
  final String? type;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.coordinates,
    this.type,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      placeId: json['placeId'] ?? json['place_id'] ?? '',
      name: json['name'] ?? json['displayName'] ?? '',
      address: json['address'] ?? json['displayName'] ?? '',
      coordinates: Coordinates(
        lat: (json['lat'] ?? json['coordinates']?['lat'] ?? 0).toDouble(),
        lng: (json['lng'] ?? json['lon'] ?? json['coordinates']?['lng'] ?? 0).toDouble(),
      ),
      type: json['type'],
    );
  }
}

class RouteResult {
  final List<Coordinates> routePoints; // Actual road route points
  final double distance; // meters
  final double duration; // seconds
  final List<Coordinates> waypoints;

  RouteResult({
    required this.routePoints,
    required this.distance,
    required this.duration,
    required this.waypoints,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    // Parse GeoJSON geometry from backend
    List<Coordinates> points = [];
    
    final geometry = json['geometry'];
    if (geometry != null) {
      if (geometry is Map && geometry['coordinates'] != null) {
        // GeoJSON format: {type: "LineString", coordinates: [[lng, lat], ...]}
        final coords = geometry['coordinates'] as List;
        points = coords.map((c) => Coordinates(
          lat: (c[1] as num).toDouble(),  // GeoJSON is [lng, lat]
          lng: (c[0] as num).toDouble(),
        )).toList();
      } else if (geometry is String) {
        // Encoded polyline - would need decoding library
        // For now, fall back to waypoints
      }
    }
    
    // Parse waypoints
    List<Coordinates> waypointsList = [];
    if (json['waypoints'] != null) {
      waypointsList = (json['waypoints'] as List).map((w) {
        if (w['location'] != null) {
          // OSRM format: {location: {lat, lng}}
          return Coordinates(
            lat: (w['location']['lat'] ?? 0).toDouble(),
            lng: (w['location']['lng'] ?? 0).toDouble(),
          );
        }
        return Coordinates(
          lat: (w['lat'] ?? 0).toDouble(),
          lng: (w['lng'] ?? w['lon'] ?? 0).toDouble(),
        );
      }).toList();
    }
    
    // If no route points from geometry, use waypoints
    if (points.isEmpty && waypointsList.isNotEmpty) {
      points = waypointsList;
    }

    return RouteResult(
      routePoints: points,
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      waypoints: waypointsList,
    );
  }

  String get distanceText {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toInt()} m';
  }

  String get durationText {
    final minutes = (duration / 60).ceil();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
    return '$minutes min';
  }
}

class EtaResult {
  final DateTime estimatedArrival;
  final double duration; // seconds
  final double distance; // meters

  EtaResult({
    required this.estimatedArrival,
    required this.duration,
    required this.distance,
  });

  factory EtaResult.fromJson(Map<String, dynamic> json) {
    return EtaResult(
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.parse(json['estimatedArrival'])
          : DateTime.now().add(Duration(seconds: (json['duration'] ?? 0).toInt())),
      duration: (json['duration'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
    );
  }
}