import 'package:flutter/material.dart';

import '../core/filter_l10n.dart';
import '../core/l10n_extensions.dart';

/// Apple-style bottom sheet for picking a filter location.
Future<String?> showLocationPickerSheet(BuildContext context) {
  final l10n = context.l10n;

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.selectCity,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          ...LocationKeys.all.map(
            (key) => ListTile(
              title: Text(FilterL10n.locationLabel(l10n, key)),
              onTap: () => Navigator.pop(ctx, key),
            ),
          ),
        ],
      ),
    ),
  );
}
