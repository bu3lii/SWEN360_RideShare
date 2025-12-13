import 'user.dart';

class Ride {
  final String id;
  final User? driver;
  final String? driverId;
  final Location startLocation;
  final Location destination;
  final RouteInfo? route;
  final DateTime departureTime;
  final DateTime? estimatedArrivalTime;
  final int totalSeats;
  final int availableSeats;
  final String genderPreference;
  final double pricePerSeat;
  final String currency;
  final String status;
  final String? cancellationReason;
  final String? notes;
  final bool isRecurring;
  final List<String> recurringDays;
  final int totalBookings;
  final int completedBookings;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed fields from search
  final double? distanceFromStart;
  final double? distanceToDestination;

  Ride({
    required this.id,
    this.driver,
    this.driverId,
    required this.startLocation,
    required this.destination,
    this.route,
    required this.departureTime,
    this.estimatedArrivalTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.genderPreference,
    required this.pricePerSeat,
    required this.currency,
    required this.status,
    this.cancellationReason,
    this.notes,
    required this.isRecurring,
    required this.recurringDays,
    required this.totalBookings,
    required this.completedBookings,
    required this.createdAt,
    required this.updatedAt,
    this.distanceFromStart,
    this.distanceToDestination,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['_id'] ?? json['id'] ?? '',
      driver: json['driver'] != null 
          ? (json['driver'] is Map ? User.fromJson(json['driver']) : null)
          : null,
      driverId: json['driver'] is String 
          ? json['driver'] 
          : (json['driver']?['_id'] ?? json['driver']?['id']),
      startLocation: Location.fromJson(json['startLocation'] ?? {}),
      destination: Location.fromJson(json['destination'] ?? {}),
      route: json['route'] != null ? RouteInfo.fromJson(json['route']) : null,
      departureTime: json['departureTime'] != null 
          ? DateTime.parse(json['departureTime']) 
          : DateTime.now(),
      estimatedArrivalTime: json['estimatedArrivalTime'] != null 
          ? DateTime.parse(json['estimatedArrivalTime']) 
          : null,
      totalSeats: json['totalSeats'] ?? 4,
      availableSeats: json['availableSeats'] ?? 0,
      genderPreference: json['genderPreference'] ?? 'any',
      pricePerSeat: (json['pricePerSeat'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'BHD',
      status: json['status'] ?? 'scheduled',
      cancellationReason: json['cancellationReason'],
      notes: json['notes'],
      isRecurring: json['isRecurring'] ?? false,
      recurringDays: (json['recurringDays'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      distanceFromStart: json['distanceFromStart']?.toDouble(),
      distanceToDestination: json['distanceToDestination']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'driver': driver?.toJson(),
      'startLocation': startLocation.toJson(),
      'destination': destination.toJson(),
      'route': route?.toJson(),
      'departureTime': departureTime.toIso8601String(),
      'estimatedArrivalTime': estimatedArrivalTime?.toIso8601String(),
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'genderPreference': genderPreference,
      'pricePerSeat': pricePerSeat,
      'currency': currency,
      'status': status,
      'cancellationReason': cancellationReason,
      'notes': notes,
      'isRecurring': isRecurring,
      'recurringDays': recurringDays,
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isFull => availableSeats == 0;
  bool get isActive => status == 'scheduled' && departureTime.isAfter(DateTime.now());
  int get bookedSeats => totalSeats - availableSeats;
  
  String get formattedPrice => '$pricePerSeat $currency';
  
  String get seatsDisplay => '$availableSeats seats left';
}

class Location {
  final String address;
  final Coordinates coordinates;

  Location({
    required this.address,
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'] ?? '',
      coordinates: Coordinates.fromJson(json['coordinates'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'coordinates': coordinates.toJson(),
    };
  }
}

class Coordinates {
  final double lat;
  final double lng;

  const Coordinates({
    required this.lat,
    required this.lng,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

class RouteInfo {
  final String? polyline;
  final List<Coordinates>? waypoints;
  final double distance; // in meters
  final double duration; // in seconds

  RouteInfo({
    this.polyline,
    this.waypoints,
    required this.distance,
    required this.duration,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      polyline: json['polyline'],
      waypoints: (json['waypoints'] as List?)
          ?.map((e) => Coordinates.fromJson(e))
          .toList(),
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'polyline': polyline,
      'waypoints': waypoints?.map((e) => e.toJson()).toList(),
      'distance': distance,
      'duration': duration,
    };
  }

  String get distanceKm => (distance / 1000).toStringAsFixed(1);
  int get durationMinutes => (duration / 60).ceil();
}