import 'package:flutter/material.dart';

import '../models/account_type.dart';
import '../views/admin/super_admin_dashboard_screen.dart';
import '../views/dashboard/showroom_dashboard_screen.dart';
import '../views/dashboard/user_dashboard_screen.dart';
import 'super_admin_config.dart';

/// Resolves the post-sign-in dashboard from the authenticated email and profile.
Widget dashboardForAuthenticatedUser({
  required String? email,
  AccountType? accountType,
}) {
  if (isSuperAdminEmail(email)) {
    return const SuperAdminDashboardScreen();
  }
  if (accountType == AccountType.showroom) {
    return const ShowroomDashboardScreen();
  }
  return const UserDashboardScreen();
}
