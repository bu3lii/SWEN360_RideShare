import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/screens.dart';
import 'models/models.dart';
import 'services/message_service.dart' show Conversation;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const UniRideApp());
}

class UniRideApp extends StatelessWidget {
  const UniRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'UniRide',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case '/':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      
      case '/sign-in':
      case '/signin':  // Support both variants
        return MaterialPageRoute(
          builder: (_) => const SignInScreen(),
        );
      
      case '/sign-up':
      case '/signup':  // Support both variants
        return MaterialPageRoute(
          builder: (_) => const SignUpScreen(),
        );
      
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
        );
      
      case '/reset-password':
        final token = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: token),
        );
      
      case '/email-verification':
        return MaterialPageRoute(
          builder: (_) => const EmailVerificationScreen(),
        );
      
      // Main Routes
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        );
      
      case '/post-ride':
        return MaterialPageRoute(
          builder: (_) => const PostRideScreen(),
        );
      
      case '/available-rides':
        return MaterialPageRoute(
          builder: (_) => const AvailableRidesScreen(),
        );
      
      case '/booking-confirmation':
        final ride = settings.arguments as Ride;
        return MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(ride: ride),
        );
      
      // Profile & Settings Routes
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );
      
      case '/edit-profile':
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        );
      
      case '/change-password':
        return MaterialPageRoute(
          builder: (_) => const ChangePasswordScreen(),
        );
      
      case '/two-factor':
        return MaterialPageRoute(
          builder: (_) => const TwoFactorScreen(),
        );
      
      case '/become-driver':
        return MaterialPageRoute(
          builder: (_) => const BecomeDriverScreen(),
        );
      
      case '/user-profile':
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: userId),
        );
      
      // Rides & Bookings Routes
      case '/my-rides':
        return MaterialPageRoute(
          builder: (_) => const MyRidesScreen(),
        );
      
      case '/driver-ride':
        final ride = settings.arguments as Ride;
        return MaterialPageRoute(
          builder: (_) => DriverRideScreen(ride: ride),
        );
      
      case '/my-bookings':
        return MaterialPageRoute(
          builder: (_) => const MyBookingsScreen(),
        );
      
      case '/booking-details':
        final booking = settings.arguments as Booking;
        return MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(booking: booking),
        );
      
      case '/payment':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PaymentScreen(
            booking: args['booking'] as Booking,
            isDriver: args['isDriver'] as bool? ?? false,
          ),
        );
      
      case '/safe-code':
        final booking = settings.arguments as Booking;
        return MaterialPageRoute(
          builder: (_) => SafeCodeScreen(booking: booking),
        );
      
      case '/active-ride':
        final booking = settings.arguments as Booking;
        return MaterialPageRoute(
          builder: (_) => ActiveRideScreen(booking: booking),
        );
      
      case '/pickup-confirmation':
        final booking = settings.arguments as Booking;
        return MaterialPageRoute<bool>(
          builder: (_) => PickupConfirmationScreen(booking: booking),
        );
      
      case '/ride-completion':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => RideCompletionScreen(
            ride: args['ride'] as Ride,
            totalEarnings: args['totalEarnings'] as double,
            bookings: args['bookings'] as List<Booking>,
          ),
        );
      
      case '/ride-history':
        return MaterialPageRoute(
          builder: (_) => const RideHistoryScreen(),
        );
      
      // Communication Routes
      case '/messages':
        return MaterialPageRoute(
          builder: (_) => const MessagesScreen(),
        );
      
      case '/chat':
        final conversation = settings.arguments as Conversation;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
        );
      
      case '/notifications':
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        );
      
      // Reviews Routes
      case '/reviews':
        return MaterialPageRoute(
          builder: (_) => const ReviewsScreen(),
        );
      
      case '/create-review':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CreateReviewScreen(
            rideId: args['rideId'],
            bookingId: args['bookingId'],
            revieweeId: args['revieweeId'],
            revieweeName: args['revieweeName'],
          ),
        );
      
      // Map Routes
      case '/live-map':
        final ride = settings.arguments as Ride?;
        return MaterialPageRoute(
          builder: (_) => LiveMapScreen(selectedRide: ride),
        );
      
      // Safety Routes
      case '/safety-center':
        return MaterialPageRoute(
          builder: (_) => const SafetyCenterScreen(),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => const _NotFoundScreen(),
        );
    }
  }
}

// 404 Not Found screen
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '404',
              style: AppTextStyles.h1.copyWith(
                fontSize: 72,
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Page Not Found',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => false,
                );
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
