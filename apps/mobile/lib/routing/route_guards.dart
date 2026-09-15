import 'package:flutter/material.dart';

import '../models/profile.dart';

String homePathForRole(UserRole? role) {
  switch (role) {
    case UserRole.salonOwner:
      return '/owner/dashboard';
    case UserRole.barber:
      return '/barber/dashboard';
    case UserRole.admin:
      // Admin uses web; fall back to customer shell on mobile.
      return '/customer/home';
    case UserRole.customer:
    case null:
      return '/customer/home';
  }
}

bool isAuthRoute(String location) {
  return location == '/login' ||
      location == '/register' ||
      location == '/forgot-password' ||
      location == '/splash' ||
      location.startsWith('/invite/');
}

bool canAccessPath(String location, List<UserRole> capabilities) {
  if (capabilities.contains(UserRole.admin)) return true;
  if (location.startsWith('/owner')) {
    return capabilities.contains(UserRole.salonOwner);
  }
  if (location.startsWith('/barber')) {
    return capabilities.contains(UserRole.barber);
  }
  // Customer shell (and shared routes) always allowed for authenticated users.
  return true;
}

String? roleGuardRedirect({
  required bool isAuthenticated,
  required Profile? profile,
  required String location,
}) {
  if (!isAuthenticated) {
    if (isAuthRoute(location)) return null;
    return '/login';
  }

  final active = profile?.effectiveActiveRole ?? UserRole.customer;
  final caps = profile?.capabilities ?? const [UserRole.customer];

  if (isAuthRoute(location) || location == '/') {
    if (location.startsWith('/invite/')) return null;
    return homePathForRole(active);
  }

  if (!canAccessPath(location, caps)) {
    return homePathForRole(active);
  }

  return null;
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
