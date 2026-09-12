import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/providers/auth_providers.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/barber/screens/barber_screens.dart';
import '../features/booking/screens/booking_flow_screen.dart';
import '../features/customer/screens/customer_bookings_screen.dart';
import '../features/customer/screens/customer_home_screen.dart';
import '../features/customer/screens/customer_shell.dart';
import '../features/customer/screens/explore_screen.dart';
import '../features/customer/screens/favorites_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/owner/screens/owner_screens.dart';
import '../features/profile/screens/profile_screens.dart';
import '../features/qr/screens/qr_screens.dart';
import '../features/salon/screens/salon_details_screen.dart';
import '../repositories/auth_repository.dart';
import 'route_guards.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final authSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentSession;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = ValueNotifier<int>(0);

  ref.listen(authStateProvider, (_, __) {
    authRefresh.value++;
  });
  ref.listen(currentProfileProvider, (_, __) {
    authRefresh.value++;
  });

  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final profileAsync = ref.read(currentProfileProvider);
      final location = state.matchedLocation;

      if (authAsync.isLoading ||
          (authAsync.valueOrNull?.session != null && profileAsync.isLoading)) {
        return location == '/splash' ? null : '/splash';
      }

      final session = ref.read(authSessionProvider);
      final isAuthenticated = session != null;
      final role = profileAsync.valueOrNull?.role;

      if (location == '/splash') {
        if (!isAuthenticated) return '/login';
        if (profileAsync.hasError || profileAsync.valueOrNull == null) {
          return '/login';
        }
        return homePathForRole(role);
      }

      return roleGuardRedirect(
        isAuthenticated: isAuthenticated,
        role: role,
        location: location,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CustomerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/home',
                builder: (_, __) => const CustomerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/explore',
                builder: (context, state) => ExploreScreen(
                  initialCategory: state.uri.queryParameters['category'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/bookings',
                builder: (_, __) => const CustomerBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/favorites',
                builder: (_, __) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/profile',
                builder: (_, __) => const CustomerProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            OwnerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/dashboard',
                builder: (_, __) => const OwnerDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/bookings',
                builder: (_, __) => const OwnerBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/services',
                builder: (_, __) => const OwnerServicesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/staff',
                builder: (_, __) => const OwnerStaffScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/more',
                builder: (_, __) => const OwnerMoreScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            BarberShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/barber/dashboard',
                builder: (_, __) => const BarberDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/barber/appointments',
                builder: (_, __) => const BarberAppointmentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/barber/scan',
                builder: (_, __) => const BarberScanTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/barber/schedule',
                builder: (_, __) => const BarberScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/barber/profile',
                builder: (_, __) => const BarberProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/salon/:salonId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SalonDetailsScreen(
          salonId: state.pathParameters['salonId']!,
        ),
      ),
      GoRoute(
        path: '/salon/:salonId/book',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BookingFlowScreen(
          salonId: state.pathParameters['salonId']!,
          initialServiceId: state.uri.queryParameters['serviceId'],
        ),
      ),
      GoRoute(
        path: '/booking/:bookingId/ticket',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BookingTicketScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/qr/scan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const EditProfileScreen(),
      ),
    ],
  );
});
