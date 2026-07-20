import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/theme/app_theme.dart';
import 'package:iq_motors/shared/widgets/car_network_image.dart';

/// Single car row for the regular user dashboard "My Ads" list.
class UserCarListItem extends StatelessWidget {
  const UserCarListItem({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.isMobile,
    required this.isDraft,
    required this.isSold,
    required this.isActive,
    required this.canToggleActive,
    this.latestBidLabel,
    this.postedLabel,
    this.daysRemainingLabel,
    this.draftLabel,
    this.onEdit,
    this.onPrices,
    this.onMarkAsSold,
    this.onDelete,
    this.onToggleActive,
  });

  static const double _mobileBreakpoint = 600;

  final String title;
  final String price;
  final String imageUrl;
  final bool isMobile;
  final bool isDraft;
  final bool isSold;
  final bool isActive;
  final bool canToggleActive;
  final String? latestBidLabel;
  final String? postedLabel;
  final String? daysRemainingLabel;
  final String? draftLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onPrices;
  final VoidCallback? onMarkAsSold;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useMobileLayout = constraints.maxWidth < _mobileBreakpoint;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: useMobileLayout ? 16 : 8),
          child: useMobileLayout
              ? _MobileCarListItem(
                  title: title,
                  price: price,
                  imageUrl: imageUrl,
                  isDraft: isDraft,
                  isSold: isSold,
                  isActive: isActive,
                  canToggleActive: canToggleActive,
                  latestBidLabel: isDraft ? null : latestBidLabel,
                  postedLabel: postedLabel,
                  daysRemainingLabel: isDraft ? null : daysRemainingLabel,
                  draftLabel: draftLabel,
                  onEdit: onEdit,
                  onPrices: onPrices,
                  onMarkAsSold: onMarkAsSold,
                  onDelete: onDelete,
                  onToggleActive: onToggleActive,
                )
              : _DesktopCarListItem(
                  title: title,
                  price: price,
                  imageUrl: imageUrl,
                  isDraft: isDraft,
                  isSold: isSold,
                  isActive: isActive,
                  canToggleActive: canToggleActive,
                  latestBidLabel: isDraft ? null : latestBidLabel,
                  postedLabel: postedLabel,
                  daysRemainingLabel: isDraft ? null : daysRemainingLabel,
                  draftLabel: draftLabel,
                  onEdit: onEdit,
                  onPrices: onPrices,
                  onMarkAsSold: onMarkAsSold,
                  onDelete: onDelete,
                  onToggleActive: onToggleActive,
                ),
        );
      },
    );
  }
}

class _DesktopCarListItem extends StatelessWidget {
  const _DesktopCarListItem({
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.isDraft,
    required this.isSold,
    required this.isActive,
    required this.canToggleActive,
    this.latestBidLabel,
    this.postedLabel,
    this.daysRemainingLabel,
    this.draftLabel,
    this.onEdit,
    this.onPrices,
    this.onMarkAsSold,
    this.onDelete,
    this.onToggleActive,
  });

  final String title;
  final String price;
  final String imageUrl;
  final bool isDraft;
  final bool isSold;
  final bool isActive;
  final bool canToggleActive;
  final String? latestBidLabel;
  final String? postedLabel;
  final String? daysRemainingLabel;
  final String? draftLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onPrices;
  final VoidCallback? onMarkAsSold;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: isDraft ? onEdit : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CarThumbnail(
                  imageUrl: imageUrl,
                  isDraft: isDraft,
                  draftLabel: draftLabel,
                  width: 80,
                  height: 60,
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _CarInfo(
                    title: title,
                    price: price,
                    latestBidLabel: latestBidLabel,
                    titleMaxLines: 1,
                  ),
                ),
                if (postedLabel != null || daysRemainingLabel != null) ...[
                  const SizedBox(width: 16),
                  Flexible(
                    flex: 2,
                    child: _AdMeta(
                      postedLabel: postedLabel,
                      daysRemainingLabel: daysRemainingLabel,
                      layout: _AdMetaLayout.inline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CarActions(
          isDraft: isDraft,
          isActive: isActive,
          isSold: isSold,
          canToggleActive: canToggleActive,
          scrollable: false,
          onToggleActive: onToggleActive,
          onEdit: onEdit,
          onPrices: onPrices,
          onMarkAsSold: onMarkAsSold,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _MobileCarListItem extends StatelessWidget {
  const _MobileCarListItem({
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.isDraft,
    required this.isSold,
    required this.isActive,
    required this.canToggleActive,
    this.latestBidLabel,
    this.postedLabel,
    this.daysRemainingLabel,
    this.draftLabel,
    this.onEdit,
    this.onPrices,
    this.onMarkAsSold,
    this.onDelete,
    this.onToggleActive,
  });

  final String title;
  final String price;
  final String imageUrl;
  final bool isDraft;
  final bool isSold;
  final bool isActive;
  final bool canToggleActive;
  final String? latestBidLabel;
  final String? postedLabel;
  final String? daysRemainingLabel;
  final String? draftLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onPrices;
  final VoidCallback? onMarkAsSold;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final hasMeta = postedLabel != null || daysRemainingLabel != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: isDraft ? onEdit : null,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CarThumbnail(
                imageUrl: imageUrl,
                isDraft: isDraft,
                draftLabel: draftLabel,
                width: 88,
                height: 66,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CarInfo(
                  title: title,
                  price: price,
                  latestBidLabel: latestBidLabel,
                  titleMaxLines: 2,
                ),
              ),
            ],
          ),
        ),
        if (hasMeta) ...[
          const SizedBox(height: 12),
          _AdMeta(
            postedLabel: postedLabel,
            daysRemainingLabel: daysRemainingLabel,
            layout: _AdMetaLayout.stacked,
          ),
        ],
        const SizedBox(height: 16),
        _CarActions(
          isDraft: isDraft,
          isActive: isActive,
          isSold: isSold,
          canToggleActive: canToggleActive,
          scrollable: true,
          onToggleActive: onToggleActive,
          onEdit: onEdit,
          onPrices: onPrices,
          onMarkAsSold: onMarkAsSold,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _CarThumbnail extends StatelessWidget {
  const _CarThumbnail({
    required this.imageUrl,
    required this.isDraft,
    required this.width,
    required this.height,
    this.draftLabel,
  });

  final String imageUrl;
  final bool isDraft;
  final double width;
  final double height;
  final String? draftLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: width,
            height: height,
            child: CarNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              cacheLogicalWidth: width,
              errorBuilder: (_, __, ___) => Container(
                width: width,
                height: height,
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 24,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        if (isDraft) ...[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColoredBox(
                color: colorScheme.secondary.withValues(alpha: 0.08),
              ),
            ),
          ),
          if (draftLabel != null)
            PositionedDirectional(
              top: -6,
              start: -4,
              child: _DraftBadge(label: draftLabel!),
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
    required this.titleMaxLines,
    this.latestBidLabel,
  });

  final String title;
  final String price;
  final int titleMaxLines;
  final String? latestBidLabel;

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
          maxLines: titleMaxLines,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.2,
          ),
        ),
        if (latestBidLabel != null && latestBidLabel!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _LatestBidChip(
              label: context.l10n.latestBidLabel,
              value: latestBidLabel!,
            ),
          ),
        ],
      ],
    );
  }
}

