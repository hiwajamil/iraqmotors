import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/shared/widgets/app_cached_network_image.dart';

/// Seller contact card & sticky mobile bar widget.
class SellerContactCard extends StatelessWidget {
  const SellerContactCard({
    super.key,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final sellerName = data['sellerName'] as String? ?? l10n.sellerDefault;
    final showroom = data['sellerShowroom'] as String? ?? '';
    final avatarUrl = data['sellerAvatar'] as String? ?? '';
    final verified = data['sellerVerified'] as bool? ?? false;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AppCachedNetworkImage(
            imageUrl: avatarUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              width: 48,
              height: 48,
              color: colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.person_outline),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      sellerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (verified) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ],
              ),
              if (showroom.isNotEmpty)
                Text(
                  showroom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onSaveToggle,
          icon: Icon(
            isSaved ? Icons.favorite : Icons.favorite_border,
            color: isSaved ? colorScheme.error : colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () {},
          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
          label: const Text('Contact'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mobile sticky bottom seller contact bar.
class MobileSellerBar extends StatelessWidget {
  const MobileSellerBar({
    super.key,
    required this.data,
    required this.isSaved,
    required this.onSaveToggle,
  });

  final Map<String, dynamic> data;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SellerContactCard(
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
