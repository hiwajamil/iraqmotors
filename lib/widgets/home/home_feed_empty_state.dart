import 'package:flutter/material.dart';

import 'home_theme.dart';

/// Empty-state placeholder when the home feed has no active listings.
class HomeFeedEmptyState extends StatelessWidget {
  const HomeFeedEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 48,
              color: HomeScreenColors.textSecondary.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: HomeScreenColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
