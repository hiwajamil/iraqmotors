import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/core/platform/picked_image_preview.dart';
import 'package:iq_motors/features/listings/domain/models/add_car_draft.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_form_card.dart';
import 'package:iq_motors/features/listings/presentation/widgets/add_car_step_header.dart';

bool _isFilledPhotoSlot(String? path) =>
    path != null && path.trim().isNotEmpty;

const double _photoGridSpacing = 10;
const double _photoTileMinSize = 96;
const double _photoTileMaxSize = 120;

int _photoGridCrossAxisCount(double maxWidth) {
  for (var cols = 5; cols >= 3; cols--) {
    final tile =
        (maxWidth - _photoGridSpacing * (cols - 1)) / cols;
    if (tile <= _photoTileMaxSize) return cols;
  }
  return 3;
}

double _photoTileSize(double maxWidth, int crossAxisCount) {
  final tile = (maxWidth - _photoGridSpacing * (crossAxisCount - 1)) /
      crossAxisCount;
  return tile.clamp(_photoTileMinSize, _photoTileMaxSize);
}

/// Step 2 — photo grid.
class AddCarStepPhotos extends StatelessWidget {
  const AddCarStepPhotos({
    super.key,
    required this.photos,
    required this.onPhotoSlotTapped,
    this.onPhotoRemoved,
    this.uploadingSlots = const {},
    this.previewBytesBySlot = const {},
  });

  final List<String?> photos;
  final ValueChanged<int> onPhotoSlotTapped;
  final ValueChanged<int>? onPhotoRemoved;
  final Set<int> uploadingSlots;
  final Map<int, Uint8List> previewBytesBySlot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slots = photos.length >= AddCarDraft.photoSlotCount
        ? photos
        : [
            ...photos,
            ...List<String?>.filled(
              AddCarDraft.photoSlotCount - photos.length,
              null,
            ),
          ];

    final filledCount = slots.where(_isFilledPhotoSlot).length;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddCarStepHeader(
            title: l10n.addCarPhotosHeading,
            subtitle: l10n.addCarPhotosSubtitle,
            trailing: Text(
              '$filledCount / ${AddCarDraft.minPhotoCount}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: filledCount >= AddCarDraft.minPhotoCount
                    ? AddCarTheme.successGreen
                    : AddCarTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AddCarFormCard(
            padding: const EdgeInsetsDirectional.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    _photoGridCrossAxisCount(constraints.maxWidth);
                final tileSize =
                    _photoTileSize(constraints.maxWidth, crossAxisCount);

                return Wrap(
                  spacing: _photoGridSpacing,
                  runSpacing: _photoGridSpacing,
                  children: [
                    for (var index = 0;
                        index < AddCarDraft.photoSlotCount;
                        index++)
                      SizedBox(
                        width: tileSize,
                        height: tileSize,
                        child: _PhotoSlot(
                          index: index,
                          photoPath: slots[index],
                          previewBytes: previewBytesBySlot[index],
                          hasPhoto: _isFilledPhotoSlot(slots[index]),
                          isUploading: uploadingSlots.contains(index),
                          enabled: !uploadingSlots.contains(index),
                          onTap: () => onPhotoSlotTapped(index),
                          onRemove: _isFilledPhotoSlot(slots[index]) &&
                                  onPhotoRemoved != null
                              ? () => onPhotoRemoved!(index)
                              : null,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatefulWidget {
  const _PhotoSlot({
    required this.index,
    required this.photoPath,
    this.previewBytes,
    required this.hasPhoto,
    required this.isUploading,
    required this.enabled,
    required this.onTap,
    this.onRemove,
  });

  final int index;
  final String? photoPath;
  final Uint8List? previewBytes;
  final bool hasPhoto;
  final bool isUploading;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  State<_PhotoSlot> createState() => _PhotoSlotState();
}

class _PhotoSlotState extends State<_PhotoSlot> {
  bool _pressed = false;

  static const double _radius = 12;

  bool get _isRemoteUrl =>
      widget.photoPath != null &&
      AddCarDraft.isRemoteImageUrl(widget.photoPath!.trim());

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildSlotBackground(),
                if (widget.isUploading) _buildUploadingOverlay(),
                if (widget.hasPhoto && !widget.isUploading) _buildDeleteButton(),
                _buildBorderOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotBackground() {
    if (widget.isUploading) {
      return const ColoredBox(color: AddCarTheme.inputFill);
    }

    if (!widget.hasPhoto) {
      return ColoredBox(
        color: AddCarTheme.inputFill,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 24,
              color: AddCarTheme.textSecondary.withValues(
                alpha: _pressed ? 1 : 0.85,
              ),
            ),
            if (widget.index == 0) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.addCarPhotoPrimary,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AddCarTheme.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final path = widget.photoPath!.trim();

    if (_isRemoteUrl) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.previewBytes != null && widget.previewBytes!.isNotEmpty)
            Image.memory(
              widget.previewBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
            ),
          Image.network(
            path,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              if (widget.previewBytes != null && widget.previewBytes!.isNotEmpty) {
                return const SizedBox.shrink();
              }
              return _buildImageLoadingState(loadingProgress);
            },
            errorBuilder: (_, __, ___) {
              if (widget.previewBytes != null && widget.previewBytes!.isNotEmpty) {
                return const SizedBox.shrink();
              }
              return _buildImageErrorState();
            },
          ),
        ],
      );
    }

    return PickedImagePreview(path: path);
  }

  Widget _buildImageLoadingState(ImageChunkEvent progress) {
    final total = progress.expectedTotalBytes;
    final loaded = progress.cumulativeBytesLoaded;
    final value = total != null ? loaded / total : null;

    return ColoredBox(
      color: AddCarTheme.inputFill,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: value,
            color: AddCarTheme.focusBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorState() {
    return ColoredBox(
      color: AddCarTheme.textPrimary.withValues(alpha: 0.06),
      child: const Icon(
        Icons.directions_car_rounded,
        size: 36,
        color: AddCarTheme.textSecondary,
      ),
    );
  }

  Widget _buildUploadingOverlay() {
    return ColoredBox(
      color: AddCarTheme.cardBg.withValues(alpha: 0.72),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AddCarTheme.focusBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final onRemove = widget.onRemove;
    if (onRemove == null) return const SizedBox.shrink();

    return PositionedDirectional(
      top: 8,
      end: 8,
      child: GestureDetector(
        onTap: onRemove,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBorderOverlay() {
    final borderColor = _pressed
      ? AddCarTheme.focusBlue
      : (widget.hasPhoto
          ? AddCarTheme.textPrimary.withValues(alpha: 0.15)
          : AddCarTheme.border);

    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: borderColor,
              width: _pressed ? 1.5 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

