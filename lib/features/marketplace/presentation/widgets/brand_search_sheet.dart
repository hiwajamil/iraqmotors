import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/data/dummy_brands.dart';
import 'package:iq_motors/shared/models/car_brand.dart';

/// Apple-style bottom sheet for browsing and filtering car brands.
class BrandSearchSheet extends StatefulWidget {
  const BrandSearchSheet({super.key});

  static Future<CarBrand?> show(BuildContext context) {
    return showModalBottomSheet<CarBrand>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BrandSearchSheet(),
    );
  }

  @override
  State<BrandSearchSheet> createState() => _BrandSearchSheetState();
}

class _BrandSearchSheetState extends State<BrandSearchSheet> {
  static const Color _background = Color(0xFFF5F5F7);
  static const Color _surface = Colors.white;
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _border = Color(0xFFE5E5EA);

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CarBrand> get _filteredBrands =>
      dummyBrands.where((b) => b.matchesQuery(_query)).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: const BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2D2D7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.brandTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SearchField(
                        hintText: l10n.brandSearchHint,
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: _filteredBrands.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            l10n.noBrandsFound,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: _textSecondary,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            20,
                            0,
                            20,
                            28,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: _filteredBrands.length,
                          itemBuilder: (context, index) {
                            final brand = _filteredBrands[index];
                            return _BrandGridTile(
                              brand: brand,
                              onTap: () => Navigator.of(context).pop(brand),
                            );
                          },
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _BrandSearchSheetState._surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _BrandSearchSheetState._border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontSize: 16,
          color: _BrandSearchSheetState._textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: _BrandSearchSheetState._textSecondary,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _BrandSearchSheetState._textSecondary,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _BrandGridTile extends StatefulWidget {
  const _BrandGridTile({
    required this.brand,
    required this.onTap,
  });

  final CarBrand brand;
  final VoidCallback onTap;

  @override
  State<_BrandGridTile> createState() => _BrandGridTileState();
}

class _BrandGridTileState extends State<_BrandGridTile> {
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
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: _BrandSearchSheetState._surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _BrandSearchSheetState._border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsetsDirectional.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: widget.brand.logoUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Center(
                      child: Text(
                        widget.brand.nameEnglish[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: _BrandSearchSheetState._textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.brand.displayName(lang),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: _BrandSearchSheetState._textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
