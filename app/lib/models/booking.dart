import 'ride.dart';
import 'user.dart';

class Booking {
  final String id;
  final Ride? ride;
  final String? rideId;
  final User? passenger;
  final String? passengerId;
  final int seatsBooked;
  final Location? pickupLocation;
  final double totalAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String status;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final DateTime? confirmedAt;
  final String? confirmedBy;
  final DateTime? pickedUpAt;
  final DateTime? droppedOffAt;
  final bool hasReviewed;
  final String? reviewId;
  final String? specialRequests;
  final String? riderSafeCode;
  final String? driverSafeCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    this.ride,
    this.rideId,
    this.passenger,
    this.passengerId,
    required this.seatsBooked,
    this.pickupLocation,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.status,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
    this.confirmedAt,
    this.confirmedBy,
    this.pickedUpAt,
    this.droppedOffAt,
    required this.hasReviewed,
    this.reviewId,
    this.specialRequests,
    this.riderSafeCode,
    this.driverSafeCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      ride: json['ride'] != null && json['ride'] is Map
          ? Ride.fromJson(json['ride'])
          : null,
      rideId: json['ride'] is String ? json['ride'] : null,
      passenger: json['passenger'] != null && json['passenger'] is Map
          ? User.fromJson(json['passenger'])
          : null,
      passengerId: json['passenger'] is String 
          ? json['passenger'] 
          : (json['passenger']?['_id'] ?? json['passenger']?['id']),
      seatsBooked: json['seatsBooked'] ?? 1,
      pickupLocation: json['pickupLocation'] != null
          ? Location.fromJson(json['pickupLocation'])
          : null,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'cash',
      status: json['status'] ?? 'pending',
      cancellationReason: json['cancellationReason'],
      cancelledBy: json['cancelledBy'],
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      confirmedBy: json['confirmedBy'],
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'])
          : null,
      droppedOffAt: json['droppedOffAt'] != null
          ? DateTime.parse(json['droppedOffAt'])
          : null,
      hasReviewed: json['hasReviewed'] ?? false,
      reviewId: json['reviewId'],
      specialRequests: json['specialRequests'],
      riderSafeCode: json['riderSafeCode'],
      driverSafeCode: json['driverSafeCode'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ride': ride?.toJson() ?? rideId,
      'passenger': passenger?.toJson() ?? passengerId,
      'seatsBooked': seatsBooked,
      'pickupLocation': pickupLocation?.toJson(),
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'status': status,
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'confirmedBy': confirmedBy,
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'droppedOffAt': droppedOffAt?.toIso8601String(),
      'hasReviewed': hasReviewed,
      'reviewId': reviewId,
      'specialRequests': specialRequests,
      'riderSafeCode': riderSafeCode,
      'driverSafeCode': driverSafeCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'pending' || status == 'confirmed';
  bool get canCancel => isActive;
  bool get canReview => status == 'completed' && !hasReviewed;
  
  String get formattedAmount => '$totalAmount BHD';
}

class BookingStats {
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double completionRate;
  final double totalSpent;

  BookingStats({
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.completionRate,
    required this.totalSpent,
  });

  factory BookingStats.fromJson(Map<String, dynamic> json) {
    return BookingStats(
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      completionRate: double.tryParse(json['completionRate']?.toString() ?? '0') ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
    );
  }
}