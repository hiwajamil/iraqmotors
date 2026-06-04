import 'package:flutter/material.dart';

import '../models/showroom_listing_status.dart';

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
    this.onEdit,
    this.onView,
    this.onDelete,
  });

  final String title;
  final String price;
  final String imageUrl;
  final String viewsLabel;
  final String savesLabel;
  final ShowroomListingStatus status;
  final bool isMobile;
  final VoidCallback? onEdit;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textGray = Color(0xFF86868B);
  static const Color _statusActive = Color(0xFF34C759);
  static const Color _statusPending = Color(0xFFFF9F0A);
  static const Color _statusSold = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _CarBasicInfo(
                  title: title,
                  price: price,
                  imageUrl: imageUrl,
                ),
                const SizedBox(height: 15),
                _CarStats(
                  viewsLabel: viewsLabel,
                  savesLabel: savesLabel,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _StatusBadge(status: status),
                ),
              ],
            ),
            PositionedDirectional(
              top: 15,
              start: 0,
              child: _CarActions(
                status: status,
                onEdit: onEdit,
                onView: onView,
                onDelete: onDelete,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _CarBasicInfo(
              title: title,
              price: price,
              imageUrl: imageUrl,
            ),
          ),
          Expanded(
            flex: 1,
            child: _CarStats(
              viewsLabel: viewsLabel,
              savesLabel: savesLabel,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(child: _StatusBadge(status: status)),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _CarActions(
                status: status,
                onEdit: onEdit,
                onView: onView,
                onDelete: onDelete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarBasicInfo extends StatelessWidget {
  const _CarBasicInfo({
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  final String title;
  final String price;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 60,
              color: const Color(0xFFF5F5F7),
              alignment: Alignment.center,
              child: const Icon(
                Icons.directions_car_outlined,
                color: ShowroomCarListItem._textGray,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ShowroomCarListItem._textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 14,
                  color: ShowroomCarListItem._textGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CarStats extends StatelessWidget {
  const _CarStats({
    required this.viewsLabel,
    required this.savesLabel,
  });

  final String viewsLabel;
  final String savesLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatLine(icon: Icons.visibility_outlined, label: viewsLabel),
        const SizedBox(height: 4),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ShowroomCarListItem._textGray),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: ShowroomCarListItem._textGray,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ShowroomListingStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ShowroomListingStatus.active => (
          ShowroomCarListItem._statusActive.withValues(alpha: 0.1),
          ShowroomCarListItem._statusActive,
        ),
      ShowroomListingStatus.pending => (
          ShowroomCarListItem._statusPending.withValues(alpha: 0.1),
          ShowroomCarListItem._statusPending,
        ),
      ShowroomListingStatus.sold => (
          ShowroomCarListItem._statusSold.withValues(alpha: 0.1),
          ShowroomCarListItem._statusSold,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.labelKu,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _CarActions extends StatelessWidget {
  const _CarActions({
    required this.status,
    this.onEdit,
    this.onView,
    this.onDelete,
  });

  final ShowroomListingStatus status;
  final VoidCallback? onEdit;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconActionButton(
          icon: Icons.edit_outlined,
          tooltip: 'دەستکاریکردن',
          onTap: onEdit,
        ),
        const SizedBox(width: 15),
        if (status == ShowroomListingStatus.sold)
          _IconActionButton(
            icon: Icons.delete_outline,
            tooltip: 'سڕینەوە',
            onTap: onDelete,
          )
        else
          _IconActionButton(
            icon: Icons.visibility_outlined,
            tooltip: 'بینین',
            onTap: onView,
          ),
      ],
    );
  }
}

class _IconActionButton extends StatefulWidget {
  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered
        ? ShowroomCarListItem._textPrimary
        : ShowroomCarListItem._textGray;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Icon(widget.icon, size: 18, color: color),
        ),
      ),
    );
  }
}
