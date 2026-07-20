import 'package:iq_motors/shared/widgets/app_cached_network_image.dart';
import 'package:iq_motors/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/core/utils/activity_actions.dart';
import 'package:iq_motors/features/admin/domain/admin_audit_helper.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/shared/data/car_models_by_brand.dart';
import 'package:iq_motors/shared/data/dummy_brands.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/shared/models/account_type.dart';
import 'package:iq_motors/features/listings/domain/models/add_car_draft.dart';
import 'package:iq_motors/features/auth/domain/models/user_profile.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/listings/presentation/add_car_review_summary.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';

/// Admin review screen for a pending car listing.
class AdminAdDetailScreen extends ConsumerStatefulWidget {
  const AdminAdDetailScreen({
    super.key,
    required this.adData,
    this.sellerProfile,
  });

  final Map<String, dynamic> adData;
  final UserProfile? sellerProfile;

  @override
  ConsumerState<AdminAdDetailScreen> createState() =>
      _AdminAdDetailScreenState();
}

class _AdminAdDetailScreenState extends ConsumerState<AdminAdDetailScreen> {
  bool _isProcessing = false;

  String get _adId => widget.adData['id']?.toString() ?? '';

  List<String> get _imageUrls {
    final urls = widget.adData['imageUrls'];
    if (urls is List) {
      return urls.map((e) => e.toString()).where((u) => u.isNotEmpty).toList();
    }
    return const [];
  }

  AddCarDraft get _draft => AddCarDraft.fromFirestoreMap(widget.adData);

  String _title(AppLocalizations l10n) {
    final languageCode = l10n.localeName.split('_').first;
    final brandId = widget.adData['brandId']?.toString();
    final modelKey = widget.adData['modelKey']?.toString();
    final year = widget.adData['year']?.toString();
    final trim = widget.adData['trim']?.toString();

    String brandModel = '';
    if (brandId != null) {
      for (final brand in dummyBrands) {
        if (brand.id == brandId) {
          final modelLabel = modelKey != null
              ? CarModelsByBrand.labelForModel(brand, modelKey, languageCode)
              : null;
          brandModel = modelLabel != null
              ? '${brand.displayName(languageCode)} $modelLabel'
              : brand.displayName(languageCode);
          break;
        }
      }
    }

    final parts = [
      if (brandModel.isNotEmpty) brandModel,
      if (year != null && year.isNotEmpty) year,
      if (trim != null && trim.isNotEmpty) trim,
    ];
    return parts.isNotEmpty ? parts.join(' ') : l10n.carFallbackTitle;
  }

  String _formatPrice() {
    final raw = widget.adData['priceValue'];
    if (raw == null) return '—';
    final amount = raw is num ? raw.toInt() : int.tryParse(raw.toString());
    if (amount == null) return '—';

    final currencyKey = widget.adData['currencyKey']?.toString() ??
        AddCarFormOptions.defaultCurrencyKey;
    final symbol = AddCarFormOptions.currencySymbol(currencyKey);
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$symbol$formatted';
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_adId.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(carDatabaseServiceProvider).updateAdStatus(
            adId: _adId,
            newStatus: newStatus,
            audit: buildAdminAudit(
              ref,
              action: newStatus == CarDatabaseService.statusActive
                  ? ActivityActions.approvedAd
                  : ActivityActions.rejectedAd,
              details: 'Ad ID: $_adId, Title: ${_title(context.l10n)}',
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _confirmReject() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.adminRejectAdTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AddCarTheme.textPrimary(context),
          ),
        ),
        content: Text(
          l10n.adminRejectAdConfirm,
          style: TextStyle(color: AddCarTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.actionReject),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(CarDatabaseService.statusRejected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = AddCarReviewSummary.build(l10n, _draft);
    final profile = widget.sellerProfile;
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: scheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.actionView,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: _BottomActionButton(
                  label: l10n.actionReject,
                  fg: scheme.error,
                  bg: scheme.surfaceContainerLowest,
                  border: scheme.error,
                  isLoading: _isProcessing,
                  onTap: _confirmReject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BottomActionButton(
                  label: l10n.actionApprove,
                  fg: scheme.onPrimary,
                  bg: scheme.primary,
                  border: scheme.primary,
                  filled: true,
                  isLoading: _isProcessing,
                  onTap: () => _updateStatus(CarDatabaseService.statusActive),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageUrls.isNotEmpty) ...[
              _ImageGallery(urls: _imageUrls),
              const SizedBox(height: 20),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(l10n),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (profile != null) ...[
              const SizedBox(height: 16),
              _PublisherCard(profile: profile),
            ],
            const SizedBox(height: 16),
            for (final section in sections) ...[
              _DetailSection(section: section),
              const SizedBox(height: 12),
            ],
            if (_draft.description != null &&
                _draft.description!.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminDescriptionLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _draft.description!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final divider = context.colorScheme.outlineVariant;
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AppCachedNetworkImage(
              imageUrl: urls[index],
              width: 300,
              height: 220,
              fit: BoxFit.cover,
              memCacheLogicalWidth: 300,
              memCacheLogicalHeight: 220,
              placeholder: (_, _) => Container(
                color: divider,
                alignment: Alignment.center,
                child: const AppLoadingIndicator.standard(),
              ),
              errorWidget: (_, _, _) => Container(
                color: divider,
                child: const Icon(Icons.directions_car_outlined, size: 48),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PublisherCard extends StatelessWidget {
  const _PublisherCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final isShowroom = profile.accountType == AccountType.showroom;
    final scheme = context.colorScheme;
    final accentBg = isShowroom ? scheme.secondaryContainer : scheme.primaryContainer;
    final accentFg = isShowroom ? scheme.onSecondaryContainer : scheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isShowroom ? Icons.storefront_outlined : Icons.person_outline,
              color: accentFg,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.phone,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.section});

  final AddCarReviewSection section;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < section.rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: scheme.outlineVariant),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    section.rows[i].label,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    section.rows[i].value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.label,
    required this.fg,
    required this.bg,
    required this.border,
    required this.onTap,
    this.filled = false,
    this.isLoading = false,
  });

  final String label;
  final Color fg;
  final Color bg;
  final Color border;
  final bool filled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final child = isLoading
        ? AppLoadingIndicator.compact(color: fg)
        : Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          );

    if (filled) {
      return FilledButton(
        onPressed: isLoading ? null : onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.7),
          disabledForegroundColor: fg,
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: fg,
        side: BorderSide(color: border),
      ),
      child: child,
    );
  }
}
