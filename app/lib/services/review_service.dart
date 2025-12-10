import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class ReviewService {
  final ApiService _api = ApiService();

  Future<Review?> createReview({
    required String rideId,
    required String bookingId,
    required String revieweeId,
    required int rating,
    String? comment,
    List<String>? tags,
  }) async {
    final body = <String, dynamic>{
      'rideId': rideId,
      'bookingId': bookingId,
      'revieweeId': revieweeId,
      'rating': rating,
    };
    if (comment != null) body['comment'] = comment;
    if (tags != null) body['tags'] = tags;

    final response = await _api.post(ApiConfig.reviewsUrl, body: body);

    if (response.success && response.data['data'] != null) {
      return Review.fromJson(response.data['data']['review']);
    }

    return null;
  }

  Future<List<Review>> getMyReviews({String type = 'received'}) async {
    try {
      final response = await _api.get('${ApiConfig.myReviewsUrl}?type=$type');

      if (response.success && response.data['data'] != null) {
        final reviews = response.data['data']['reviews'] as List;
        return reviews.map((r) {
          try {
            return Review.fromJson(r);
          } catch (e) {
            debugPrint('Error parsing review: $e');
            return null;
          }
        }).whereType<Review>().toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  Future<List<Review>> getUserReviews(String userId) async {
    final response = await _api.get(ApiConfig.userReviewsUrl(userId));

    if (response.success && response.data['data'] != null) {
      final reviews = response.data['data']['reviews'] as List;
      return reviews.map((r) => Review.fromJson(r)).toList();
    }

    return [];
  }

  Future<ReviewStats?> getReviewStats() async {
    final response = await _api.get(ApiConfig.reviewStatsUrl);

    if (response.success && response.data['data'] != null) {
      // Backend responds with { data: { stats: { avgRating, totalReviews, distribution } } }
      final stats = response.data['data']['stats'];
      if (stats != null) {
        return ReviewStats.fromJson(stats);
      }
    }

    return null;
  }

  Future<bool> respondToReview(String reviewId, String response) async {
    final result = await _api.post(
      ApiConfig.respondReviewUrl(reviewId),
      body: {'response': response},
    );
    return result.success;
  }

  Future<bool> reportReview(String reviewId, String reason) async {
    final response = await _api.post(
      ApiConfig.reportReviewUrl(reviewId),
      body: {'reason': reason},
    );
    return response.success;
  }
}

class Review {
  final String id;
  final ReviewUser? reviewer;
  final ReviewUser? reviewee;
  final String? rideId;
  final String? bookingId;
  final int rating;
  final String? comment;
  final List<String> tags;
  final String? response;
  final DateTime? respondedAt;
  final bool isHidden;
  final DateTime createdAt;

  Review({
    required this.id,
    this.reviewer,
    this.reviewee,
    this.rideId,
    this.bookingId,
    required this.rating,
    this.comment,
    required this.tags,
    this.response,
    this.respondedAt,
    required this.isHidden,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Parse response object - backend returns { text: string, respondedAt: Date }
    String? responseText;
    DateTime? responseDate;
    if (json['response'] != null) {
      if (json['response'] is String) {
        responseText = json['response'] as String;
      } else if (json['response'] is Map && json['response']['text'] != null) {
        responseText = json['response']['text'] as String;
        if (json['response']['respondedAt'] != null) {
          try {
            responseDate = DateTime.parse(json['response']['respondedAt']);
          } catch (e) {
            // Ignore parse errors
          }
        }
      }
    }

    return Review(
      id: json['_id'] ?? '',
      reviewer: json['reviewer'] != null && json['reviewer'] is Map
          ? ReviewUser.fromJson(json['reviewer'])
          : null,
      reviewee: json['reviewee'] != null && json['reviewee'] is Map
          ? ReviewUser.fromJson(json['reviewee'])
          : null,
      rideId: json['ride'] is String ? json['ride'] : json['ride']?['_id'],
      bookingId: json['booking'] is String ? json['booking'] : json['booking']?['_id'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      response: responseText,
      respondedAt: responseDate,
      isHidden: json['isVisible'] == false || json['isHidden'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class ReviewUser {
  final String id;
  final String name;
  final String? profilePicture;

  ReviewUser({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      profilePicture: json['profilePicture'],
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }
}

class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final List<String> topTags;

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.topTags,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    final distribution = <int, int>{};
    // Backend returns the distribution under `distribution` with numeric keys as strings
    if (json['distribution'] != null) {
      (json['distribution'] as Map).forEach((key, value) {
        distribution[int.parse(key.toString())] = value as int;
      });
    }

    return ReviewStats(
      // Accept both the expected frontend key and the backend key
      averageRating: (json['averageRating'] ?? json['avgRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: distribution,
      topTags: (json['topTags'] as List?)?.map((t) => t.toString()).toList() ?? [],
    );
  }
}