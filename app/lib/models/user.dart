class User {
  final String id;
  final String name;
  final String email;
  final String universityId;
  final String phoneNumber;
  final String gender;
  final String? profilePicture;
  final String role;
  final bool isEmailVerified;
  final bool isActive;
  final String accountStatus;
  final bool isDriver;
  final CarDetails? carDetails;
  final Rating rating;
  final UserStats stats;
  final bool twoFactorEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.universityId,
    required this.phoneNumber,
    required this.gender,
    this.profilePicture,
    required this.role,
    required this.isEmailVerified,
    required this.isActive,
    required this.accountStatus,
    required this.isDriver,
    this.carDetails,
    required this.rating,
    required this.stats,
    required this.twoFactorEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      universityId: json['universityId'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      gender: json['gender'] ?? 'male',
      profilePicture: json['profilePicture'],
      role: json['role'] ?? 'user',
      isEmailVerified: json['isEmailVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      accountStatus: json['accountStatus'] ?? 'active',
      isDriver: json['isDriver'] ?? false,
      carDetails: json['carDetails'] != null 
          ? CarDetails.fromJson(json['carDetails']) 
          : null,
      rating: Rating.fromJson(json['rating'] ?? {}),
      stats: UserStats.fromJson(json['stats'] ?? {}),
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
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
      'name': name,
      'email': email,
      'universityId': universityId,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'profilePicture': profilePicture,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'accountStatus': accountStatus,
      'isDriver': isDriver,
      'carDetails': carDetails?.toJson(),
      'rating': rating.toJson(),
      'stats': stats.toJson(),
      'twoFactorEnabled': twoFactorEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return 'U';
  }

  User copyWith({
    String? name,
    String? phoneNumber,
    String? profilePicture,
    bool? isDriver,
    CarDetails? carDetails,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      universityId: universityId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role,
      isEmailVerified: isEmailVerified,
      isActive: isActive,
      accountStatus: accountStatus,
      isDriver: isDriver ?? this.isDriver,
      carDetails: carDetails ?? this.carDetails,
      rating: rating,
      stats: stats,
      twoFactorEnabled: twoFactorEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class CarDetails {
  final String model;
  final String color;
  final String licensePlate;
  final int totalSeats;

  CarDetails({
    required this.model,
    required this.color,
    required this.licensePlate,
    required this.totalSeats,
  });

  factory CarDetails.fromJson(Map<String, dynamic> json) {
    return CarDetails(
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      totalSeats: json['totalSeats'] ?? 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'color': color,
      'licensePlate': licensePlate,
      'totalSeats': totalSeats,
    };
  }

  String get displayName => '$model - $color';
}

class Rating {
  final double average;
  final int count;

  Rating({
    required this.average,
    required this.count,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      average: (json['average'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average': average,
      'count': count,
    };
  }
}

class UserStats {
  final int totalRidesAsDriver;
  final int totalRidesAsRider;
  final double moneySaved;

  UserStats({
    required this.totalRidesAsDriver,
    required this.totalRidesAsRider,
    required this.moneySaved,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalRidesAsDriver: json['totalRidesAsDriver'] ?? 0,
      totalRidesAsRider: json['totalRidesAsRider'] ?? 0,
      moneySaved: (json['moneySaved'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRidesAsDriver': totalRidesAsDriver,
      'totalRidesAsRider': totalRidesAsRider,
      'moneySaved': moneySaved,
    };
  }

  int get totalRides => totalRidesAsDriver + totalRidesAsRider;
}