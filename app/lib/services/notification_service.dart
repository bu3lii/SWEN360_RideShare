import '../config/api_config.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? unreadOnly,
  }) async {
    var url = '${ApiConfig.notificationsUrl}?page=$page&limit=$limit';
    if (type != null) url += '&type=$type';
    if (unreadOnly == true) url += '&unreadOnly=true';

    final response = await _api.get(url);

    if (response.success && response.data['data'] != null) {
      return NotificationResponse.fromJson(response.data['data']);
    }

    return NotificationResponse(notifications: [], totalCount: 0, unreadCount: 0);
  }

  Future<int> getUnreadCount() async {
    final response = await _api.get(ApiConfig.unreadCountUrl);

    if (response.success && response.data['data'] != null) {
      return response.data['data']['unreadCount'] ?? 0;
    }

    return 0;
  }

  Future<bool> markAsRead(String notificationId) async {
    final response = await _api.patch(ApiConfig.markNotificationReadUrl(notificationId));
    return response.success;
  }

  Future<bool> markAllAsRead() async {
    final response = await _api.patch(ApiConfig.markAllReadUrl);
    return response.success;
  }

  Future<bool> deleteNotification(String notificationId) async {
    final response = await _api.delete(ApiConfig.notificationUrl(notificationId));
    return response.success;
  }

  Future<bool> clearReadNotifications() async {
    final response = await _api.delete(ApiConfig.clearReadUrl);
    return response.success;
  }
}

class NotificationResponse {
  final List<AppNotification> notifications;
  final int totalCount;
  final int unreadCount;

  NotificationResponse({
    required this.notifications,
    required this.totalCount,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notifications: (json['notifications'] as List?)
          ?.map((n) => AppNotification.fromJson(n))
          .toList() ?? [],
      totalCount: json['totalCount'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final NotificationData? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? NotificationData.fromJson(json['data']) : null,
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  String get iconType {
    switch (type) {
      case 'booking_request':
      case 'booking_confirmed':
      case 'booking_cancelled':
        return 'booking';
      case 'ride_started':
      case 'ride_completed':
      case 'ride_cancelled':
        return 'ride';
      case 'new_message':
        return 'message';
      case 'new_review':
        return 'review';
      default:
        return 'general';
    }
  }
}

class NotificationData {
  final String? rideId;
  final String? bookingId;
  final String? reviewId;
  final String? messageId;
  final String? userId;

  NotificationData({
    this.rideId,
    this.bookingId,
    this.reviewId,
    this.messageId,
    this.userId,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      rideId: json['rideId'],
      bookingId: json['bookingId'],
      reviewId: json['reviewId'],
      messageId: json['messageId'],
      userId: json['userId'],
    );
  }
}