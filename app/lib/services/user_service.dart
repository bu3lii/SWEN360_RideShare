import '../config/api_config.dart';
import '../models/models.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<DashboardData?> getDashboard() async {
    final response = await _api.get(ApiConfig.dashboardUrl);

    if (response.success && response.data['data'] != null) {
      return DashboardData.fromJson(response.data['data']);
    }

    return null;
  }

  Future<User?> updateProfile({
    String? name,
    String? phoneNumber,
    String? profilePicture,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (profilePicture != null) body['profilePicture'] = profilePicture;

    final response = await _api.patch(ApiConfig.profileUrl, body: body);

    if (response.success && response.data['data'] != null) {
      return User.fromJson(response.data['data']['user']);
    }

    return null;
  }

  Future<User?> becomeDriver({
    required String model,
    required String color,
    required String licensePlate,
    required int totalSeats,
  }) async {
    final response = await _api.post(
      ApiConfig.becomeDriverUrl,
      body: {
        'model': model,
        'color': color,
        'licensePlate': licensePlate,
        'totalSeats': totalSeats,
      },
    );

    if (response.success && response.data['data'] != null) {
      return User.fromJson(response.data['data']['user']);
    }

    return null;
  }

  Future<User?> updateCarDetails({
    required String model,
    required String color,
    required String licensePlate,
    required int totalSeats,
  }) async {
    final response = await _api.patch(
      ApiConfig.carDetailsUrl,
      body: {
        'model': model,
        'color': color,
        'licensePlate': licensePlate,
        'totalSeats': totalSeats,
      },
    );

    if (response.success && response.data['data'] != null) {
      return User.fromJson(response.data['data']['user']);
    }

    return null;
  }

  Future<List<RideHistoryItem>> getRideHistory({
    String type = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '${ApiConfig.rideHistoryUrl}?type=$type&page=$page&limit=$limit',
    );

    if (response.success && response.data['data'] != null) {
      final history = response.data['data']['history'] as List;
      return history.map((h) => RideHistoryItem.fromJson(h)).toList();
    }

    return [];
  }

  Future<bool> deactivateAccount() async {
    final response = await _api.delete(ApiConfig.deactivateAccountUrl);
    return response.success;
  }

  Future<User?> getUser(String userId) async {
    final response = await _api.get(ApiConfig.userUrl(userId));

    if (response.success && response.data['data'] != null) {
      return User.fromJson(response.data['data']['user']);
    }

    return null;
  }
}

class DashboardData {
  final DashboardUser user;
  final List<Booking> upcomingRidesAsPassenger;
  final List<Ride> upcomingRidesAsDriver;
  final Booking? activeRideAsPassenger;
  final Ride? activeRideAsDriver;
  final List<Booking> recentBookings;
  final ImpactData impact;

  DashboardData({
    required this.user,
    required this.upcomingRidesAsPassenger,
    required this.upcomingRidesAsDriver,
    this.activeRideAsPassenger,
    this.activeRideAsDriver,
    required this.recentBookings,
    required this.impact,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      user: DashboardUser.fromJson(json['user'] ?? {}),
      upcomingRidesAsPassenger: (json['upcomingRidesAsPassenger'] as List?)
          ?.map((b) => Booking.fromJson(b))
          .toList() ?? [],
      upcomingRidesAsDriver: (json['upcomingRidesAsDriver'] as List?)
          ?.map((r) => Ride.fromJson(r))
          .toList() ?? [],
      activeRideAsPassenger: json['activeRideAsPassenger'] != null
          ? Booking.fromJson(json['activeRideAsPassenger'])
          : null,
      activeRideAsDriver: json['activeRideAsDriver'] != null
          ? Ride.fromJson(json['activeRideAsDriver'])
          : null,
      recentBookings: (json['recentBookings'] as List?)
          ?.map((b) => Booking.fromJson(b))
          .toList() ?? [],
      impact: ImpactData.fromJson(json['impact'] ?? {}),
    );
  }
}

class DashboardUser {
  final String name;
  final String email;
  final String? profilePicture;
  final bool isDriver;
  final Rating rating;
  final UserStats stats;

  DashboardUser({
    required this.name,
    required this.email,
    this.profilePicture,
    required this.isDriver,
    required this.rating,
    required this.stats,
  });

  factory DashboardUser.fromJson(Map<String, dynamic> json) {
    return DashboardUser(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'],
      isDriver: json['isDriver'] ?? false,
      rating: Rating.fromJson(json['rating'] ?? {}),
      stats: UserStats.fromJson(json['stats'] ?? {}),
    );
  }
}

class ImpactData {
  final int totalRides;
  final double moneySaved;
  final String co2Saved;

  ImpactData({
    required this.totalRides,
    required this.moneySaved,
    required this.co2Saved,
  });

  factory ImpactData.fromJson(Map<String, dynamic> json) {
    return ImpactData(
      totalRides: json['totalRides'] ?? 0,
      moneySaved: (json['moneySaved'] ?? 0).toDouble(),
      co2Saved: json['co2Saved']?.toString() ?? '0',
    );
  }
}

class RideHistoryItem {
  final String type;
  final DateTime date;
  final Ride? ride;
  final BookingInfo? booking;
  final List<PassengerInfo>? passengers;
  final double? totalEarnings;

  RideHistoryItem({
    required this.type,
    required this.date,
    this.ride,
    this.booking,
    this.passengers,
    this.totalEarnings,
  });

  factory RideHistoryItem.fromJson(Map<String, dynamic> json) {
    return RideHistoryItem(
      type: json['type'] ?? 'passenger',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      ride: json['ride'] != null ? Ride.fromJson(json['ride']) : null,
      booking: json['booking'] != null ? BookingInfo.fromJson(json['booking']) : null,
      passengers: (json['passengers'] as List?)
          ?.map((p) => PassengerInfo.fromJson(p))
          .toList(),
      totalEarnings: json['totalEarnings']?.toDouble(),
    );
  }
}

class BookingInfo {
  final String id;
  final int seatsBooked;
  final double totalAmount;
  final bool hasReviewed;

  BookingInfo({
    required this.id,
    required this.seatsBooked,
    required this.totalAmount,
    required this.hasReviewed,
  });

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
    return BookingInfo(
      id: json['_id'] ?? '',
      seatsBooked: json['seatsBooked'] ?? 1,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      hasReviewed: json['hasReviewed'] ?? false,
    );
  }
}

class PassengerInfo {
  final String name;
  final String? profilePicture;
  final int seatsBooked;

  PassengerInfo({
    required this.name,
    this.profilePicture,
    required this.seatsBooked,
  });

  factory PassengerInfo.fromJson(Map<String, dynamic> json) {
    return PassengerInfo(
      name: json['name'] ?? '',
      profilePicture: json['profilePicture'],
      seatsBooked: json['seatsBooked'] ?? 1,
    );
  }
}