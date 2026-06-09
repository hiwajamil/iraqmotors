import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bid_display.dart';
import '../core/l10n_extensions.dart';
import '../l10n/app_localizations.dart';
import '../services/car_bid_service.dart';
import '../widgets/bid_input_dialog.dart';

/// Premium listing card matching the IQ Motors HTML prototype.
class PremiumCarCard extends ConsumerStatefulWidget {
  const PremiumCarCard({
    super.key,
    required this.car,
    this.animationDelay = Duration.zero,
    this.onTap,
    this.onBidTap,
    this.onWishlistTap,
    this.isWishlisted = false,
  });

  final Map<String, dynamic> car;
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

    final newBid = await BidInputDialog.show(context, carId: carId);
    if (newBid != null && mounted) {
      setState(() => _optimisticHighestBid = newBid);
    }
  }

  Widget _buildLatestBidRow(
    AppLocalizations l10n, {
    Map<String, dynamic>? firestoreData,
  }) {
    final latestBid = BidDisplay.latestBidLabel(
      car: widget.car,
      firestoreData: firestoreData,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${l10n.latestBidLabel} ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: PremiumCarCard.latestBidLabelColor,
              height: 1.3,
            ),
          ),
          TextSpan(
            text: latestBid,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PremiumCarCard.latestBidValueColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidButton(AppLocalizations l10n) {
    return _BidButton(
      label: l10n.placeYourBid,
      onTap: _onPlaceBidTap,
    );
  }

  Widget _buildPricingSection(AppLocalizations l10n) {
    final price = widget.car['price'] as String? ?? '';

    final sellerPriceRow = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${l10n.sellerPriceLabel} ',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: PremiumCarCard.sellerPriceColor,
              height: 1.3,
            ),
          ),
          TextSpan(
            text: price,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: PremiumCarCard.sellerPriceColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sellerPriceRow,
        const SizedBox(height: 4),
        _buildLatestBidRow(l10n, firestoreData: _bidOverlay),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final make = widget.car['make'] as String? ?? '';
    final model = widget.car['model'] as String? ?? '';
    final engine = widget.car['engine'] as String? ?? '';
    final mileage = widget.car['mileage'] as String? ?? '';
    final imageUrl = widget.car['imageUrl'] as String? ?? '';

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
            transform: Matrix4.translationValues(0, _isActive ? -8 : 0, 0),
            decoration: BoxDecoration(
              color: PremiumCarCard.cardWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.02),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isActive ? 0.08 : 0.03,
                  ),
                  blurRadius: _isActive ? 40 : 20,
                  offset: Offset(0, _isActive ? 16 : 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTap: widget.onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
                        child: _ImageContainer(
                          imageUrl: imageUrl,
                          isZoomed: _isActive,
                          isWishlisted: widget.isWishlisted,
                          wishlistHovered: _wishlistHovered,
                          onWishlistTap: widget.onWishlistTap,
                          onWishlistHover: (hovered) =>
                              setState(() => _wishlistHovered = hovered),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              make.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: PremiumCarCard.textSecondary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              model,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22.4,
                                fontWeight: FontWeight.w600,
                                color: PremiumCarCard.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPricingSection(l10n),
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
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 6),
                  child: _buildBidButton(l10n),
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
    this.onWishlistTap,
    this.onWishlistHover,
  });

  final String imageUrl;
  final bool isZoomed;
  final bool isWishlisted;
  final bool wishlistHovered;
  final VoidCallback? onWishlistTap;
  final ValueChanged<bool>? onWishlistHover;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
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
                    size: 48,
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 15,
              right: 15,
              child: _WishlistButton(
                isWishlisted: isWishlisted,
                isHovered: wishlistHovered,
                onTap: onWishlistTap,
                onHover: onWishlistHover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({
    required this.isWishlisted,
    required this.isHovered,
    this.onTap,
    this.onHover,
  });

  final bool isWishlisted;
  final bool isHovered;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHover;

  @override
  Widget build(BuildContext context) {
    final color = isWishlisted || isHovered
        ? const Color(0xFFFF3B30)
        : const Color(0xFF86868B);

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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  size: 18,
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
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  State<_BidButton> createState() => _BidButtonState();
}

class _BidButtonState extends State<_BidButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _hovered
                  ? const Color(0xFF000000)
                  : PremiumCarCard.textPrimary,
              borderRadius: BorderRadius.circular(16),
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
                const Icon(
                  Icons.gavel_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: Colors.white,
                    height: 1.2,
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
