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
      location == '/splash';
}

String? roleGuardRedirect({
  required bool isAuthenticated,
  required UserRole? role,
  required String location,
}) {
  if (!isAuthenticated) {
    if (isAuthRoute(location)) return null;
    return '/login';
  }

  if (isAuthRoute(location) || location == '/') {
    return homePathForRole(role);
  }

  if (location.startsWith('/customer') &&
      role != UserRole.customer &&
      role != UserRole.admin) {
    return homePathForRole(role);
  }
  if (location.startsWith('/owner') && role != UserRole.salonOwner) {
    return homePathForRole(role);
  }
  if (location.startsWith('/barber') && role != UserRole.barber) {
    return homePathForRole(role);
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
