import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bid_display.dart';
import '../core/l10n_extensions.dart';
import '../l10n/app_localizations.dart';
import '../services/car_bid_service.dart';
import '../services/car_database_service.dart';
import '../widgets/bid_input_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    ));

    Future<void>.delayed(widget.animationDelay, () {
      if (mounted) _entryController.forward();
    });
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

  Future<void> _onPlaceBidTap() async {
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
      setState(() => _optimisticHighestBid = newBid);
    }
  }

  Widget _buildLatestBidRow(
    AppLocalizations l10n, {
    Map<String, dynamic>? firestoreData,
    required bool compact,
  }) {
    final latestBid = BidDisplay.latestBidLabel(
      car: widget.car,
      firestoreData: firestoreData,
    );
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
        SizedBox(height: compact ? 2 : 4),
        _buildLatestBidRow(l10n, firestoreData: _bidOverlay, compact: compact),
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
    final imageUrl = widget.car['imageUrl'] as String? ?? '';
    final isSold =
        widget.car['status']?.toString() == CarDatabaseService.statusSold;

    final cardRadius = compact ? 16.0 : 24.0;
    final outerPadding = compact ? 6.0 : 8.0;
    final imageGap = compact ? 8.0 : 20.0;
    final contentGap = compact ? 6.0 : 20.0;
    final hoverLift = compact ? 4.0 : 8.0;

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: widget.onTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            outerPadding,
                            outerPadding,
                            outerPadding,
                            0,
                          ),
                          child: _ImageContainer(
                            imageUrl: imageUrl,
                            isZoomed: _isActive,
                            isWishlisted: widget.isWishlisted,
                            wishlistHovered: _wishlistHovered,
                            compact: compact,
                            isSold: isSold,
                            onWishlistTap: widget.onWishlistTap,
                            onWishlistHover: (hovered) =>
                                setState(() => _wishlistHovered = hovered),
                          ),
                        ),
                        SizedBox(height: imageGap),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              outerPadding,
                              0,
                              outerPadding,
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
                                SizedBox(height: compact ? 4 : 8),
                                _buildPricingSection(l10n, compact: compact),
                                if (!compact) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.only(top: 16),
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
                                        const SizedBox(width: 20),
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
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: compact ? 6 : contentGap),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    outerPadding,
                    0,
                    outerPadding,
                    compact ? 4 : 6,
                  ),
                  child: _buildBidButton(l10n, compact: compact),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageContainer extends StatelessWidget {
  const _ImageContainer({
    required this.imageUrl,
    required this.isZoomed,
    required this.isWishlisted,
    required this.wishlistHovered,
    this.compact = false,
    this.isSold = false,
    this.onWishlistTap,
    this.onWishlistHover,
  });

  final String imageUrl;
  final bool isZoomed;
  final bool isWishlisted;
  final bool wishlistHovered;
  final bool compact;
  final bool isSold;
  final VoidCallback? onWishlistTap;
  final ValueChanged<bool>? onWishlistHover;

  @override
  Widget build(BuildContext context) {
    final imageRadius = compact ? 12.0 : 16.0;
    final wishlistInset = compact ? 8.0 : 15.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(imageRadius),
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
      children: [
        AnimatedScale(
          scale: isZoomed ? 1.08 : 1,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
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
        if (isSold)
          Positioned(
            top: wishlistInset,
            left: wishlistInset,
            child: _SoldBadge(compact: compact),
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

class _SoldBadge extends StatelessWidget {
  const _SoldBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final horizontal = compact ? 10.0 : 14.0;
    final vertical = compact ? 5.0 : 7.0;
    final fontSize = compact ? 9.0 : 12.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 10 : 14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(compact ? 10 : 14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            l10n.soldBadgeLabel,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: compact ? 0.4 : 0.6,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
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

    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AnimatedScale(
              scale: isHovered ? 1.1 : 1,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  size: iconSize,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BidButton extends StatefulWidget {
  const _BidButton({
    required this.label,
    this.compact = false,
    this.onTap,
  });

  final String label;
  final bool compact;
  final VoidCallback? onTap;

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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            decoration: BoxDecoration(
              color: _hovered
                  ? const Color(0xFF000000)
                  : PremiumCarCard.textPrimary,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _hovered ? 0.14 : 0.08),
                  blurRadius: _hovered ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.gavel_rounded,
                  size: iconSize,
                  color: Colors.white,
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
                      color: Colors.white,
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
