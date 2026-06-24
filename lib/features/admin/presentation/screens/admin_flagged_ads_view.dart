import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/utils/activity_actions.dart';
import 'package:iq_motors/features/admin/domain/admin_audit_helper.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/car_models_by_brand.dart';
import 'package:iq_motors/shared/data/dummy_brands.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/features/admin/domain/models/flagged_ad_report.dart';
import 'package:iq_motors/features/auth/domain/models/user_profile.dart';
import 'package:iq_motors/features/auth/presentation/providers/auth_providers.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/features/admin/presentation/screens/admin_ad_detail_screen.dart';

/// Moderation queue for user-reported car listings.
class AdminFlaggedAdsView extends ConsumerStatefulWidget {
  const AdminFlaggedAdsView({super.key, required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<AdminFlaggedAdsView> createState() =>
      _AdminFlaggedAdsViewState();
}

class _AdminFlaggedAdsViewState extends ConsumerState<AdminFlaggedAdsView> {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _warning = Color(0xFFFF9500);

  late Future<List<FlaggedAdReport>> _reportsFuture;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _reportsFuture = _fetchReports();
  }

  Future<List<FlaggedAdReport>> _fetchReports() {
    return ref.read(flaggedAdsServiceProvider).fetchFlaggedAds();
  }

  void _reload() {
    setState(() {
      _reportsFuture = _fetchReports();
    });
  }

  String _carTitle(Map<String, dynamic>? adData, AppLocalizations l10n) {
    if (adData == null) return l10n.adminFlaggedAdMissing;

    final languageCode = l10n.localeName.split('_').first;
    final brandId = adData['brandId']?.toString();
    final modelKey = adData['modelKey']?.toString();
    final year = adData['year']?.toString();
    final trim = adData['trim']?.toString();

    if (brandId != null) {
      for (final brand in dummyBrands) {
        if (brand.id == brandId) {
          final modelLabel = modelKey != null
              ? CarModelsByBrand.labelForModel(brand, modelKey, languageCode)
              : null;
          final brandName = brand.displayName(languageCode);
          final parts = [
            if (modelLabel != null) '$brandName $modelLabel' else brandName,
            if (year != null && year.isNotEmpty) year,
            if (trim != null && trim.isNotEmpty) trim,
          ];
          if (parts.isNotEmpty) return parts.join(' ');
          break;
        }
      }
    }

    return adData['title']?.toString() ?? l10n.carFallbackTitle;
  }

  String _imageUrl(Map<String, dynamic>? adData) {
    if (adData == null) return '';
    final urls = adData['imageUrls'];
    if (urls is List && urls.isNotEmpty) {
      return urls.first.toString();
    }
    return adData['imageUrl']?.toString() ?? '';
  }

  String _localizedReason(String reason, AppLocalizations l10n) {
    return switch (reason) {
      FlagReportReasonKeys.soldAlready => l10n.flaggedReasonSold,
      FlagReportReasonKeys.wrongPrice => l10n.flaggedReasonWrongPrice,
      FlagReportReasonKeys.misleading => l10n.flaggedReasonMisleading,
      FlagReportReasonKeys.spam => l10n.flaggedReasonSpam,
      _ => reason,
    };
  }

  Future<void> _viewAd(FlaggedAdReport report, AppLocalizations l10n) async {
    final adData = report.adData;
    if (adData == null) {
      _showSnack(l10n.adminFlaggedAdMissing, isError: true);
      return;
    }

    UserProfile? sellerProfile;
    final sellerId = adData['sellerId']?.toString();
    if (sellerId != null && sellerId.isNotEmpty) {
      sellerProfile = await ref.read(authServiceProvider).fetchProfile(sellerId);
    }

    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminAdDetailScreen(
          adData: adData,
          sellerProfile: sellerProfile,
        ),
      ),
    );
  }

  Future<void> _ignoreReport(FlaggedAdReport report) async {
    if (_processingIds.contains(report.id)) return;
    setState(() => _processingIds.add(report.id));

    try {
      await ref.read(flaggedAdsServiceProvider).resolveFlaggedAd(
            reportId: report.id,
          );
      if (!mounted) return;
      _showSnack(context.l10n.adminFlaggedIgnoredSuccess);
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _processingIds.remove(report.id));
    }
  }

  Future<void> _deleteAd(FlaggedAdReport report, AppLocalizations l10n) async {
    if (report.adId.isEmpty || _processingIds.contains(report.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.adminFlaggedDeleteAd,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        content: Text(
          l10n.adminFlaggedDeleteConfirm,
          style: const TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
            ),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingIds.add(report.id));
    try {
      final title = _carTitle(report.adData, l10n);
      await ref.read(carDatabaseServiceProvider).deleteCarAd(
            adId: report.adId,
            audit: buildAdminAudit(
              ref,
              action: ActivityActions.deletedAd,
              details:
                  'Ad ID: ${report.adId}, Title: $title (Flagged: ${report.reason})',
            ),
          );
      await ref.read(flaggedAdsServiceProvider).resolveFlaggedAd(
            reportId: report.id,
          );
      if (!mounted) return;
      _showSnack(l10n.adminFlaggedDeleteSuccess);
      _reload();
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _processingIds.remove(report.id));
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFFF3B30) : AddCarTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.navFlaggedAds,
          style: TextStyle(
            fontSize: widget.isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminFlaggedSubtitle,
          style: const TextStyle(fontSize: 14, color: _textSecondary),
        ),
        const SizedBox(height: 28),
        FutureBuilder<List<FlaggedAdReport>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            if (snapshot.hasError) {
              return _ErrorBanner(
                message: snapshot.error.toString(),
                retryLabel: l10n.adminRetry,
                onRetry: _reload,
              );
            }

            final reports = snapshot.data ?? const [];
            if (reports.isEmpty) {
              return _EmptyState(message: l10n.adminFlaggedEmpty);
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final report = reports[index];
                return _FlaggedAdCard(
                  report: report,
                  title: _carTitle(report.adData, l10n),
                  imageUrl: _imageUrl(report.adData),
                  reasonLabel: _localizedReason(report.reason, l10n),
                  reporterName: report.reporterDisplayName?.isNotEmpty == true
                      ? report.reporterDisplayName!
                      : report.reportedBy,
                  isProcessing: _processingIds.contains(report.id),
                  isMobile: widget.isMobile,
                  reasonCaption: l10n.adminFlaggedReasonLabel,
                  reportedByCaption: l10n.adminFlaggedReportedByLabel,
                  viewLabel: l10n.adminFlaggedViewAd,
                  deleteLabel: l10n.adminFlaggedDeleteAd,
                  ignoreLabel: l10n.adminFlaggedIgnore,
                  onView: () => _viewAd(report, l10n),
                  onDelete: () => _deleteAd(report, l10n),
                  onIgnore: () => _ignoreReport(report),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _FlaggedAdCard extends StatelessWidget {
  const _FlaggedAdCard({
    required this.report,
    required this.title,
    required this.imageUrl,
    required this.reasonLabel,
    required this.reporterName,
    required this.isProcessing,
    required this.isMobile,
    required this.reasonCaption,
    required this.reportedByCaption,
    required this.viewLabel,
    required this.deleteLabel,
    required this.ignoreLabel,
    required this.onView,
    required this.onDelete,
    required this.onIgnore,
  });

  final FlaggedAdReport report;
  final String title;
  final String imageUrl;
  final String reasonLabel;
  final String reporterName;
  final bool isProcessing;
  final bool isMobile;
  final String reasonCaption;
  final String reportedByCaption;
  final String viewLabel;
  final String deleteLabel;
  final String ignoreLabel;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AddCarTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdThumbnail(imageUrl: imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: _AdminFlaggedAdsViewState._warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: _AdminFlaggedAdsViewState._textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _MetaRow(
                      label: reasonCaption,
                      value: reasonLabel,
                    ),
                    const SizedBox(height: 6),
                    _MetaRow(
                      label: reportedByCaption,
                      value: reporterName,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActionButton(
                  label: viewLabel,
                  icon: Icons.visibility_outlined,
                  onPressed: isProcessing ? null : onView,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: deleteLabel,
                  icon: Icons.delete_outline,
                  foregroundColor: const Color(0xFFFF3B30),
                  onPressed: isProcessing ? null : onDelete,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: ignoreLabel,
                  icon: Icons.block_outlined,
                  foregroundColor: _AdminFlaggedAdsViewState._textSecondary,
                  onPressed: isProcessing ? null : onIgnore,
                ),
              ],
            )
          else
            Row(
              children: [
                _ActionButton(
                  label: viewLabel,
                  icon: Icons.visibility_outlined,
                  onPressed: isProcessing ? null : onView,
                ),
                const SizedBox(width: 10),
                _ActionButton(
                  label: deleteLabel,
                  icon: Icons.delete_outline,
                  foregroundColor: const Color(0xFFFF3B30),
                  onPressed: isProcessing ? null : onDelete,
                ),
                const SizedBox(width: 10),
                _ActionButton(
                  label: ignoreLabel,
                  icon: Icons.block_outlined,
                  foregroundColor: _AdminFlaggedAdsViewState._textSecondary,
                  onPressed: isProcessing ? null : onIgnore,
                ),
                if (isProcessing) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _AdThumbnail extends StatelessWidget {
  const _AdThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 88,
        height: 88,
        color: const Color(0xFFF2F2F7),
        child: imageUrl.isEmpty
            ? const Icon(Icons.directions_car_outlined, color: Color(0xFF86868B))
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF86868B),
                ),
              ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, height: 1.4),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: _AdminFlaggedAdsViewState._textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: _AdminFlaggedAdsViewState._textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? AddCarTheme.focusBlue;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: const Color(0xFF86868B).withValues(alpha: 0.45),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: _AdminFlaggedAdsViewState._textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
