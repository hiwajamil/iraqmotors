import 'package:flutter/material.dart';

import 'package:iq_motors/shared/models/account_type.dart';
import 'package:iq_motors/features/listings/presentation/add_car_flow_screen.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:iq_motors/features/dashboard/presentation/screens/showroom_dashboard_screen.dart';
import 'package:iq_motors/features/dashboard/presentation/screens/user_dashboard_screen.dart';
import 'package:iq_motors/core/config/super_admin_config.dart';

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
