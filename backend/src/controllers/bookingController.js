/**
 * Booking Controller
 * Handles ride booking, cancellation, and management
 */

const { Booking, Ride, User, Notification } = require('../models');
const AppError = require('../utils/AppError');
const asyncHandler = require('../middleware/asyncHandler');
const emailService = require('../services/emailService');
const { sendBookingUpdate, emitToUser } = require('../services/socketService');

/**
 * Create a booking
 * POST /api/v1/bookings
 */
exports.createBooking = asyncHandler(async (req, res, next) => {
  const { rideId, seatsBooked = 1, pickupLocation, specialRequests } = req.body;
  const passenger = req.user;

  // Get ride
  const ride = await Ride.findById(rideId).populate('driver');

  if (!ride) {
    return next(new AppError('Ride not found', 404));
  }

  // Validate ride is available
  if (ride.status !== 'scheduled') {
    return next(new AppError('This ride is no longer available for booking', 400));
  }

  if (ride.departureTime <= new Date()) {
    return next(new AppError('Cannot book a ride that has already departed', 400));
  }

  // Check if user is trying to book their own ride
  if (ride.driver._id.toString() === passenger._id.toString()) {
    return next(new AppError('You cannot book your own ride', 400));
  }

  // Check seat availability
  if (ride.availableSeats < seatsBooked) {
    return next(new AppError(`Only ${ride.availableSeats} seats available`, 400));
  }

  // Check gender preference
  if (ride.genderPreference !== 'any' && ride.genderPreference !== passenger.gender) {
    return next(new AppError(`This ride is only for ${ride.genderPreference} passengers`, 400));
  }

  // Check if user already has a booking for this ride
  const existingBooking = await Booking.hasExistingBooking(rideId, passenger._id);
  if (existingBooking) {
    return next(new AppError('You already have a booking for this ride', 400));
  }

  // Calculate total amount based on ride price per seat
  const totalAmount = (ride.pricePerSeat || 0) * seatsBooked;

  // Generate safe codes for security verification
  const generateSafeCode = () => {
    return Math.floor(1000 + Math.random() * 9000).toString(); // 4-digit code
  };
  const riderSafeCode = generateSafeCode();
  const driverSafeCode = generateSafeCode();

  // Create booking as pending (requires driver acceptance)
  const booking = await Booking.create({
    ride: rideId,
    passenger: passenger._id,
    seatsBooked,
    pickupLocation: pickupLocation || {
      address: ride.startLocation.address,
      coordinates: ride.startLocation.coordinates
    },
    totalAmount,
    specialRequests,
    riderSafeCode,
    driverSafeCode,
    status: 'pending' // Requires driver acceptance
  });

  // Don't decrement seats until booking is confirmed

  // Populate booking data
  await booking.populate([
    { path: 'passenger', select: 'name profilePicture phoneNumber gender' },
    { 
      path: 'ride', 
      populate: { 
        path: 'driver', 
        select: 'name profilePicture phoneNumber carDetails rating' 
      } 
    }
  ]);

  // Create notification for driver
  await Notification.createNotification('booking_request', ride.driver._id, {
    rideId: ride._id,
    bookingId: booking._id,
    passengerName: passenger.name
  });

  // Create notification for passenger (pending status)
  await Notification.createNotification('booking_pending', passenger._id, {
    rideId: ride._id,
    bookingId: booking._id,
    message: 'Your booking request is pending driver approval'
  });

  // Real-time notification to driver
  emitToUser(ride.driver._id.toString(), 'booking:new', {
    booking: {
      _id: booking._id,
      passenger: {
        name: passenger.name,
        profilePicture: passenger.profilePicture
      },
      seatsBooked,
      status: booking.status
    },
    ride: {
      _id: ride._id,
      availableSeats: ride.availableSeats
    }
  });

  // Send pending booking email (not confirmation yet)
  try {
    await emailService.sendBookingConfirmationEmail(passenger, booking, ride, ride.driver);
  } catch (error) {
    console.error('Failed to send booking email:', error.message);
  }

  res.status(201).json({
    success: true,
    data: {
      booking
    }
  });
});

