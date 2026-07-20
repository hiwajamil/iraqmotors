import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/utils/bid_display.dart';
import 'package:iq_motors/core/utils/car_image_urls.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/app/providers/currency_provider.dart';
import 'package:iq_motors/features/marketplace/data/services/car_bid_service.dart';
import 'package:iq_motors/features/marketplace/data/services/car_database_service.dart';
import 'package:iq_motors/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/bid_input_dialog.dart';
import 'package:iq_motors/shared/widgets/car_network_image.dart';

/// Minimalist, high-conversion Material Design 3 (M3) car card.
/// Refactored for high signal-to-noise ratio, minimal cognitive load, and frictionless interaction.
class PremiumCarCard extends ConsumerStatefulWidget {
  const PremiumCarCard({
    super.key,
    required this.car,
    this.compact = false,
    this.onTap,
    this.onWishlistTap,
  });

  final Map<String, dynamic> car;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;

  @override
  ConsumerState<PremiumCarCard> createState() => _PremiumCarCardState();
}

class _PremiumCarCardState extends ConsumerState<PremiumCarCard> {
  /// Locally updated after a successful bid — avoids unnecessary live Firestore listeners.
  int? _optimisticHighestBid;

  String? get _carId => widget.car['id']?.toString();

  bool get _isWishlisted {
    final id = _carId;
    if (id == null || id.isEmpty) return false;
    return ref.watch(favoritesProvider.select((ids) => ids.contains(id)));
  }

  Map<String, dynamic>? get _bidOverlay {
    if (_optimisticHighestBid == null) return null;
    return {CarBidService.highestBidField: _optimisticHighestBid};
  }

  Map<String, dynamic> get _bidFirestoreData {
    final overlay = _bidOverlay;
    if (overlay == null) return widget.car;
    return {...widget.car, ...overlay};
  }

  Future<void> _onPlaceBidTap() async {
    if (widget.car['status']?.toString() == CarDatabaseService.statusSold) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Directive 2: Type & Color Restraint - Relying strictly on Theme.of(context)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final make = widget.car['make'] as String? ?? '';
    final model = widget.car['model'] as String? ?? '';
    final titleText = make.isEmpty ? model : '$make $model';
    final rawPriceStr = widget.car['price']?.toString() ?? '';
    final rawPriceNum = int.tryParse(rawPriceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final currencyMode = ref.watch(currencyModeProvider);
    final currencyService = ref.watch(currencyServiceProvider);

    final formattedPrice = rawPriceNum > 0
        ? currencyService.formatPrimary(rawPriceNum, currencyMode)
        : rawPriceStr;

    final secondaryPrice = rawPriceNum > 0
        ? currencyService.formatSecondary(rawPriceNum, currencyMode)
        : '';

    final imageUrl = carPrimaryImageUrl(widget.car);
    final isSold =
        widget.car['status']?.toString() == CarDatabaseService.statusSold;

    final latestBid = BidDisplay.highestBidLabel(
      car: widget.car,
      firestoreData: _bidFirestoreData,
    );

    // Directive 1: Eliminate Visual Noise - Removed heavy custom borders, complex box shadows,
    // and nested containers in favor of a clean, flat M3 surfaceContainerLow card structure.
    return RepaintBoundary(
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          // Fit grid cells with a fixed height: image flexes, footer stays intrinsic.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hasBoundedHeight = constraints.hasBoundedHeight &&
                  constraints.maxHeight.isFinite;

              final imageStack = Stack(
                fit: StackFit.expand,
                children: [
                  CarNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    cacheLogicalWidth: widget.compact ? 240 : 480,
                    errorBuilder: (_, __, ___) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.directions_car_outlined,
                        size: widget.compact ? 32 : 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isSold)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.soldBadgeLabel,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: widget.onWishlistTap,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            colorScheme.surface.withValues(alpha: 0.85),
                        foregroundColor: _isWishlisted
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                      icon: Icon(
                        _isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: widget.compact ? 18 : 20,
                      ),
                    ),
                  ),
                ],
              );

              final content = Padding(
                padding: EdgeInsets.fromLTRB(
                  widget.compact ? 10 : 16,
                  widget.compact ? 8 : 12,
                  widget.compact ? 10 : 16,
                  widget.compact ? 10 : 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (widget.compact
                              ? textTheme.titleSmall
                              : textTheme.titleLarge)
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: widget.compact ? 4 : 6),
                    Row(
                      children: [
                        if (formattedPrice.isNotEmpty)
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formattedPrice,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: (widget.compact
                                          ? textTheme.titleSmall
                                          : textTheme.titleMedium)
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                if (secondaryPrice.isNotEmpty && !widget.compact)
                                  Text(
                                    secondaryPrice,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (latestBid != null && latestBid.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              latestBid,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: widget.compact ? 8 : 16),
                    SizedBox(
                      width: double.infinity,
                      child: isSold
                          ? OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: Text(l10n.carSoldNoBids),
                            )
                          : FilledButton.icon(
                              onPressed: _onPlaceBidTap,
                              icon: const Icon(Icons.gavel_rounded, size: 18),
                              label: Text(l10n.placeYourBid),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                    ),
                  ],
                ),
              );

              if (hasBoundedHeight) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: imageStack),
                    content,
                  ],
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: widget.compact ? 16 / 10 : 16 / 9,
                    child: imageStack,
                  ),
                  content,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
