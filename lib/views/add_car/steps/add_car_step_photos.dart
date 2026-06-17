import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../core/picked_image_preview.dart';
import '../../../models/add_car_draft.dart';
import '../add_car_theme.dart';
import '../widgets/add_car_form_card.dart';
import '../widgets/add_car_step_header.dart';

bool _isFilledPhotoSlot(String? path) =>
    path != null && path.trim().isNotEmpty;

/// Step 2 — photo grid.
class AddCarStepPhotos extends StatelessWidget {
  const AddCarStepPhotos({
    super.key,
    required this.photos,
    required this.onPhotoSlotTapped,
    this.uploadingSlots = const {},
    this.previewBytesBySlot = const {},
  });

  final List<String?> photos;
  final ValueChanged<int> onPhotoSlotTapped;
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
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AddCarDraft.photoSlotCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final photoPath = slots[index];
                final hasPhoto = _isFilledPhotoSlot(photoPath);
                return _PhotoSlot(
                  index: index,
                  photoPath: photoPath,
                  previewBytes: previewBytesBySlot[index],
                  hasPhoto: hasPhoto,
                  isUploading: uploadingSlots.contains(index),
                  enabled: !uploadingSlots.contains(index),
                  onTap: () => onPhotoSlotTapped(index),
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
  });

  final int index;
  final String? photoPath;
  final Uint8List? previewBytes;
  final bool hasPhoto;
  final bool isUploading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_PhotoSlot> createState() => _PhotoSlotState();
}

class _PhotoSlotState extends State<_PhotoSlot> {
  bool _pressed = false;

  static const double _radius = AddCarTheme.inputRadius;

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
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildSlotBackground(),
                  if (widget.isUploading) _buildUploadingOverlay(),
                  if (widget.hasPhoto && !widget.isUploading)
                    _buildSuccessCheckmark(),
                  _buildBorderOverlay(),
                ],
              ),
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
              size: 28,
              color: AddCarTheme.textSecondary.withValues(
                alpha: _pressed ? 1 : 0.85,
              ),
            ),
            if (widget.index == 0) ...[
              const SizedBox(height: 6),
              Text(
                context.l10n.addCarPhotoPrimary,
                style: TextStyle(
                  fontSize: 11,
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

  Widget _buildSuccessCheckmark() {
    return PositionedDirectional(
      top: 8,
      end: 8,
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AddCarTheme.successGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 14,
          color: Colors.white,
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

