import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/utils/bid_display.dart';
import 'package:iq_motors/core/utils/car_image_urls.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/features/marketplace/data/services/car_bid_service.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/bid_input_dialog.dart';
import 'package:iq_motors/shared/widgets/car_network_image.dart';

/// Premium listing card matching the IQ Motors HTML prototype.
class PremiumCarCard extends ConsumerStatefulWidget {
  const PremiumCarCard({
    super.key,
    required this.car,
    this.compact = false,
    this.animationDelay = Duration.zero,
    this.onTap,
    this.onBidTap,
    this.onWishlistTap,
    this.isWishlisted = false,
  });

  final Map<String, dynamic> car;
  final bool compact;
  final Duration animationDelay;
  final VoidCallback? onTap;
  final VoidCallback? onBidTap;
  final VoidCallback? onWishlistTap;
  final bool isWishlisted;

  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF86868B);
  static const Color sellerPriceColor = Color(0xFF8E8E93);
  static const Color latestBidLabelColor = Color(0xFFFF3B30);
  static const Color latestBidValueColor = Color(0xFF1C1C1E);
  static const Color specsBorder = Color(0xFFF2F2F7);

  @override
  ConsumerState<PremiumCarCard> createState() => _PremiumCarCardState();
}

class _PremiumCarCardState extends ConsumerState<PremiumCarCard>
    with SingleTickerProviderStateMixin {
  static const _hoverCurve = Cubic(0.175, 0.885, 0.32, 1.275);

  bool _hovered = false;
  bool _pressed = false;
  bool _wishlistHovered = false;

  /// Locally updated after a successful bid — avoids live Firestore listeners.
  int? _optimisticHighestBid;

  late final AnimationController _entryController;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  bool get _useEntryAnimation => kIsWeb;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _useEntryAnimation ? 1000 : 1),
    );
    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entrySlide = Tween<Offset>(
      begin: Offset(0, _useEntryAnimation ? 0.08 : 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    ));

    if (_useEntryAnimation) {
      Future<void>.delayed(widget.animationDelay, () {
        if (mounted) _entryController.forward();
      });
    } else {
      _entryController.value = 1;
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  bool get _isActive => _hovered || _pressed;

  String? get _carId => widget.car['id']?.toString();

  Map<String, dynamic>? get _bidOverlay {
    if (_optimisticHighestBid == null) return null;
    return {CarBidService.highestBidField: _optimisticHighestBid};
  }

  /// Car document fields used for bid display (live stream + local optimistic).
  Map<String, dynamic> get _bidFirestoreData {
    final overlay = _bidOverlay;
    if (overlay == null) return widget.car;
    return {...widget.car, ...overlay};
  }

  Future<void> _onPlaceBidTap() async {
    if (widget.car['status']?.toString() == CarDatabaseService.statusSold) {
      return;
    }

    if (widget.onBidTap != null) {
      widget.onBidTap!();
      return;
    }

    final carId = _carId;
    if (carId == null || carId.isEmpty) return;

    final newBid = await BidInputDialog.show(
      context,
      carId: carId,
      car: widget.car,
    );
    if (newBid != null && mounted) {
      final currentHighest = BidDisplay.highestBidAmount(
        car: widget.car,
        firestoreData: _bidFirestoreData,
      );
      if (newBid > currentHighest) {
        setState(() => _optimisticHighestBid = newBid);
      }
    }
  }

  Widget? _buildLatestBidRow(
    AppLocalizations l10n, {
    required bool compact,
  }) {
    final latestBid = BidDisplay.highestBidLabel(
      car: widget.car,
      firestoreData: _bidFirestoreData,
    );
    if (latestBid == null || latestBid.isEmpty) return null;

    final labelSize = compact ? 8.0 : 14.0;
    final valueSize = compact ? 10.0 : 18.0;

    final bidRow = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${l10n.latestBidLabel} ',
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: PremiumCarCard.latestBidLabelColor,
              height: 1.2,
            ),
          ),
          TextSpan(
            text: latestBid,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
              color: PremiumCarCard.latestBidValueColor,
              height: 1.2,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!compact) return bidRow;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: bidRow,
    );
  }

  Widget _buildBidButton(AppLocalizations l10n, {required bool compact}) {
    final isSold =
        widget.car['status']?.toString() == CarDatabaseService.statusSold;
    if (isSold) {
      return _BidButton(
        label: l10n.carSoldNoBids,
        compact: compact,
        enabled: false,
      );
    }

    return _BidButton(
      label: l10n.placeYourBid,
      compact: compact,
      onTap: _onPlaceBidTap,
    );
  }

  Widget _buildPricingSection(AppLocalizations l10n, {required bool compact}) {
    final price = widget.car['price'] as String? ?? '';
    final priceSize = compact ? 8.0 : 12.5;

    final sellerPriceRow = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${l10n.sellerPriceLabel} ',
            style: TextStyle(
              fontSize: priceSize,
              fontWeight: FontWeight.w500,
              color: PremiumCarCard.sellerPriceColor,
              height: 1.2,
            ),
          ),
          TextSpan(
            text: price,
            style: TextStyle(
              fontSize: priceSize,
              fontWeight: FontWeight.w500,
              color: PremiumCarCard.sellerPriceColor,
              height: 1.2,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        compact
            ? FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: sellerPriceRow,
              )
            : sellerPriceRow,
        if (_buildLatestBidRow(l10n, compact: compact) case final bidRow?) ...[
          SizedBox(height: compact ? 2 : 4),
          bidRow,
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = widget.compact;
    final make = widget.car['make'] as String? ?? '';
    final model = widget.car['model'] as String? ?? '';
    final engine = widget.car['engine'] as String? ?? '';
    final mileage = widget.car['mileage'] as String? ?? '';
    final imageUrl = carPrimaryImageUrl(widget.car);
    final isSold =
        widget.car['status']?.toString() == CarDatabaseService.statusSold;

    const cardRadius = 12.0;
    final contentPadding = compact ? 6.0 : 12.0;
    final imageTextGap = compact ? 6.0 : 12.0;
    const buttonGap = 16.0;
    const bottomPadding = 2.0;
    final hoverLift = compact ? 4.0 : 8.0;

    final card = MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: _hoverCurve,
            transform: Matrix4.translationValues(0, _isActive ? -hoverLift : 0, 0),
            decoration: BoxDecoration(
              color: PremiumCarCard.cardWhite,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.02),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isActive ? 0.08 : 0.03,
                  ),
                  blurRadius: _isActive ? (compact ? 24 : 40) : (compact ? 12 : 20),
                  offset: Offset(0, _isActive ? (compact ? 8 : 16) : (compact ? 2 : 4)),
                ),
              ],
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: widget.onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImageContainer(
                    imageUrl: imageUrl,
                    cardRadius: cardRadius,
                    isZoomed: _isActive,
                    isWishlisted: widget.isWishlisted,
                    wishlistHovered: _wishlistHovered,
                    compact: compact,
                    isSold: isSold,
                    onWishlistTap: widget.onWishlistTap,
                    onWishlistHover: (hovered) =>
                        setState(() => _wishlistHovered = hovered),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      contentPadding,
                      imageTextGap,
                      contentPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          make.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 8 : 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: compact ? 0.6 : 1,
                            color: PremiumCarCard.textSecondary,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        Text(
                          model,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 12 : 22.4,
                            fontWeight: FontWeight.w600,
                            color: PremiumCarCard.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        _buildPricingSection(l10n, compact: compact),
                        if (!compact) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.only(top: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: PremiumCarCard.specsBorder,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                _SpecColumn(
                                  label: l10n.specEngine,
                                  value: engine,
                                ),
                                const SizedBox(width: 16),
                                _SpecColumn(
                                  label: l10n.specMileage,
                                  value: mileage,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: buttonGap),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      contentPadding,
                      0,
                      contentPadding,
                      bottomPadding,
                    ),
                    child: _buildBidButton(l10n, compact: compact),
                  ),
                ],
              ),
            ),
          ),
        ),
    );

    if (!_useEntryAnimation) {
      return RepaintBoundary(child: card);
    }

    return RepaintBoundary(
      child: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: card,
        ),
      ),
    );
  }
}

