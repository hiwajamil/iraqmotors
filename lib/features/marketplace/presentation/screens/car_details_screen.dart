import 'package:iq_motors/shared/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:iq_motors/core/utils/car_image_urls.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/localized_dummy_data.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:iq_motors/features/marketplace/presentation/providers/user_interest_provider.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/shared/widgets/car_network_image.dart';
import 'package:iq_motors/features/auth/presentation/screens/auth_screen.dart';

/// Car details (زانیاری ئۆتۆمبێل) — gallery collage, specs, sticky seller card.
class CarDetailsScreen extends ConsumerStatefulWidget {
  const CarDetailsScreen({
    super.key,
    this.car,
  });

  /// Optional listing map; falls back to prototype dummy data.
  final Map<String, dynamic>? car;

  @override
  ConsumerState<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends ConsumerState<CarDetailsScreen> {
  static const Color _background = Color(0xFFF5F5F7);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _divider = Color(0xFFE5E5EA);
  static const Color _accentBlue = Color(0xFF007AFF);
  static const Color _whatsappGreen = Color(0xFF25D366);
  static const Color _callBlack = Color(0xFF000000);
  static const double _desktopBreakpoint = 992;

  bool _prototypeSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final car = widget.car;
      if (car != null) {
        ref.read(userInterestRevisionProvider.notifier).recordFromCar(car);
      }
    });
  }

  Map<String, dynamic> _data(AppLocalizations l10n) {
    final prototype = LocalizedDummyData.prototypeCar(l10n);
    if (widget.car == null) return prototype;
    return {...prototype, ...widget.car!};
  }

  List<String> _images(AppLocalizations l10n) {
    final data = _data(l10n);
    final fromListing = carImageUrlsFromAd(data);
    if (fromListing.isNotEmpty) return fromListing;

    final prototype = LocalizedDummyData.prototypeCar(l10n);
    if (data['images'] is List) {
      return List<String>.from(data['images'] as List);
    }
    return List<String>.from(prototype['images'] as List);
  }

  double _horizontalPadding(double width) {
    if (width >= _desktopBreakpoint) return width * 0.08;
    return 20;
  }

  bool _isSaved() {
    final carId = widget.car?['id']?.toString();
    if (carId == null || carId.isEmpty) return _prototypeSaved;
    return ref.watch(favoritesProvider).contains(carId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = _data(l10n);
    final images = _images(l10n);
    final isSaved = _isSaved();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > _desktopBreakpoint;
        final hPad = _horizontalPadding(constraints.maxWidth);

        return Scaffold(
          backgroundColor: _background,
          bottomNavigationBar: isWide
              ? null
              : _MobileSellerBar(
                  data: data,
                  isSaved: isSaved,
                  onSaveToggle: _toggleSave,
                ),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailsAppBar(horizontalPadding: hPad),
                Expanded(
                  child: isWide
                      ? _WideLayout(
                          data: data,
                          images: images,
                          horizontalPadding: hPad,
                          isSaved: isSaved,
                          onSaveToggle: _toggleSave,
                        )
                      : _MobileScrollBody(
                          data: data,
                          images: images,
                          horizontalPadding: hPad,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleSave() async {
    final car = widget.car;
    if (car == null) {
      setState(() => _prototypeSaved = !_prototypeSaved);
      return;
    }

    try {
      await ref.read(favoritesProvider.notifier).toggle(car);
    } on FavoritesAuthRequired {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      );
    } on CarDatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }
}

class _DetailsAppBar extends StatelessWidget {
  const _DetailsAppBar({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        horizontalPadding,
        12,
        horizontalPadding,
        12,
      ),
      child: Row(
        children: [
          _BackButton(onPressed: () => Navigator.of(context).maybePop()),
          Expanded(
            child: Text(
              context.l10n.carDetailsTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _CarDetailsScreenState._textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFE8E8ED)
                : _CarDetailsScreenState._cardWhite,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18,
            color: _CarDetailsScreenState._textPrimary,
          ),
        ),
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.data,
    required this.images,
    required this.horizontalPadding,
    required this.isSaved,
    required this.onSaveToggle,
  });

  final Map<String, dynamic> data;
  final List<String> images;
  final double horizontalPadding;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        horizontalPadding,
        0,
        horizontalPadding,
        32,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _CarDetailsContent(
                data: data,
                images: images,
                galleryHeight: 500,
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 1,
            child: _SellerContactCard(
              data: data,
              isSaved: isSaved,
              onSaveToggle: onSaveToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileScrollBody extends StatelessWidget {
  const _MobileScrollBody({
    required this.data,
    required this.images,
    required this.horizontalPadding,
  });

  final Map<String, dynamic> data;
  final List<String> images;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsetsDirectional.fromSTEB(
        horizontalPadding,
        0,
        horizontalPadding,
        24,
      ),
      child: _CarDetailsContent(
        data: data,
        images: images,
        galleryHeight: 380,
      ),
    );
  }
}

class _MobileSellerBar extends StatelessWidget {
  const _MobileSellerBar({
    required this.data,
    required this.isSaved,
    required this.onSaveToggle,
  });

  final Map<String, dynamic> data;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _CarDetailsScreenState._cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
          child: _SellerContactCard(
            data: data,
            isSaved: isSaved,
            onSaveToggle: onSaveToggle,
            compact: true,
          ),
        ),
      ),
    );
  }
}

