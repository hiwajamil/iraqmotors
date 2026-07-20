import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/core/utils/activity_actions.dart';
import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/utils/relative_time.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/features/admin/domain/models/activity_log.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';

/// Scrollable audit trail of super-admin actions.
class AdminActivityLogsView extends ConsumerStatefulWidget {
  const AdminActivityLogsView({super.key, required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<AdminActivityLogsView> createState() =>
      _AdminActivityLogsViewState();
}

class _AdminActivityLogsViewState extends ConsumerState<AdminActivityLogsView> {
  late Future<List<ActivityLog>> _logsFuture;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchLogs();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ActivityLog>> _fetchLogs() {
    return ref.read(activityLogServiceProvider).fetchActivityLogs();
  }

  void _reload() {
    setState(() {
      _logsFuture = _fetchLogs();
    });
  }

  List<ActivityLog> _filterLogs(List<ActivityLog> logs, AppLocalizations l10n) {
    if (_query.isEmpty) return logs;
    return logs.where((log) {
      final action = _localizedAction(log.action, l10n).toLowerCase();
      final admin = log.adminDisplayName.toLowerCase();
      final details = log.details.toLowerCase();
      return action.contains(_query) ||
          admin.contains(_query) ||
          details.contains(_query) ||
          log.action.toLowerCase().contains(_query);
    }).toList();
  }

  static String _localizedAction(String action, AppLocalizations l10n) {
    return switch (action) {
      ActivityActions.approvedAd => l10n.adminActivityActionApproved,
      ActivityActions.rejectedAd => l10n.adminActivityActionRejected,
      ActivityActions.deletedAd => l10n.adminActivityActionDeleted,
      ActivityActions.updatedPackagePrice =>
        l10n.adminActivityActionUpdatedPrice,
      ActivityActions.updatedSystemConfig => l10n.adminActivityActionUpdatedConfig,
      ActivityActions.addedCity => l10n.adminActivityActionAddedCity,
      ActivityActions.removedCity => l10n.adminActivityActionRemovedCity,
      ActivityActions.addedAdmin => l10n.adminActivityActionAddedAdmin,
      ActivityActions.updatedCredentials =>
        l10n.adminActivityActionUpdatedCredentials,
      _ => action,
    };
  }

  static _ActivityVisual _visualForAction(BuildContext context, String action) {
    final scheme = Theme.of(context).colorScheme;
    return switch (action) {
      ActivityActions.approvedAd => _ActivityVisual(
          Icons.check_circle_outline,
          scheme.tertiary,
          scheme.tertiaryContainer,
        ),
      ActivityActions.rejectedAd => _ActivityVisual(
          Icons.cancel_outlined,
          scheme.error,
          scheme.errorContainer,
        ),
      ActivityActions.deletedAd => _ActivityVisual(
          Icons.delete_outline,
          scheme.error,
          scheme.errorContainer,
        ),
      ActivityActions.updatedPackagePrice => _ActivityVisual(
          Icons.payments_outlined,
          scheme.primary,
          scheme.primaryContainer,
        ),
      ActivityActions.addedCity => _ActivityVisual(
          Icons.location_city_outlined,
          scheme.secondary,
          scheme.secondaryContainer,
        ),
      ActivityActions.removedCity => _ActivityVisual(
          Icons.location_off_outlined,
          scheme.secondary,
          scheme.secondaryContainer,
        ),
      ActivityActions.addedAdmin => _ActivityVisual(
          Icons.person_add_outlined,
          scheme.primary,
          scheme.primaryContainer,
        ),
      ActivityActions.updatedCredentials => _ActivityVisual(
          Icons.vpn_key_outlined,
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHighest,
        ),
      _ => _ActivityVisual(
          Icons.history,
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHighest,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.navActivity,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AddCarTheme.textPrimary(context),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminActivitySubtitle,
          style: AddCarTheme.stepSubtitle(context).copyWith(fontSize: 14),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _searchController,
          decoration: AddCarTheme.textFieldDecoration(
            context,
            hintText: l10n.adminActivitySearchHint,
          ).copyWith(
            prefixIcon: Icon(
              Icons.search,
              color: AddCarTheme.textSecondary(context),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: FutureBuilder<List<ActivityLog>>(
            future: _logsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (snapshot.hasError) {
                return _ErrorState(
                  message: snapshot.error.toString(),
                  retryLabel: l10n.adminRetry,
                  onRetry: _reload,
                );
              }

              final allLogs = snapshot.data ?? const [];
              final logs = _filterLogs(allLogs, l10n);

              if (logs.isEmpty) {
                return _EmptyState(
                  message: _query.isEmpty
                      ? l10n.adminActivityEmpty
                      : l10n.adminActivityNoResults,
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _ActivityLogRow(
                      log: log,
                      actionLabel: _localizedAction(log.action, l10n),
                      visual: _visualForAction(context, log.action),
                      timeLabel: log.timestamp != null
                          ? formatRelativeTime(log.timestamp!, l10n)
                          : '—',
                      isMobile: widget.isMobile,
                      performedByLabel: l10n.adminActivityPerformedBy,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActivityVisual {
  const _ActivityVisual(this.icon, this.color, this.background);

  final IconData icon;
  final Color color;
  final Color background;
}

class _ActivityLogRow extends StatelessWidget {
  const _ActivityLogRow({
    required this.log,
    required this.actionLabel,
    required this.visual,
    required this.timeLabel,
    required this.isMobile,
    required this.performedByLabel,
  });

  final ActivityLog log;
  final String actionLabel;
  final _ActivityVisual visual;
  final String timeLabel;
  final bool isMobile;
  final String performedByLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final adminLabel = log.adminDisplayName.isNotEmpty
        ? log.adminDisplayName
        : log.adminId;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: visual.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(visual.icon, color: visual.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        actionLabel,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$performedByLabel: $adminLabel',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (log.details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    IraqLocationL10n.localizeActivityDetails(l10n, log.details),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