class _ImageContainer extends StatelessWidget {
  const _ImageContainer({
    required this.imageUrl,
    required this.cardRadius,
    required this.isZoomed,
    required this.isWishlisted,
    required this.wishlistHovered,
    this.compact = false,
    this.isSold = false,
    this.onWishlistTap,
    this.onWishlistHover,
  });

  final String imageUrl;
  final double cardRadius;
  final bool isZoomed;
  final bool isWishlisted;
  final bool wishlistHovered;
  final bool compact;
  final bool isSold;
  final VoidCallback? onWishlistTap;
  final ValueChanged<bool>? onWishlistHover;

  @override
  Widget build(BuildContext context) {
    final wishlistInset = compact ? 8.0 : 12.0;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(cardRadius),
        topRight: Radius.circular(cardRadius),
      ),
      child: compact
          ? AspectRatio(
              aspectRatio: 1.35,
              child: _buildImageStack(wishlistInset),
            )
          : SizedBox(
              height: 220,
              width: double.infinity,
              child: _buildImageStack(wishlistInset),
            ),
    );
  }

  Widget _buildImageStack(double wishlistInset) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: AnimatedScale(
            scale: isZoomed && !isSold ? 1.08 : 1,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            child: CarNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              cacheLogicalWidth: compact ? 180 : 360,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF5F5F7),
                alignment: Alignment.center,
                child: Icon(
                  Icons.directions_car_outlined,
                  size: compact ? 28 : 48,
                  color: Colors.black.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
        ),
        if (isSold)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
              ),
            ),
          ),
        if (isSold)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SoldBottomBanner(compact: compact),
          ),
        Positioned(
          top: wishlistInset,
          right: wishlistInset,
          child: _WishlistButton(
            isWishlisted: isWishlisted,
            isHovered: wishlistHovered,
            compact: compact,
            onTap: onWishlistTap,
            onHover: onWishlistHover,
          ),
        ),
      ],
    );
  }
}

