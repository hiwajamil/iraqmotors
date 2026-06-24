import 'package:flutter/material.dart';

import 'package:iq_motors/shared/widgets/car_network_image.dart';

/// Compact saved-listing card for the user dashboard wishlist grid.
class WishlistCarCard extends StatefulWidget {
  const WishlistCarCard({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
    this.onTap,
    this.onRemove,
  });

  final String title;
  final String price;
  final String imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF86868B);
  static const Color accentRed = Color(0xFFFF3B30);

  @override
  State<WishlistCarCard> createState() => _WishlistCarCardState();
}

class _WishlistCarCardState extends State<WishlistCarCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WishlistCarCard.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CarNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF5F5F7),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.directions_car_outlined,
                            size: 40,
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _RemoveButton(onTap: widget.onRemove),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19.2,
                  fontWeight: FontWeight.w600,
                  color: WishlistCarCard.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.price,
                style: const TextStyle(
                  fontSize: 17.6,
                  fontWeight: FontWeight.w500,
                  color: WishlistCarCard.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            Icons.close,
            size: 18,
            color: WishlistCarCard.accentRed,
          ),
        ),
      ),
    );
  }
}
