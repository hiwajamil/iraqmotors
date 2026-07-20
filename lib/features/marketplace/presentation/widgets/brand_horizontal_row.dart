import 'package:flutter/material.dart';

import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/shared/data/dummy_brands.dart';
import 'package:iq_motors/shared/models/car_brand.dart';
import 'package:iq_motors/shared/widgets/brand_logo_image.dart';

/// Horizontally scrollable brand logos for quick selection on home.
class BrandHorizontalRow extends StatelessWidget {
  const BrandHorizontalRow({
    super.key,
    required this.selectedBrandId,
    required this.onBrandSelected,
    this.onViewAllTap,
  });

  final String? selectedBrandId;
  final ValueChanged<CarBrand?> onBrandSelected;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
        itemCount: dummyBrands.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == dummyBrands.length) {
            return _ViewAllChip(onTap: onViewAllTap);
          }
          final brand = dummyBrands[index];
          final isSelected = selectedBrandId == brand.id;
          return _BrandChip(
            brand: brand,
            isSelected: isSelected,
            onTap: () {
              onBrandSelected(isSelected ? null : brand);
            },
          );
        },
      ),
    );
  }
}

class _BrandChip extends StatefulWidget {
  const _BrandChip({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  final CarBrand brand;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_BrandChip> createState() => _BrandChipState();
}

class _BrandChipState extends State<_BrandChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(
                        alpha: widget.isSelected ? 0.1 : 0.05,
                      ),
                      blurRadius: widget.isSelected ? 14 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: widget.isSelected
                        ? colorScheme.onSurface
                        : colorScheme.outlineVariant,
                    width: widget.isSelected ? 2 : 1,
                  ),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: BrandLogoImage(
                      brand: widget.brand,
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.brand.nameKurdish,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewAllChip extends StatelessWidget {
  const _ViewAllChip({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.apps_rounded,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'هەموو',
              style: context.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
