import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/activity_actions.dart';
import '../../core/iraq_location_l10n.dart';
import '../../core/l10n_extensions.dart';
import '../../core/relative_time.dart';
import '../../l10n/app_localizations.dart';
import '../../models/activity_log.dart';
import '../../providers/storage_providers.dart';
import '../add_car/add_car_theme.dart';

/// Scrollable audit trail of super-admin actions.
class AdminActivityLogsView extends ConsumerStatefulWidget {
  const AdminActivityLogsView({super.key, required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<AdminActivityLogsView> createState() =>
      _AdminActivityLogsViewState();
}

class _AdminActivityLogsViewState extends ConsumerState<AdminActivityLogsView> {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

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

  static _ActivityVisual _visualForAction(String action) {
    return switch (action) {
      ActivityActions.approvedAd => const _ActivityVisual(
          Icons.check_circle_outline,
          Color(0xFF34C759),
          Color(0xFFE8F8ED),
        ),
      ActivityActions.rejectedAd => const _ActivityVisual(
          Icons.cancel_outlined,
          Color(0xFFFF3B30),
          Color(0xFFFFEBEA),
        ),
      ActivityActions.deletedAd => const _ActivityVisual(
          Icons.delete_outline,
          Color(0xFFFF3B30),
          Color(0xFFFFEBEA),
        ),
      ActivityActions.updatedPackagePrice => const _ActivityVisual(
          Icons.payments_outlined,
          Color(0xFF007AFF),
          Color(0xFFE8F2FF),
        ),
      ActivityActions.addedCity => const _ActivityVisual(
          Icons.location_city_outlined,
          Color(0xFF5856D6),
          Color(0xFFEEEDFA),
        ),
      ActivityActions.removedCity => const _ActivityVisual(
          Icons.location_off_outlined,
          Color(0xFFFF9500),
          Color(0xFFFFF4E5),
        ),
      ActivityActions.addedAdmin => const _ActivityVisual(
          Icons.person_add_outlined,
          Color(0xFF007AFF),
          Color(0xFFE8F2FF),
        ),
      ActivityActions.updatedCredentials => const _ActivityVisual(
          Icons.vpn_key_outlined,
          Color(0xFF86868B),
          Color(0xFFF2F2F7),
        ),
      _ => const _ActivityVisual(
          Icons.history,
          Color(0xFF86868B),
          Color(0xFFF2F2F7),
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
          style: TextStyle(
            fontSize: widget.isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminActivitySubtitle,
          style: const TextStyle(fontSize: 14, color: _textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _searchController,
          decoration: AddCarTheme.textFieldDecoration(
            hintText: l10n.adminActivitySearchHint,
          ).copyWith(
            prefixIcon: const Icon(Icons.search, color: _textSecondary, size: 20),
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
                      visual: _visualForAction(log.action),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$performedByLabel: $adminLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF86868B),
                  ),
                ),
                if (log.details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    IraqLocationL10n.localizeActivityDetails(l10n, log.details),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1D1D1F),
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
            color: const Color(0xFF86868B).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF86868B)),
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