class _CarDetailsContent extends StatelessWidget {
  const _CarDetailsContent({
    required this.data,
    required this.images,
    required this.galleryHeight,
  });

  final Map<String, dynamic> data;
  final List<String> images;
  final double galleryHeight;

  @override
  Widget build(BuildContext context) {
    final make = data['make'] as String? ?? '';
    final model = data['model'] as String? ?? '';
    final price = data['price'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final features =
        List<String>.from(data['features'] as List? ?? const <String>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImageGalleryCollage(
          images: images,
          height: galleryHeight,
        ),
        const SizedBox(height: 32),
        Text(
          make.toUpperCase(),
          style: const TextStyle(
            fontSize: 13.6,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: _CarDetailsScreenState._textSecondary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          model,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            color: _CarDetailsScreenState._textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          price,
          style: const TextStyle(
            fontSize: 35.2,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: _CarDetailsScreenState._textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 28),
        _QuickSpecsGrid(data: data),
        const SizedBox(height: 32),
        if (description.isNotEmpty) ...[
          Text(
            context.l10n.description,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _CarDetailsScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: _CarDetailsScreenState._textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
        ],
        if (features.isNotEmpty) _FeaturesSection(features: features),
        const SizedBox(height: 24),
        _FullSpecsCard(data: data),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ImageGalleryCollage extends StatelessWidget {
  const _ImageGalleryCollage({
    required this.images,
    required this.height,
  });

  final List<String> images;
  final double height;

  static const double _gap = 12;
  static const double _radius = 20;
  static const double _smallRadius = 16;

  String _urlAt(int index) =>
      images.length > index ? images[index] : images.first;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _GalleryImage(
              url: _urlAt(0),
              borderRadius: BorderRadius.circular(_radius),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: _GalleryImage(
                    url: _urlAt(1),
                    borderRadius: BorderRadius.circular(_smallRadius),
                  ),
                ),
                const SizedBox(height: _gap),
                Expanded(
                  child: _GalleryImage(
                    url: _urlAt(2),
                    borderRadius: BorderRadius.circular(_smallRadius),
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

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({
    required this.url,
    required this.borderRadius,
  });

  final String url;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CarNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheLogicalWidth:
            (MediaQuery.sizeOf(context).width * 0.5).clamp(180, 400),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFFE8E8ED),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFE8E8ED),
          alignment: Alignment.center,
          child: Icon(
            Icons.directions_car_outlined,
            size: 40,
            color: Colors.black.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }
}

class _QuickSpecsGrid extends StatelessWidget {
  const _QuickSpecsGrid({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final specs = [
      _SpecItem(
        icon: Icons.speed,
        label: l10n.specMileage,
        value: data['mileage'] as String? ?? '—',
      ),
      _SpecItem(
        icon: Icons.settings,
        label: l10n.specTransmission,
        value: data['transmission'] as String? ?? '—',
      ),
      _SpecItem(
        icon: Icons.precision_manufacturing_outlined,
        label: l10n.specEngine,
        value: data['engine'] as String? ?? '—',
      ),
      _SpecItem(
        icon: Icons.location_on_outlined,
        label: l10n.specLocation,
        value: data['location'] as String? ?? '—',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: _CarDetailsScreenState._cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < specs.length; i++) ...[
              if (i > 0)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: _CarDetailsScreenState._divider,
                ),
              Expanded(child: specs[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: _CarDetailsScreenState._textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _CarDetailsScreenState._textSecondary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _CarDetailsScreenState._textPrimary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.features,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: _CarDetailsScreenState._textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _CarDetailsScreenState._cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: features
                .map(
                  (f) => Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _CarDetailsScreenState._background,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: _CarDetailsScreenState._textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          f,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _CarDetailsScreenState._textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _FullSpecsCard extends StatelessWidget {
  const _FullSpecsCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <MapEntry<String, String>>[
      MapEntry(l10n.specYear, data['year'] as String? ?? '—'),
      MapEntry(l10n.specType, data['bodyType'] as String? ?? '—'),
      MapEntry(l10n.specColor, data['color'] as String? ?? '—'),
      MapEntry(l10n.specEngine, data['engine'] as String? ?? '—'),
      MapEntry(l10n.specTransmission, data['transmission'] as String? ?? '—'),
      MapEntry(l10n.specMileage, data['mileage'] as String? ?? '—'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _CarDetailsScreenState._cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.technicalDetails,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _CarDetailsScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.key,
                      style: const TextStyle(
                        fontSize: 15,
                        color: _CarDetailsScreenState._textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _CarDetailsScreenState._textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerContactCard extends StatelessWidget {
  const _SellerContactCard({
    required this.data,
    required this.isSaved,
    required this.onSaveToggle,
    this.compact = false,
  });

  final Map<String, dynamic> data;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sellerName = data['sellerName'] as String? ?? l10n.sellerDefault;
    final showroom = data['sellerShowroom'] as String? ?? '';
    final avatarUrl = data['sellerAvatar'] as String? ?? '';
    final verified = data['sellerVerified'] as bool? ?? false;
    final listingsLabel = data['sellerListings'] as String? ?? '';

    return Container(
      padding: EdgeInsets.all(compact ? 0 : 28),
      decoration: compact
          ? null
          : BoxDecoration(
              color: _CarDetailsScreenState._cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Text(
              l10n.contactSeller,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _CarDetailsScreenState._textPrimary,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppCachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  memCacheLogicalWidth: 56,
                  memCacheLogicalHeight: 56,
                  errorWidget: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFE8E8ED),
                    child: const Icon(Icons.person_outline),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sellerName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: _CarDetailsScreenState._textPrimary,
                            ),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: _CarDetailsScreenState._accentBlue,
                          ),
                        ],
                      ],
                    ),
                    if (showroom.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        showroom,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _CarDetailsScreenState._textSecondary,
                        ),
                      ),
                    ],
                    if (listingsLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        listingsLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _CarDetailsScreenState._textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 16 : 28),
          _ContactButton(
            label: l10n.whatsapp,
            icon: const FaIcon(
              FontAwesomeIcons.whatsapp,
              size: 20,
              color: Colors.white,
            ),
            backgroundColor: _CarDetailsScreenState._whatsappGreen,
            foregroundColor: Colors.white,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          _ContactButton(
            label: l10n.phoneCall,
            icon: const Icon(Icons.phone, size: 20, color: Colors.white),
            backgroundColor: _CarDetailsScreenState._callBlack,
            foregroundColor: Colors.white,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          _ContactButton(
            label: isSaved ? l10n.removeFromWishlist : l10n.saveToWishlist,
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: _CarDetailsScreenState._textPrimary,
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: _CarDetailsScreenState._textPrimary,
            outlined: true,
            onPressed: onSaveToggle,
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatefulWidget {
  const _ContactButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final Widget icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  State<_ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<_ContactButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.outlined
        ? (_hovered ? const Color(0xFFF2F2F7) : Colors.transparent)
        : (widget.backgroundColor == _CarDetailsScreenState._callBlack &&
                _hovered
            ? const Color(0xFF333333)
            : widget.backgroundColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: widget.outlined
                ? Border.all(
                    color: const Color(0xFFD1D1D6),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon,
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