/**
 * Get user's bookings
 * GET /api/v1/bookings
 */
exports.getMyBookings = asyncHandler(async (req, res, next) => {
  const { status, page = 1, limit = 20 } = req.query;

  const bookings = await Booking.findByPassenger(req.user._id, status);

  // Pagination
  const startIndex = (parseInt(page) - 1) * parseInt(limit);
  const paginatedBookings = bookings.slice(startIndex, startIndex + parseInt(limit));

  res.status(200).json({
    success: true,
    count: paginatedBookings.length,
    total: bookings.length,
    page: parseInt(page),
    pages: Math.ceil(bookings.length / parseInt(limit)),
    data: {
      bookings: paginatedBookings
    }
  });
});

/**
 * Get single booking
 * GET /api/v1/bookings/:id
 */
exports.getBooking = asyncHandler(async (req, res, next) => {
  const booking = await Booking.findById(req.params.id)
    .populate('passenger', 'name profilePicture phoneNumber gender rating')
    .populate({
      path: 'ride',
      populate: {
        path: 'driver',
        select: 'name profilePicture phoneNumber carDetails rating'
      }
    });

  if (!booking) {
    return next(new AppError('Booking not found', 404));
  }

  // Check authorization
  const isPassenger = booking.passenger._id.toString() === req.user._id.toString();
  const isDriver = booking.ride.driver._id.toString() === req.user._id.toString();

  if (!isPassenger && !isDriver) {
    return next(new AppError('You are not authorized to view this booking', 403));
  }

  res.status(200).json({
    success: true,
    data: {
      booking
    }
  });
});

/**
 * Cancel booking
 * PATCH /api/v1/bookings/:id/cancel
 */
exports.cancelBooking = asyncHandler(async (req, res, next) => {
  const booking = await Booking.findById(req.params.id)
    .populate('passenger')
    .populate({
      path: 'ride',
      populate: { path: 'driver' }
    });

  if (!booking) {
    return next(new AppError('Booking not found', 404));
  }

  // Check authorization
  const isPassenger = booking.passenger._id.toString() === req.user._id.toString();
  const isDriver = booking.ride.driver._id.toString() === req.user._id.toString();

  if (!isPassenger && !isDriver) {
    return next(new AppError('You are not authorized to cancel this booking', 403));
  }

  // Check if booking can be cancelled
  if (!['pending', 'confirmed'].includes(booking.status)) {
    return next(new AppError('This booking cannot be cancelled', 400));
  }

  // Check cancellation timing (e.g., at least 1 hour before departure)
  const ride = booking.ride;
  const hoursUntilDeparture = (new Date(ride.departureTime) - new Date()) / (1000 * 60 * 60);
  
  if (isPassenger && hoursUntilDeparture < 1) {
    return next(new AppError('Cannot cancel less than 1 hour before departure', 400));
  }

  const { reason } = req.body;
  const cancelledBy = isPassenger ? 'passenger' : 'driver';

  // Store original status before cancellation
  const wasConfirmed = booking.status === 'confirmed';

  // Cancel booking
  await booking.cancel(reason || 'No reason provided', cancelledBy);

  // Only restore seats if booking was confirmed (seats were actually decremented)
  if (wasConfirmed) {
    await ride.incrementSeats(booking.seatsBooked);
  }

  // Notify the other party
  const recipientId = isPassenger ? ride.driver._id : booking.passenger._id;
  await Notification.createNotification('booking_cancelled', recipientId, {
    rideId: ride._id,
    bookingId: booking._id,
    cancelledBy
  });

  // Real-time notification
  sendBookingUpdate(booking, 'booking:cancelled');

  res.status(200).json({
    success: true,
    message: 'Booking cancelled successfully',
    data: {
      booking
    }
  });
});

/**
 * Get bookings for a ride
 * GET /api/v1/bookings/ride/:rideId
 * Drivers see full booking details, passengers see limited info (for map display)
 */
