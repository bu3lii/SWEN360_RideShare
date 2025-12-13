import '../config/api_config.dart';
import '../models/models.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _api = ApiService();

  Future<Booking?> createBooking({
    required String rideId,
    required int seatsBooked,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    String? specialRequests,
    String paymentMethod = 'cash',
  }) async {
    final body = <String, dynamic>{
      'rideId': rideId,
      'seatsBooked': seatsBooked,
      'paymentMethod': paymentMethod,
    };

    if (pickupLat != null && pickupLng != null && pickupAddress != null) {
      body['pickupLocation'] = {
        'address': pickupAddress,
        'coordinates': {
          'lat': pickupLat,
          'lng': pickupLng,
        },
      };
    }

    if (specialRequests != null) body['specialRequests'] = specialRequests;

    final response = await _api.post(ApiConfig.bookingsUrl, body: body);

    if (response.success && response.data['data'] != null) {
      return Booking.fromJson(response.data['data']['booking']);
    }

    return null;
  }

  Future<List<Booking>> getMyBookings({String? status}) async {
    var url = ApiConfig.bookingsUrl;
    if (status != null) url += '?status=$status';

    final response = await _api.get(url);

    if (response.success && response.data['data'] != null) {
      final bookings = response.data['data']['bookings'] as List;
      return bookings.map((b) => Booking.fromJson(b)).toList();
    }

    return [];
  }

  Future<Booking?> getBooking(String id) async {
    final response = await _api.get(ApiConfig.bookingUrl(id));

    if (response.success && response.data['data'] != null) {
      return Booking.fromJson(response.data['data']['booking']);
    }

    return null;
  }

  Future<BookingStats?> getBookingStats() async {
    final response = await _api.get(ApiConfig.bookingStatsUrl);

    if (response.success && response.data['data'] != null) {
      return BookingStats.fromJson(response.data['data']);
    }

    return null;
  }

  Future<List<Booking>> getRideBookings(String rideId) async {
    final response = await _api.get(ApiConfig.rideBookingsUrl(rideId));

    if (response.success && response.data['data'] != null) {
      final bookings = response.data['data']['bookings'] as List;
      return bookings.map((b) => Booking.fromJson(b)).toList();
    }

    return [];
  }

  Future<bool> cancelBooking(String id, {String? reason}) async {
    final response = await _api.patch(
      ApiConfig.cancelBookingUrl(id),
      body: reason != null ? {'reason': reason} : null,
    );
    return response.success;
  }

  Future<bool> markPickedUp(String id, {required String riderCode}) async {
    final response = await _api.patch(
      ApiConfig.pickupBookingUrl(id),
      body: {'riderCode': riderCode},
    );
    return response.success;
  }

  Future<bool> markPaid(String id) async {
    final response = await _api.patch(ApiConfig.markPaidBookingUrl(id));
    return response.success;
  }

  Future<bool> markNoShow(String id) async {
    final response = await _api.patch(ApiConfig.noShowBookingUrl(id));
    return response.success;
  }

  Future<bool> acceptBooking(String id) async {
    final response = await _api.patch(ApiConfig.acceptBookingUrl(id));
    return response.success;
  }

  Future<bool> rejectBooking(String id, {String? reason}) async {
    final response = await _api.patch(
      ApiConfig.rejectBookingUrl(id),
      body: reason != null ? {'reason': reason} : null,
    );
    return response.success;
  }
}