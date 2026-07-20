import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/shared/widgets/car_network_image.dart';

import 'package:iq_motors/features/admin/domain/models/showroom_listing_status.dart';

/// Single car row for the showroom dashboard listings table.
class ShowroomCarListItem extends StatelessWidget {
  const ShowroomCarListItem({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.viewsLabel,
    required this.savesLabel,
    required this.status,
    required this.isMobile,
    this.latestBid,
    this.onEdit,
    this.onPrices,
    this.onMarkAsSold,
    this.onDelete,
    this.onToggleActive,
  });

  final String title;
  final String price;
  final String imageUrl;
  final String viewsLabel;
  final String savesLabel;
  final ShowroomListingStatus status;
  final bool isMobile;
  final String? latestBid;
  final VoidCallback? onEdit;
  final VoidCallback? onPrices;
  final VoidCallback? onMarkAsSold;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;

  bool get _isListingActive => status == ShowroomListingStatus.active;
  bool get _isSold => status == ShowroomListingStatus.sold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _CarDetailsRow(
            title: title,
            price: price,
            imageUrl: imageUrl,
            latestBid: latestBid,
            viewsLabel: viewsLabel,
            savesLabel: savesLabel,
            compact: isMobile,
          )),
          const SizedBox(width: 12),
          _CarActions(
            isActive: _isListingActive,
            isSold: _isSold,
            onToggleActive: onToggleActive,
            onEdit: onEdit,
            onPrices: onPrices,
            onMarkAsSold: onMarkAsSold,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CarDetailsRow extends StatelessWidget {
  const _CarDetailsRow({
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.viewsLabel,
    required this.savesLabel,
    required this.compact,
    this.latestBid,
  });

  final String title;
  final String price;
  final String imageUrl;
  final String viewsLabel;
  final String savesLabel;
  final bool compact;
  final String? latestBid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: compact ? 72 : 80,
            height: compact ? 54 : 60,
            child: CarNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              cacheLogicalWidth: compact ? 72 : 80,
              errorBuilder: (_, __, ___) => Container(
                width: compact ? 72 : 80,
                height: compact ? 54 : 60,
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 22,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: compact ? 3 : 2,
                child: _CarInfo(
                  title: title,
                  price: price,
                  latestBid: latestBid,
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 16),
                _CarStats(
                  viewsLabel: viewsLabel,
                  savesLabel: savesLabel,
                  horizontal: true,
                ),
              ],
            ],
          ),
        ),
        if (compact) ...[
          const SizedBox(width: 8),
          _CarStats(
            viewsLabel: viewsLabel,
            savesLabel: savesLabel,
            horizontal: false,
          ),
        ],
      ],
    );
  }
}

class _CarInfo extends StatelessWidget {
  const _CarInfo({
    required this.title,
    required this.price,
    this.latestBid,
  });

  final String title;
  final String price;
  final String? latestBid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.2,
          ),
        ),
        if (latestBid != null && latestBid!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _LatestBidChip(value: latestBid!),
        ],
      ],
    );
  }
}

class _LatestBidChip extends StatelessWidget {
  const _LatestBidChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.gavel_rounded,
            size: 12,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${context.l10n.latestBidLabel} ',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarStats extends StatelessWidget {
  const _CarStats({
    required this.viewsLabel,
    required this.savesLabel,
    required this.horizontal,
  });

  final String viewsLabel;
  final String savesLabel;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatLine(icon: Icons.visibility_outlined, label: viewsLabel),
          const SizedBox(width: 16),
          _StatLine(icon: Icons.favorite_border, label: savesLabel),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatLine(icon: Icons.visibility_outlined, label: viewsLabel),
        const SizedBox(height: 2),
        _StatLine(icon: Icons.favorite_border, label: savesLabel),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _CarActions extends StatelessWidget {
  const _CarActions({
    required this.isActive,
    required this.isSold,
    this.onToggleActive,
    this.onEdit,
    this.onPrices,
    this.onMarkAsSold,
    this.onDelete,
  });

  final bool isActive;
  final bool isSold;
  final VoidCallback? onToggleActive;
  final VoidCallback? onEdit;
  final VoidCallback? onPrices;
  final VoidCallback? onMarkAsSold;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isSold)
          _ActiveToggleButton(
            isActive: isActive,
            onTap: onToggleActive,
          ),
        if (!isSold) const SizedBox(width: 6),
        _IconActionButton(
          icon: Icons.edit_outlined,
          tooltip: context.l10n.editAction,
          onTap: onEdit,
        ),
        const SizedBox(width: 6),
        _IconActionButton(
          icon: Icons.gavel_rounded,
          tooltip: context.l10n.offersAction,
          onTap: onPrices,
          accentColor: colorScheme.primary,
        ),
        if (!isSold) ...[
          const SizedBox(width: 6),
          _IconActionButton(
            icon: Icons.sell_outlined,
            tooltip: context.l10n.soldAction,
            onTap: onMarkAsSold,
          ),
        ],
        const SizedBox(width: 6),
        _IconActionButton(
          icon: Icons.delete_outline,
          tooltip: context.l10n.deleteAction,
          onTap: onDelete,
          accentColor: colorScheme.error,
        ),
      ],
    );
  }
}

class _ActiveToggleButton extends StatefulWidget {
  const _ActiveToggleButton({
    required this.isActive,
    this.onTap,
  });

  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<_ActiveToggleButton> createState() => _ActiveToggleButtonState();
}

class _ActiveToggleButtonState extends State<_ActiveToggleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final active = widget.isActive;
    final bg = active
        ? colorScheme.tertiary.withValues(alpha: _hovered ? 0.22 : 0.14)
        : (_hovered
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHigh);
    final fg = active ? colorScheme.tertiary : colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: active ? context.l10n.adStatusActive : context.l10n.adStatusInactive,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: active
                  ? Border.all(
                      color: colorScheme.tertiary.withValues(alpha: 0.35),
                    )
                  : null,
            ),
            child: Icon(
              active ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
              size: 20,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatefulWidget {
  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final base = widget.accentColor ?? colorScheme.onSurfaceVariant;
    final color = _hovered ? colorScheme.onSurface : base;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(widget.icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
