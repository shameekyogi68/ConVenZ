import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/booking.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/welcome/welcome_carousel.dart';
import '../../screens/user_setup/user_setup_carousel.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/booking_flow/vendor_details_screen.dart';
import '../../screens/booking_flow/booking_otp_screen.dart';
import '../../screens/booking_flow/feedback_screen.dart';
import '../../screens/booking_flow/completion_screen.dart';
import '../../screens/home/booking/booking_confirmation_screen.dart';
import '../../screens/home/booking/vendor_search_screen.dart';
import '../../screens/home/booking/vendor_searching_screen.dart';
import '../../screens/home/booking/vendor_found_screen.dart';
import '../../screens/home/booking/vendor_not_found_screen.dart';
import '../../screens/home/booking/service_details_screen.dart';
import '../../screens/home/booking/map_screen.dart';
import '../../screens/blocked_user_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // ── Auth & Onboarding ──
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcomeCarousel',
        builder: (context, state) => const WelcomeCarousel(),
      ),
      GoRoute(
        path: '/userSetupCarousel',
        builder: (context, state) => const UserSetupCarousel(),
      ),
      GoRoute(
        path: '/blocked',
        builder: (context, state) {
          final reason = state.extra as String?;
          return BlockedUserScreen(reason: reason);
        },
      ),

      // ── Main App ──
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ── Booking Flow (Post-Match) ──
      GoRoute(
        path: '/vendorDetails',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return VendorDetailsScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/bookingOtp',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return BookingOtpScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return FeedbackScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/completion',
        builder: (context, state) => const CompletionScreen(),
      ),

      // ── Booking Flow (Pre-Match: Map / Service Details / Vendor Search) ──
      GoRoute(
        path: '/map',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return MapScreen(
            selectedService: args['selectedService'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/serviceDetails',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ServiceDetailsScreen(
            address: args['address'] as String,
            selectedService: args['selectedService'] as String?,
            latitude: args['latitude'] as double?,
            longitude: args['longitude'] as double?,
          );
        },
      ),
      GoRoute(
        path: '/bookingConfirmation',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return BookingConfirmationScreen(
            bookingId: args['bookingId'] as String,
            serviceName: args['serviceName'] as String,
            selectedDate: args['selectedDate'] as String,
            selectedTime: args['selectedTime'] as String,
            address: args['address'] as String,
            jobDescription: args['jobDescription'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/vendorSearching',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return VendorSearchingScreen(
            bookingId: args['bookingId'] as String,
            serviceName: args['serviceName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/vendorSearch',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return VendorSearchScreen(
            bookingId: args['bookingId'] as String,
            serviceName: args['serviceName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/vendorFound',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return VendorFoundScreen(
            bookingId: args['bookingId'] as String,
            vendorName: args['vendorName'] as String,
            vendorPhone: args['vendorPhone'] as String,
            vendorAddress: args['vendorAddress'] as String,
            service: args['service'] as String,
            date: args['date'] as String,
            time: args['time'] as String,
          );
        },
      ),
      GoRoute(
        path: '/vendorNotFound',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return VendorNotFoundScreen(
            bookingId: args['bookingId'] as String,
            serviceName: args['serviceName'] as String,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Route: ${state.uri.toString()}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
