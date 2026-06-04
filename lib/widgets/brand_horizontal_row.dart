import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/dummy_brands.dart';
import '../models/car_brand.dart';

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

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _fill = Color(0xFFE8E8ED);
  static const Color _selectedRing = Color(0xFF1D1D1F);

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
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: widget.isSelected ? 0.1 : 0.05,
                      ),
                      blurRadius: widget.isSelected ? 14 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: widget.isSelected
                        ? BrandHorizontalRow._selectedRing
                        : BrandHorizontalRow._fill,
                    width: widget.isSelected ? 2 : 1,
                  ),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.brand.logoUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          widget.brand.nameEnglish[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: BrandHorizontalRow._textSecondary,
                          ),
                        ),
                      ),
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isSelected
                      ? BrandHorizontalRow._textPrimary
                      : BrandHorizontalRow._textSecondary,
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
                color: BrandHorizontalRow._fill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.apps_rounded,
                size: 22,
                color: BrandHorizontalRow._textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'هەموو',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: BrandHorizontalRow._textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
