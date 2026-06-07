import 'package:flutter/material.dart';

import '../../../models/add_car_draft.dart';

/// Step 2 — photo grid (simulated picker for Phase 1).
class AddCarStepPhotos extends StatelessWidget {
  const AddCarStepPhotos({
    super.key,
    required this.photos,
    required this.onPhotoAdded,
  });

  final List<String?> photos;
  final ValueChanged<int> onPhotoAdded;

  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);
  static const Color _border = Color(0xFFE5E5EA);
  static const Color _fill = Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'وێنەکان بگرە',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.15,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'بە لایەنی کەمەوە ٤ وێنەی ئۆتۆمبێلەکەت بگرە',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$filledCount / ${AddCarDraft.minPhotoCount}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: filledCount >= AddCarDraft.minPhotoCount
                  ? const Color(0xFF34C759)
                  : _textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AddCarDraft.photoSlotCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final hasPhoto = slots[index] != null;
              return _PhotoSlot(
                index: index,
                hasPhoto: hasPhoto,
                onTap: () => onPhotoAdded(index),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatefulWidget {
  const _PhotoSlot({
    required this.index,
    required this.hasPhoto,
    required this.onTap,
  });

  final int index;
  final bool hasPhoto;
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
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.hasPhoto ? Colors.white : AddCarStepPhotos._fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.hasPhoto
                  ? AddCarStepPhotos._textPrimary.withValues(alpha: 0.15)
                  : AddCarStepPhotos._border,
              width: widget.hasPhoto ? 1.5 : 1,
            ),
            boxShadow: _pressed
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: widget.hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: ColoredBox(
                        color: AddCarStepPhotos._textPrimary.withValues(
                          alpha: 0.06,
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          size: 36,
                          color: AddCarStepPhotos._textSecondary,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34C759),
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
                      color: AddCarStepPhotos._textSecondary.withValues(
                        alpha: _pressed ? 1 : 0.85,
                      ),
                    ),
                    if (widget.index == 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'سەرەکی',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AddCarStepPhotos._textSecondary.withValues(
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
