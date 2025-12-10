import '../config/api_config.dart';
import '../models/models.dart';
import 'api_service.dart';

class RideService {
  final ApiService _api = ApiService();

  Future<List<Ride>> getAvailableRides({
    required double startLat, // Required for radius-based search
    required double startLng, // Required for radius-based search
    double? destLat,
    double? destLng,
    String? date,
    int? minSeats,
    String? genderPreference,
    int? radius, // Radius in meters
    int page = 1,
    int limit = 20,
  }) async {
    String url = ApiConfig.ridesUrl;
    final params = <String>[];

    // Start location is required
    params.add('startLat=$startLat');
    params.add('startLng=$startLng');
    
    if (destLat != null) params.add('destLat=$destLat');
    if (destLng != null) params.add('destLng=$destLng');
    if (date != null) params.add('date=$date');
    if (minSeats != null) params.add('minSeats=$minSeats');
    if (genderPreference != null) params.add('genderPreference=$genderPreference');
    if (radius != null) params.add('radius=$radius');
    params.add('page=$page');
    params.add('limit=$limit');

    url += '?${params.join('&')}';

    final response = await _api.get(url, requireAuth: false);

    if (response.success && response.data['data'] != null) {
      final rides = response.data['data']['rides'] as List;
      return rides.map((r) => Ride.fromJson(r)).toList();
    }

    return [];
  }

  Future<List<Ride>> searchRides({
    Location? startLocation,
    Location? destination,
    String? departureDate,
    int minSeats = 1,
    double? maxPrice,
    String? genderPreference,
    int maxWalkingDistance = 1000,
  }) async {
    final body = <String, dynamic>{
      'minSeats': minSeats,
      'maxWalkingDistance': maxWalkingDistance,
    };

    if (startLocation != null) {
      body['startLocation'] = startLocation.toJson();
    }
    if (destination != null) {
      body['destination'] = destination.toJson();
    }
    if (departureDate != null) {
      body['departureDate'] = departureDate;
    }
    if (maxPrice != null) {
      body['maxPrice'] = maxPrice;
    }
    if (genderPreference != null) {
      body['genderPreference'] = genderPreference;
    }

    final response = await _api.post(
      ApiConfig.searchRidesUrl,
      body: body,
      requireAuth: false,
    );

    if (response.success && response.data['data'] != null) {
      final rides = response.data['data']['rides'] as List;
      return rides.map((r) => Ride.fromJson(r)).toList();
    }

    return [];
  }

  Future<Ride?> getRide(String rideId) async {
    final response = await _api.get(ApiConfig.rideUrl(rideId));

    if (response.success && response.data['data'] != null) {
      return Ride.fromJson(response.data['data']['ride']);
    }

    return null;
  }

  Future<Ride?> createRide({
    required Location startLocation,
    required Location destination,
    required DateTime departureTime,
    required int totalSeats,
    String genderPreference = 'any',
    String? notes,
    bool isRecurring = false,
    List<String>? recurringDays,
  }) async {
    final response = await _api.post(
      ApiConfig.ridesUrl,
      body: {
        'startLocation': startLocation.toJson(),
        'destination': destination.toJson(),
        'departureTime': departureTime.toIso8601String(),
        'totalSeats': totalSeats,
        'genderPreference': genderPreference,
        'notes': notes,
        'isRecurring': isRecurring,
        'recurringDays': recurringDays ?? [],
      },
    );

    if (response.success && response.data['data'] != null) {
      return Ride.fromJson(response.data['data']['ride']);
    }

    return null;
  }

  Future<Ride?> updateRide(
    String rideId, {
    DateTime? departureTime,
    int? totalSeats,
    String? notes,
    String? genderPreference,
  }) async {
    final body = <String, dynamic>{};

    if (departureTime != null) {
      body['departureTime'] = departureTime.toIso8601String();
    }
    if (totalSeats != null) body['totalSeats'] = totalSeats;
    if (notes != null) body['notes'] = notes;
    if (genderPreference != null) body['genderPreference'] = genderPreference;

    final response = await _api.patch(
      ApiConfig.rideUrl(rideId),
      body: body,
    );

    if (response.success && response.data['data'] != null) {
      return Ride.fromJson(response.data['data']['ride']);
    }

    return null;
  }

  Future<bool> cancelRide(String rideId, {String? reason}) async {
    final response = await _api.delete(
      ApiConfig.rideUrl(rideId),
      body: reason != null ? {'reason': reason} : null,
    );

    return response.success;
  }

  Future<List<Ride>> getMyRides({String? status, int page = 1, int limit = 20}) async {
    String url = '${ApiConfig.myRidesUrl}?page=$page&limit=$limit';
    if (status != null) {
      url += '&status=$status';
    }

    final response = await _api.get(url);

    if (response.success && response.data['data'] != null) {
      final rides = response.data['data']['rides'] as List;
      return rides.map((r) => Ride.fromJson(r)).toList();
    }

    return [];
  }

  Future<bool> startRide(String rideId) async {
    final response = await _api.patch(ApiConfig.startRideUrl(rideId));
    return response.success;
  }

  Future<Map<String, dynamic>?> completeRide(String rideId) async {
    final response = await _api.patch(ApiConfig.completeRideUrl(rideId));
    
    if (response.success && response.data['data'] != null) {
      final data = response.data['data'];
      return {
        'ride': Ride.fromJson(data['ride']),
        'driverTotalEarnings': (data['driverTotalEarnings'] ?? 0).toDouble(),
        'bookings': (data['bookings'] as List?)
            ?.map((b) => Booking.fromJson(b))
            .toList() ?? [],
      };
    }
    
    return null;
  }

  Future<RouteInfo?> calculateRoute(Coordinates start, Coordinates end) async {
    final response = await _api.post(
      ApiConfig.routeUrl,
      body: {
        'start': start.toJson(),
        'end': end.toJson(),
      },
      requireAuth: false,
    );

    if (response.success && response.data['data'] != null) {
      return RouteInfo.fromJson(response.data['data']['route']);
    }

    return null;
  }
}