import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:iq_motors/shared/data/dummy_brands.dart';
import 'package:iq_motors/shared/models/car_brand.dart';
import 'package:iq_motors/features/marketplace/presentation/widgets/home/home_theme.dart';

/// Horizontally scrollable brand logos — logo above name.
class HomeBrandHorizontalStrip extends StatelessWidget {
  const HomeBrandHorizontalStrip({
    super.key,
    required this.isWide,
    required this.selectedBrandId,
    required this.onBrandSelected,
    required this.onViewAllTap,
  });

  final bool isWide;
  final String? selectedBrandId;
  final ValueChanged<CarBrand?> onBrandSelected;
  final VoidCallback onViewAllTap;

  static const Color _brandFill = Color(0xFFE8E8ED);
  static const Color _brandSelectedRing = Color(0xFF1D1D1F);

  double get _circleSize => isWide ? 88 : 70;
  double get _logoPadding => isWide ? 6 : 5;
  double get _stripHeight => isWide ? 160 : 118;
  double get _itemWidth => isWide ? 104 : 70;
  double get _itemSpacing => isWide ? 18 : 16;

  /// Clearbit Logo API — current high-quality marks from official domains.
  static String clearbitLogoUrl(CarBrand brand) {
    final host = _clearbitHosts[brand.id] ??
        '${brand.id.replaceAll('_', '-')}.com';
    return 'https://logo.clearbit.com/$host';
  }

  static const Map<String, String> _clearbitHosts = {
    'mercedes_benz': 'mercedes-benz.com',
    'land_rover': 'landrover.com',
    'gac_motor': 'gacgroup.com',
    'rolls_royce': 'rolls-roycemotorcars.com',
    'aston_martin': 'astonmartin.com',
    'alfa_romeo': 'alfaromeo.com',
    'great_wall': 'gwm-global.com',
    'li_auto': 'lixiang.com',
    'nio': 'nio.com',
    'xpeng': 'xiaopeng.com',
    'genesis': 'genesis.com',
    'mini': 'mini.com',
    'bentley': 'bentleymotors.com',
    'lamborghini': 'lamborghini.com',
    'maserati': 'maserati.com',
    'porsche': 'porsche.com',
  };

  @override
  Widget build(BuildContext context) {
    final brands = homeStripBrands;

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 12,
          children: [
            for (final brand in brands)
              _HomeBrandItem(
                brand: brand,
                circleSize: _circleSize,
                logoPadding: _logoPadding,
                itemWidth: _itemWidth,
                isSelected: selectedBrandId == brand.id,
                onTap: () {
                  final isSelected = selectedBrandId == brand.id;
                  onBrandSelected(isSelected ? null : brand);
                },
              ),
            _HomeBrandMoreChip(
              circleSize: _circleSize,
              itemWidth: _itemWidth,
              onTap: onViewAllTap,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: _stripHeight,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        itemCount: brands.length + 1,
        separatorBuilder: (context, index) => SizedBox(width: _itemSpacing),
        itemBuilder: (context, index) {
          if (index == brands.length) {
            return SizedBox(
              width: _itemWidth,
              height: _stripHeight,
              child: _HomeBrandMoreChip(
                circleSize: _circleSize,
                itemWidth: _itemWidth,
                onTap: onViewAllTap,
              ),
            );
          }

          final brand = brands[index];
          final isSelected = selectedBrandId == brand.id;
          return SizedBox(
            width: _itemWidth,
            height: _stripHeight,
            child: _HomeBrandItem(
              brand: brand,
              circleSize: _circleSize,
              logoPadding: _logoPadding,
              itemWidth: _itemWidth,
              isSelected: isSelected,
              onTap: () => onBrandSelected(isSelected ? null : brand),
            ),
          );
        },
      ),
    );
  }
}

class _HomeBrandLogoCircle extends StatelessWidget {
  const _HomeBrandLogoCircle({
    required this.brand,
    required this.fallbackLetter,
    required this.isSelected,
    required this.circleSize,
    required this.logoPadding,
  });