exports.getRideBookings = asyncHandler(async (req, res, next) => {
  const ride = await Ride.findById(req.params.rideId);

  if (!ride) {
    return next(new AppError('Ride not found', 404));
  }

  const isDriver = ride.driver.toString() === req.user._id.toString();
  const bookings = await Booking.findByRide(req.params.rideId);

  // If passenger, only return pickup locations (for map display)
  // If driver, return full booking details
  const bookingData = isDriver 
    ? bookings 
    : bookings.map(booking => ({
        _id: booking._id,
        pickupLocation: booking.pickupLocation,
        seatsBooked: booking.seatsBooked,
        status: booking.status,
        // Don't expose passenger details, safe codes, etc. to other passengers
      }));

  res.status(200).json({
    success: true,
    count: bookingData.length,
    data: {
      bookings: bookingData
    }
  });
});

/**
 * Mark passenger as picked up (with code verification)
 * PATCH /api/v1/bookings/:id/pickup
 */
exports.markPickedUp = asyncHandler(async (req, res, next) => {
  const { riderCode } = req.body; // Driver enters rider's code

  const booking = await Booking.findById(req.params.id).populate('ride');

  if (!booking) {
    return next(new AppError('Booking not found', 404));
  }

  // Check if user is the driver
  if (booking.ride.driver.toString() !== req.user._id.toString()) {
    return next(new AppError('Only the driver can mark passengers as picked up', 403));
  }

  if (booking.status !== 'confirmed') {
    return next(new AppError('Booking must be confirmed', 400));
  }

  // Verify rider code
  if (!riderCode) {
    return next(new AppError('Rider code is required', 400));
  }

  if (booking.riderSafeCode !== riderCode) {
    return next(new AppError('Invalid rider code. Please verify the code with the passenger.', 400));
  }

  await booking.markPickedUp();

  // Notify passenger via socket (notification type doesn't exist, so we'll just use socket)
  emitToUser(booking.passenger.toString(), 'booking:picked_up', {
    bookingId: booking._id,
    rideId: booking.ride._id
  });

  res.status(200).json({
    success: true,
    message: 'Passenger marked as picked up',
    data: { booking }
  });
});

/**
 * Accept booking (driver only)
 * PATCH /api/v1/bookings/:id/accept
 */
exports.acceptBooking = asyncHandler(async (req, res, next) => {
  const booking = await Booking.findById(req.params.id)
    .populate('passenger')
    .populate({
      path: 'ride',
      populate: { path: 'driver' }
    });

  if (!booking) {
    return next(new AppError('Booking not found', 404));
  }

  // Check if user is the driver
  if (booking.ride.driver._id.toString() !== req.user._id.toString()) {
    return next(new AppError('Only the driver can accept bookings', 403));
  }

  if (booking.status !== 'pending') {
    return next(new AppError('Only pending bookings can be accepted', 400));
  }

  // Check seat availability
  if (booking.ride.availableSeats < booking.seatsBooked) {
    return next(new AppError('Not enough seats available', 400));
  }

  // Confirm booking
  await booking.confirm('driver');

  // Update ride seat count
  await booking.ride.decrementSeats(booking.seatsBooked);

  // Create notification for passenger
  await Notification.createNotification('booking_confirmed', booking.passenger._id, {
    rideId: booking.ride._id,
    bookingId: booking._id,
    pickupTime: booking.ride.departureTime
  });

  // Real-time notification
  sendBookingUpdate(booking, 'booking:accepted');
  emitToUser(booking.passenger._id.toString(), 'booking:confirmed', {
    bookingId: booking._id,
    rideId: booking.ride._id
  });

  res.status(200).json({
    success: true,
    message: 'Booking accepted successfully',
    data: { booking }
  });
});

/**
 * Reject booking (driver only)
 * PATCH /api/v1/bookings/:id/reject
 */
