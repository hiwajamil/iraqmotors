import 'package:flutter/material.dart';

import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_theme.dart';

/// Numbered page controls for the home listing grid.
class HomePagination extends StatelessWidget {
  const HomePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  static const int _maxVisiblePages = 7;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = _visiblePages(currentPage, totalPages);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 32, 16, 48),
      child: Center(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              enabled: currentPage > 1,
              onTap: () => onPageSelected(currentPage - 1),
            ),
            for (final page in pages)
              if (page == null)
                const _Ellipsis()
              else
                _PageButton(
                  page: page,
                  isSelected: page == currentPage,
                  onTap: () => onPageSelected(page),
                ),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              enabled: currentPage < totalPages,
              onTap: () => onPageSelected(currentPage + 1),
            ),
          ],
        ),
      ),
    );
  }

  List<int?> _visiblePages(int current, int total) {
    if (total <= _maxVisiblePages) {
      return [for (var i = 1; i <= total; i++) i];
    }

    const edge = 2;
    final pages = <int?>{};

    for (var i = 1; i <= edge; i++) {
      pages.add(i);
    }
    for (var i = total - edge + 1; i <= total; i++) {
      pages.add(i);
    }

    final windowStart = (current - 1).clamp(edge + 1, total - edge);
    final windowEnd = (current + 1).clamp(edge + 1, total - edge);
    for (var i = windowStart; i <= windowEnd; i++) {
      pages.add(i);
    }

    final sorted = pages.whereType<int>().toList()..sort();
    final result = <int?>[];
    int? previous;

    for (final page in sorted) {
      if (previous != null && page - previous > 1) {
        result.add(null);
      }
      result.add(page);
      previous = page;
    }

    return result;
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  final int page;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    if (isSelected) {
      return FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
          disabledBackgroundColor: scheme.primary,
          disabledForegroundColor: scheme.onPrimary,
        ),
        child: Text('$page'),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        foregroundColor: scheme.onSurface,
      ),
      child: Text('$page'),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: enabled ? onTap : null,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }
}

class _Ellipsis extends StatelessWidget {
  const _Ellipsis();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Text(
          '…',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: HomeScreenColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}