  final CarBrand brand;
  final String fallbackLetter;
  final bool isSelected;
  final double circleSize;
  final double logoPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: circleSize,
      height: circleSize,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.antiAlias,
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.1 : 0.05),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? HomeBrandHorizontalStrip._brandSelectedRing
                : HomeBrandHorizontalStrip._brandFill,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(logoPadding),
          child: ClipOval(
            child: SizedBox.expand(
              child: _HomeBrandLogoImage(
                brand: brand,
                fallbackLetter: fallbackLetter,
                circleSize: circleSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBrandLogoImage extends StatefulWidget {
  const _HomeBrandLogoImage({
    required this.brand,
    required this.fallbackLetter,
    required this.circleSize,
  });

  final CarBrand brand;
  final String fallbackLetter;
  final double circleSize;

  @override
  State<_HomeBrandLogoImage> createState() => _HomeBrandLogoImageState();
}

class _HomeBrandLogoImageState extends State<_HomeBrandLogoImage> {
  int _sourceIndex = 0;

  List<String> get _urls => [
        HomeBrandHorizontalStrip.clearbitLogoUrl(widget.brand),
        widget.brand.logoUrl,
      ];

  @override
  Widget build(BuildContext context) {
    final cacheExtent =
        (widget.circleSize * MediaQuery.devicePixelRatioOf(context)).round();

    return CachedNetworkImage(
      imageUrl: _urls[_sourceIndex],
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.high,
      memCacheWidth: cacheExtent,
      memCacheHeight: cacheExtent,
      placeholder: (_, __) => Center(
        child: SizedBox(
          width: widget.circleSize * 0.28,
          height: widget.circleSize * 0.28,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) {
        if (_sourceIndex < _urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _sourceIndex < _urls.length - 1) {
              setState(() => _sourceIndex++);
            }
          });
        }
        return _HomeBrandLogoLetterFallback(
          letter: widget.fallbackLetter,
          circleSize: widget.circleSize,
        );
      },
    );
  }
}

class _HomeBrandLogoLetterFallback extends StatelessWidget {
  const _HomeBrandLogoLetterFallback({
    required this.letter,
    required this.circleSize,
  });

  final String letter;
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontSize: circleSize * 0.36,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

class _HomeBrandItem extends StatefulWidget {
  const _HomeBrandItem({
    required this.brand,
    required this.circleSize,
    required this.logoPadding,
    required this.itemWidth,
    required this.isSelected,
    required this.onTap,
  });

  final CarBrand brand;
  final double circleSize;
  final double logoPadding;
  final double itemWidth;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_HomeBrandItem> createState() => _HomeBrandItemState();
}

class _HomeBrandItemState extends State<_HomeBrandItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: widget.itemWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: widget.circleSize,
                height: widget.circleSize,
                child: _HomeBrandLogoCircle(
                  brand: widget.brand,
                  fallbackLetter: widget.brand.nameEnglish[0].toUpperCase(),
                  isSelected: widget.isSelected,
                  circleSize: widget.circleSize,
                  logoPadding: widget.logoPadding,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: widget.itemWidth,
                child: Text(
                  widget.brand.displayName(lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isSelected
                        ? HomeScreenColors.textPrimary
                        : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBrandMoreChip extends StatefulWidget {
  const _HomeBrandMoreChip({
    required this.circleSize,
    required this.itemWidth,
    required this.onTap,
  });

  final double circleSize;
  final double itemWidth;
  final VoidCallback onTap;

  @override
  State<_HomeBrandMoreChip> createState() => _HomeBrandMoreChipState();
}

class _HomeBrandMoreChipState extends State<_HomeBrandMoreChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: widget.itemWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: widget.circleSize,
                height: widget.circleSize,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  width: widget.circleSize,
                  height: widget.circleSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: HomeBrandHorizontalStrip._brandFill,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: widget.circleSize * 0.4,
                      color: HomeScreenColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: widget.itemWidth,
                child: Text(
                  'زیاتر',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
