import 'package:flutter/material.dart';

import '../models/account_type.dart';
import '../views/add_car/add_car_flow_screen.dart';
import '../views/admin/admin_dashboard_screen.dart';
import '../views/dashboard/showroom_dashboard_screen.dart';
import '../views/dashboard/user_dashboard_screen.dart';
import 'super_admin_config.dart';

enum PostAuthRoute {
  dashboard,
  sellCar,
}

/// Resolves the post-sign-in dashboard from the authenticated email and profile.
Widget dashboardForAuthenticatedUser({
  required String? email,
  String? phone,
  AccountType? accountType,
}) {
  if (isSuperAdminUser(email: email, phone: phone)) {
    return const AdminDashboardScreen();
  }
  if (accountType == AccountType.showroom) {
    return const ShowroomDashboardScreen();
  }
  return const UserDashboardScreen();
}

/// Screen to open after a successful sign-in or registration.
Widget screenForPostAuthRoute(
  PostAuthRoute route, {
  required String? email,
  String? phone,
  AccountType? accountType,
}) {
  return switch (route) {
    PostAuthRoute.dashboard => dashboardForAuthenticatedUser(
        email: email,
        phone: phone,
        accountType: accountType,
      ),
    PostAuthRoute.sellCar => const AddCarFlowScreen(),
  };
}