exports.rejectBooking = asyncHandler(async (req, res, next) => {
  const booking = await Booking.findById(req.params.id)
    .populate('passenger')
    .populate({
      path: 'ride',
      populate: { path: 'driver' }
    });

  if (!booking) {
    return next(new AppError('Booking not found', 404));
  }

  // Check if user is the driver
  if (booking.ride.driver._id.toString() !== req.user._id.toString()) {
    return next(new AppError('Only the driver can reject bookings', 403));
  }

  if (booking.status !== 'pending') {
    return next(new AppError('Only pending bookings can be rejected', 400));
  }

  const { reason } = req.body;

  // Cancel booking (rejected)
  await booking.cancel(reason || 'Booking rejected by driver', 'driver');

  // Create notification for passenger
  await Notification.createNotification('booking_cancelled', booking.passenger._id, {
    rideId: booking.ride._id,
    bookingId: booking._id,
    cancelledBy: 'driver',
    message: reason || 'Your booking request was rejected by the driver'
  });

  // Real-time notification
  sendBookingUpdate(booking, 'booking:rejected');
  emitToUser(booking.passenger._id.toString(), 'booking:rejected', {
    bookingId: booking._id,
    rideId: booking.ride._id,
    reason: reason || 'Booking rejected by driver'
  });

  res.status(200).json({
    success: true,
    message: 'Booking rejected successfully',
    data: { booking }
  });
});

/**
 * Mark passenger as no-show
 * PATCH /api/v1/bookings/:id/no-show
 */
/**
 * Mark booking as paid (in person)
 * PATCH /api/v1/bookings/:id/mark-paid
 */
exports.markPaid = asyncHandler(async (req, res, next) => {
  const booking = await Booking.findById(req.params.id).populate('ride');

  if (!booking) {
    return next(new AppError('Booking not found', 404));
  }

  // Check if user is the driver
  if (booking.ride.driver.toString() !== req.user._id.toString()) {
    return next(new AppError('Only the driver can mark bookings as paid', 403));
  }

  // Only allow marking as paid if booking is completed
  if (booking.status !== 'completed') {
    return next(new AppError('Booking must be completed before marking as paid', 400));
  }

  // Mark as paid
  booking.paymentStatus = 'paid';
  booking.paymentMethod = 'cash';
  await booking.save();

  // Notify passenger
  await Notification.createNotification('payment_received', booking.passenger._id, {
    bookingId: booking._id,
    rideId: booking.ride._id,
    amount: booking.totalAmount,
  });

  emitToUser(booking.passenger.toString(), 'booking:paid', {
    bookingId: booking._id,
    rideId: booking.ride._id,
  });

  res.status(200).json({
    success: true,
    message: 'Booking marked as paid',
    data: { booking }
  });
});

exports.markNoShow = asyncHandler(async (req, res, next) => {
  const booking = await Booking.findById(req.params.id).populate('ride');

  if (!booking) {
    return next(new AppError('Booking not found', 404));
  }

  // Check if user is the driver
  if (booking.ride.driver.toString() !== req.user._id.toString()) {
    return next(new AppError('Only the driver can mark passengers as no-show', 403));
  }

  if (booking.status !== 'confirmed') {
    return next(new AppError('Booking must be confirmed', 400));
  }

  await booking.markNoShow();

  // Notify passenger
  await Notification.createNotification('booking_cancelled', booking.passenger, {
    bookingId: booking._id,
    message: 'You were marked as a no-show for your ride'
  });

  res.status(200).json({
    success: true,
    message: 'Passenger marked as no-show',
    data: { booking }
  });
});

/**
 * Get booking statistics
 * GET /api/v1/bookings/stats
 */
exports.getBookingStats = asyncHandler(async (req, res, next) => {
  const userId = req.user._id;

  const [totalBookings, completedBookings, cancelledBookings, totalSpent] = await Promise.all([
    Booking.countDocuments({ passenger: userId }),
    Booking.countDocuments({ passenger: userId, status: 'completed' }),
    Booking.countDocuments({ passenger: userId, status: 'cancelled' }),
    Booking.getTotalSpent(userId)
  ]);

  res.status(200).json({
    success: true,
    data: {
      stats: {
        totalBookings,
        completedBookings,
        cancelledBookings,
        completionRate: totalBookings > 0 
          ? ((completedBookings / totalBookings) * 100).toFixed(1) 
          : 0,
        totalSpent
      }
    }
  });
});