class _LatestBidChip extends StatelessWidget {
  const _LatestBidChip({required this.label, required this.value});

  final String label;
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
                    text: '$label ',
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

enum _AdMetaLayout { inline, stacked }

class _AdMeta extends StatelessWidget {
  const _AdMeta({
    required this.layout,
    this.postedLabel,
    this.daysRemainingLabel,
  });

  final _AdMetaLayout layout;
  final String? postedLabel;
  final String? daysRemainingLabel;

  @override
  Widget build(BuildContext context) {
    if (postedLabel == null && daysRemainingLabel == null) {
      return const SizedBox.shrink();
    }

    final posted = postedLabel != null
        ? _MetaLine(icon: Icons.calendar_today_outlined, label: postedLabel!)
        : null;
    final remaining = daysRemainingLabel != null
        ? _MetaLine(icon: Icons.schedule_outlined, label: daysRemainingLabel!)
        : null;

    if (layout == _AdMetaLayout.stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (posted != null) posted,
          if (posted != null && remaining != null) const SizedBox(height: 6),
          if (remaining != null) remaining,
        ],
      );
    }

    return Row(
      children: [
        if (posted != null) Flexible(child: posted),
        if (posted != null && remaining != null) const SizedBox(width: 16),
        if (remaining != null) Flexible(child: remaining),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.label});

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
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _CarActions extends StatelessWidget {
  const _CarActions({
    required this.isDraft,
    required this.isActive,
    required this.isSold,
    required this.canToggleActive,
    required this.scrollable,
    this.onToggleActive,
    this.onEdit,
    this.onPrices,
    this.onMarkAsSold,
    this.onDelete,
  });

  final bool isDraft;
  final bool isActive;
  final bool isSold;
  final bool canToggleActive;
  final bool scrollable;
  final VoidCallback? onToggleActive;
  final VoidCallback? onEdit;
  final VoidCallback? onPrices;
  final VoidCallback? onMarkAsSold;
  final VoidCallback? onDelete;

  List<Widget> _buildButtons(BuildContext context) {
    final colorScheme = context.colorScheme;
    final buttons = <Widget>[
      if (canToggleActive) ...[
        _ActiveToggleButton(
          isActive: isActive,
          onTap: onToggleActive,
        ),
        const SizedBox(width: 8),
      ],
      _IconActionButton(
        icon: isDraft ? Icons.play_arrow_rounded : Icons.edit_outlined,
        tooltip: isDraft ? context.l10n.adCompleteDraft : context.l10n.editAction,
        onTap: onEdit,
        accentColor: isDraft ? colorScheme.secondary : null,
      ),
      if (!isDraft) ...[
        const SizedBox(width: 8),
        _IconActionButton(
          icon: Icons.gavel_rounded,
          tooltip: context.l10n.offersAction,
          onTap: onPrices,
          accentColor: colorScheme.primary,
        ),
        if (!isSold) ...[
          const SizedBox(width: 8),
          _IconActionButton(
            icon: Icons.sell_outlined,
            tooltip: context.l10n.soldAction,
            onTap: onMarkAsSold,
          ),
        ],
      ],
      const SizedBox(width: 8),
      _IconActionButton(
        icon: Icons.delete_outline,
        tooltip: context.l10n.deleteAction,
        onTap: onDelete,
        accentColor: colorScheme.error,
      ),
    ];

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    final buttons = _buildButtons(context);

    if (!scrollable) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        clipBehavior: Clip.none,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: buttons,
        ),
      ),
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

class _DraftBadge extends StatelessWidget {
  const _DraftBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSecondary,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
