import 'package:flutter/material.dart';

import '../../../core/l10n_extensions.dart';
import '../../../core/picked_image_preview.dart';
import '../../../models/add_car_draft.dart';
import '../add_car_theme.dart';
import '../widgets/add_car_form_card.dart';
import '../widgets/add_car_step_header.dart';

/// Step 2 — photo grid.
class AddCarStepPhotos extends StatelessWidget {
  const AddCarStepPhotos({
    super.key,
    required this.photos,
    required this.onPhotoSlotTapped,
    this.isProcessing = false,
  });

  final List<String?> photos;
  final ValueChanged<int> onPhotoSlotTapped;
  final bool isProcessing;

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

    final filledCount = slots.where((p) => p != null).length;

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
                final hasPhoto = photoPath != null;
                return _PhotoSlot(
                  index: index,
                  photoPath: photoPath,
                  hasPhoto: hasPhoto,
                  enabled: !isProcessing,
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
    required this.hasPhoto,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final String? photoPath;
  final bool hasPhoto;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_PhotoSlot> createState() => _PhotoSlotState();
}

class _PhotoSlotState extends State<_PhotoSlot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        onHighlightChanged:
            widget.enabled ? (v) => setState(() => _pressed = v) : null,
        borderRadius: BorderRadius.circular(AddCarTheme.inputRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.hasPhoto ? AddCarTheme.cardBg : AddCarTheme.inputFill,
            borderRadius: BorderRadius.circular(AddCarTheme.inputRadius),
            border: Border.all(
              color: _pressed
                  ? AddCarTheme.focusBlue
                  : (widget.hasPhoto
                      ? AddCarTheme.textPrimary.withValues(alpha: 0.15)
                      : AddCarTheme.border),
              width: _pressed ? 1.5 : 1,
            ),
          ),
          child: widget.hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AddCarTheme.inputRadius - 1,
                      ),
                      child: PickedImagePreview(path: widget.photoPath!),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AddCarTheme.successGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
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
                          color: AddCarTheme.textSecondary.withValues(
                            alpha: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

