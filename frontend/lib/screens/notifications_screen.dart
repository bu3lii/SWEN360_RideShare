import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../config/theme.dart';
import '../services/notification_service.dart';
import '../services/ride_service.dart';
import '../services/booking_service.dart';
import '../widgets/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final response = await _notificationService.getNotifications();

    if (mounted) {
      setState(() {
        _notifications = response.notifications;
        _unreadCount = response.unreadCount;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success && mounted) {
      setState(() {
        for (var n in _notifications) {
          n = AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        _unreadCount = 0;
      });
      _loadNotifications();
    }
  }

  Future<void> _clearReadNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Notifications'),
        content: const Text('Are you sure you want to clear all read notifications?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _notificationService.clearReadNotifications();
      if (success && mounted) {
        _loadNotifications();
      }
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final success = await _notificationService.deleteNotification(notification.id);
    if (success && mounted) {
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    }
  }

  void _handleNotificationTap(AppNotification notification) async {
    // Mark as read
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }

    if (!mounted) return;

    // Navigate based on notification type
    final data = notification.data;
    final type = notification.type;
    
    // Import services
    final rideService = RideService();
    final bookingService = BookingService();
    
    // Route to appropriate screen based on notification type
    if (type == 'booking_request') {
      // For booking requests, navigate to the specific ride (driver view)
      if (data?.rideId != null) {
        final ride = await rideService.getRide(data!.rideId!);
        if (ride != null && mounted) {
          Navigator.pushNamed(
            context,
            '/driver-ride',
            arguments: ride,
          );
        } else {
          Navigator.pushNamed(context, '/my-rides');
        }
      } else {
        Navigator.pushNamed(context, '/my-rides');
      }
    } else if (type == 'booking_confirmed' || type == 'booking_cancelled') {
      // For booking confirmations/cancellations, navigate to booking details
      if (data?.bookingId != null) {
        final booking = await bookingService.getBooking(data!.bookingId!);
        if (booking != null && mounted) {
          Navigator.pushNamed(
            context,
            '/booking-details',
            arguments: booking,
          );
        } else {
          Navigator.pushNamed(context, '/my-bookings');
        }
      } else {
        Navigator.pushNamed(context, '/my-bookings');
      }
    } else if (type == 'ride_started' || type == 'ride_completed' || 
               type == 'ride_updated' || type == 'ride_cancelled') {
      // For ride updates, navigate to the specific ride
      if (data?.rideId != null) {
        final ride = await rideService.getRide(data!.rideId!);
        if (ride != null && mounted) {
          Navigator.pushNamed(
            context,
            '/driver-ride',
            arguments: ride,
          );
        } else {
          Navigator.pushNamed(context, '/my-rides');
        }
      } else {
        Navigator.pushNamed(context, '/my-rides');
      }
    } else if (type == 'new_message') {
      Navigator.pushNamed(context, '/messages');
    } else if (type == 'new_review' || type == 'review_response') {
      Navigator.pushNamed(context, '/reviews');
    } else if (data?.rideId != null) {
      // Default: try to navigate to specific ride
      final ride = await rideService.getRide(data!.rideId!);
      if (ride != null && mounted) {
        Navigator.pushNamed(
          context,
          '/driver-ride',
          arguments: ride,
        );
      } else {
        Navigator.pushNamed(context, '/my-rides');
      }
    } else if (data?.bookingId != null) {
      // Default: try to navigate to specific booking
      final booking = await bookingService.getBooking(data!.bookingId!);
      if (booking != null && mounted) {
        Navigator.pushNamed(
          context,
          '/booking-details',
          arguments: booking,
        );
      } else {
        Navigator.pushNamed(context, '/my-bookings');
      }
    }

    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearReadNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Iconsax.trash, size: 20),
                    SizedBox(width: 12),
                    Text('Clear read'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: LoadingIndicator())
            : _notifications.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                        onDelete: () => _deleteNotification(notification),
                      ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.1, end: 0);
                    },
                  ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  IconData get _icon {
    switch (notification.iconType) {
      case 'booking':
        return Iconsax.receipt_2;
      case 'ride':
        return Iconsax.car;
      case 'message':
        return Iconsax.message;
      case 'review':
        return Iconsax.star;
      default:
        return Iconsax.notification;
    }
  }

  Color get _iconColor {
    switch (notification.iconType) {
      case 'booking':
        return AppColors.primary;
      case 'ride':
        return AppColors.secondary;
      case 'message':
        return AppColors.success;
      case 'review':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(
          Iconsax.trash,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead
              ? null
              : Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _icon,
              color: _iconColor,
              size: 22,
            ),
          ),
          title: Text(
            notification.title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                timeago.format(notification.createdAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.notification,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}