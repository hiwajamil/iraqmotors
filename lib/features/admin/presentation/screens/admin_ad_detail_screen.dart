import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  static const Color _bg = Color(0xFFF5F5F7);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _divider = Color(0xFFE5E5EA);

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
          backgroundColor: const Color(0xFFFF3B30),
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
          style: const TextStyle(fontWeight: FontWeight.w700, color: _textPrimary),
        ),
        content: Text(
          l10n.adminRejectAdConfirm,
          style: const TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
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

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.actionView,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
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
                  fg: const Color(0xFFFF3B30),
                  bg: Colors.white,
                  border: const Color(0xFFFF3B30),
                  isLoading: _isProcessing,
                  onTap: _confirmReject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BottomActionButton(
                  label: l10n.actionApprove,
                  fg: Colors.white,
                  bg: const Color(0xFF1D1D1F),
                  border: const Color(0xFF1D1D1F),
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
                color: _card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(l10n),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
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
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminDescriptionLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _draft.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _textSecondary,
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
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: urls[index],
              width: 300,
              height: 220,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: _AdminAdDetailScreenState._divider,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) => Container(
                color: _AdminAdDetailScreenState._divider,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _AdminAdDetailScreenState._card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isShowroom
                  ? const Color(0xFFF3EBFF)
                  : const Color(0xFFE6F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isShowroom ? Icons.storefront_outlined : Icons.person_outline,
              color: isShowroom
                  ? const Color(0xFFAF52DE)
                  : const Color(0xFF007AFF),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _AdminAdDetailScreenState._textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.phone,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _AdminAdDetailScreenState._textSecondary,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _AdminAdDetailScreenState._card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _AdminAdDetailScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < section.rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: _AdminAdDetailScreenState._divider),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    section.rows[i].label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _AdminAdDetailScreenState._textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    section.rows[i].value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _AdminAdDetailScreenState._textPrimary,
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
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: filled ? Colors.white : fg,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
      ),
    );
  }
}