class _SoldBottomBanner extends StatelessWidget {
  const _SoldBottomBanner({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fontSize = compact ? 11.0 : 14.0;
    final vertical = compact ? 8.0 : 12.0;

    final banner = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: vertical),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1B5E20).withValues(alpha: 0.72),
            const Color(0xFF1B5E20).withValues(alpha: 0.92),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.22),
            width: 0.8,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: compact ? 14 : 18,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            l10n.soldBadgeLabel,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: compact ? 0.8 : 1.2,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    if (kIsWeb) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: banner,
        ),
      );
    }
    return banner;
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({
    required this.isWishlisted,
    required this.isHovered,
    this.compact = false,
    this.onTap,
    this.onHover,
  });

  final bool isWishlisted;
  final bool isHovered;
  final bool compact;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHover;

  @override
  Widget build(BuildContext context) {
    final color = isWishlisted || isHovered
        ? const Color(0xFFFF3B30)
        : const Color(0xFF86868B);
    final size = compact ? 28.0 : 36.0;
    final iconSize = compact ? 14.0 : 18.0;

    final button = GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isHovered ? 1.1 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: kIsWeb ? 0.9 : 0.95),
            shape: BoxShape.circle,
            boxShadow: kIsWeb
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Icon(
            isWishlisted ? Icons.favorite : Icons.favorite_border,
            size: iconSize,
            color: color,
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: kIsWeb
          ? ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: button,
              ),
            )
          : button,
    );
  }
}

class _BidButton extends StatefulWidget {
  const _BidButton({
    required this.label,
    this.compact = false,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool compact;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<_BidButton> createState() => _BidButtonState();
}

class _BidButtonState extends State<_BidButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final verticalPadding = compact ? 5.0 : 12.0;
    final horizontalPadding = compact ? 6.0 : 0.0;
    final fontSize = compact ? 9.0 : 14.0;
    final iconSize = compact ? 12.0 : 16.0;
    final borderRadius = compact ? 10.0 : 16.0;
    final iconGap = compact ? 4.0 : 8.0;

    final backgroundColor = !widget.enabled
        ? const Color(0xFFE5E5EA)
        : _hovered
            ? const Color(0xFF000000)
            : PremiumCarCard.textPrimary;
    final foregroundColor =
        widget.enabled ? Colors.white : const Color(0xFF86868B);

    return MouseRegion(
      onEnter: widget.enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.enabled ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed && widget.enabled ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: _hovered ? 0.14 : 0.08),
                        blurRadius: _hovered ? 12 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.enabled ? Icons.gavel_rounded : Icons.block_rounded,
                  size: iconSize,
                  color: foregroundColor,
                ),
                SizedBox(width: iconGap),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: foregroundColor,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecColumn extends StatelessWidget {
  const _SpecColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: PremiumCarCard.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: PremiumCarCard.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
