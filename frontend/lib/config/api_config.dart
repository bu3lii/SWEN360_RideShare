class ApiConfig {
  // Base URL for the backend API
  // static const String baseUrl = 'http://localhost:3000';
  static const String baseUrl = 'http://10.0.2.2:3000';
  //static const String baseUrl = 'https://sean-amy-obtain-asset.trycloudflare.com:3000';
  static const String apiVersion = 'v1';
  
  // Full API base URL
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';
  
  // Auth endpoints
  static String get registerUrl => '$apiBaseUrl/auth/register';
  static String get loginUrl => '$apiBaseUrl/auth/login';
  static String get logoutUrl => '$apiBaseUrl/auth/logout';
  static String get forgotPasswordUrl => '$apiBaseUrl/auth/forgot-password';
  static String get meUrl => '$apiBaseUrl/auth/me';
  static String get updatePasswordUrl => '$apiBaseUrl/auth/update-password';
  static String get resendVerificationUrl => '$apiBaseUrl/auth/resend-verification';
  static String verifyEmailUrl(String token) => '$apiBaseUrl/auth/verify-email/$token';
  static String resetPasswordUrl(String token) => '$apiBaseUrl/auth/reset-password/$token';
  
  // 2FA endpoints
  static String get setup2faUrl => '$apiBaseUrl/auth/2fa/setup';
  static String get enable2faUrl => '$apiBaseUrl/auth/2fa/enable';
  static String get disable2faUrl => '$apiBaseUrl/auth/2fa/disable';
  
  // User endpoints
  static String get dashboardUrl => '$apiBaseUrl/users/dashboard';
  static String get profileUrl => '$apiBaseUrl/users/profile';
  static String get becomeDriverUrl => '$apiBaseUrl/users/become-driver';
  static String get carDetailsUrl => '$apiBaseUrl/users/car-details';
  static String get rideHistoryUrl => '$apiBaseUrl/users/ride-history';
  static String get deactivateAccountUrl => '$apiBaseUrl/users/account';
  static String get driversUrl => '$apiBaseUrl/users/drivers';
  static String userUrl(String id) => '$apiBaseUrl/users/$id';
  
  // Ride endpoints
  static String get ridesUrl => '$apiBaseUrl/rides';
  static String get searchRidesUrl => '$apiBaseUrl/rides/search';
  static String get myRidesUrl => '$apiBaseUrl/rides/my-rides';
  static String get routeUrl => '$apiBaseUrl/rides/route';
  static String rideUrl(String id) => '$apiBaseUrl/rides/$id';
  static String startRideUrl(String id) => '$apiBaseUrl/rides/$id/start';
  static String completeRideUrl(String id) => '$apiBaseUrl/rides/$id/complete';
  
  // Booking endpoints
  static String get bookingsUrl => '$apiBaseUrl/bookings';
  static String get bookingStatsUrl => '$apiBaseUrl/bookings/stats';
  static String bookingUrl(String id) => '$apiBaseUrl/bookings/$id';
  static String cancelBookingUrl(String id) => '$apiBaseUrl/bookings/$id/cancel';
  static String acceptBookingUrl(String id) => '$apiBaseUrl/bookings/$id/accept';
  static String rejectBookingUrl(String id) => '$apiBaseUrl/bookings/$id/reject';
  static String pickupBookingUrl(String id) => '$apiBaseUrl/bookings/$id/pickup';
  static String markPaidBookingUrl(String id) => '$apiBaseUrl/bookings/$id/mark-paid';
  static String noShowBookingUrl(String id) => '$apiBaseUrl/bookings/$id/no-show';
  static String rideBookingsUrl(String rideId) => '$apiBaseUrl/bookings/ride/$rideId';
  
  // Review endpoints
  static String get reviewsUrl => '$apiBaseUrl/reviews';
  static String get myReviewsUrl => '$apiBaseUrl/reviews/me';
  static String get reviewStatsUrl => '$apiBaseUrl/reviews/stats';
  static String reviewUrl(String id) => '$apiBaseUrl/reviews/$id';
  static String userReviewsUrl(String userId) => '$apiBaseUrl/reviews/user/$userId';
  static String respondReviewUrl(String id) => '$apiBaseUrl/reviews/$id/respond';
  static String reportReviewUrl(String id) => '$apiBaseUrl/reviews/$id/report';
  
  // Message endpoints
  static String get messagesUrl => '$apiBaseUrl/messages';
  static String get conversationsUrl => '$apiBaseUrl/messages/conversations';
  static String get unreadMessagesUrl => '$apiBaseUrl/messages/unread';
  static String get moderationStatusUrl => '$apiBaseUrl/messages/moderation-status';
  static String conversationUrl(String id) => '$apiBaseUrl/messages/conversations/$id';
  static String markReadUrl(String id) => '$apiBaseUrl/messages/conversations/$id/read';
  static String blockConversationUrl(String id) => '$apiBaseUrl/messages/conversations/$id/block';
  
  // Notification endpoints
  static String get notificationsUrl => '$apiBaseUrl/notifications';
  static String get unreadCountUrl => '$apiBaseUrl/notifications/unread-count';
  static String get markAllReadUrl => '$apiBaseUrl/notifications/read-all';
  static String get clearReadUrl => '$apiBaseUrl/notifications/clear-read';
  static String notificationUrl(String id) => '$apiBaseUrl/notifications/$id';
  static String markNotificationReadUrl(String id) => '$apiBaseUrl/notifications/$id/read';
  
  // Location endpoints
  static String get geocodeUrl => '$apiBaseUrl/location/geocode';
  static String get reverseGeocodeUrl => '$apiBaseUrl/location/reverse-geocode';
  static String get searchPlacesUrl => '$apiBaseUrl/location/search';
  static String get calculateRouteUrl => '$apiBaseUrl/location/route';
  static String get multiRouteUrl => '$apiBaseUrl/location/multi-route';
  static String get distanceMatrixUrl => '$apiBaseUrl/location/distance-matrix';
  static String get snapToRoadUrl => '$apiBaseUrl/location/snap-to-road';
  static String get etaUrl => '$apiBaseUrl/location/eta';
  static String get validateLocationUrl => '$apiBaseUrl/location/validate';
  static String get serviceAreaUrl => '$apiBaseUrl/location/service-area';
  
  // Socket.IO URL
  static String get socketUrl => baseUrl;
  
  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}