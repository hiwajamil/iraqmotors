import 'package:flutter/material.dart';

import 'package:iq_motors/features/detection/domain/models/car_bounding_box.dart';

/// Draws vehicle bounding boxes on top of the camera preview.
class DetectionOverlayPainter extends CustomPainter {
  DetectionOverlayPainter({
    required this.detections,
    required this.highlightThreshold,
    this.primaryColor = const Color(0xFF34C759),
    this.lowConfidenceColor = const Color(0x99FFFFFF),
  });

  final List<CarBoundingBox> detections;
  final double highlightThreshold;
  final Color primaryColor;
  final Color lowConfidenceColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      final rect = Rect.fromLTRB(
        detection.rect.left * size.width,
        detection.rect.top * size.height,
        detection.rect.right * size.width,
        detection.rect.bottom * size.height,
      );

      final isHighConfidence = detection.confidence >= highlightThreshold;
      final color = isHighConfidence ? primaryColor : lowConfidenceColor;

      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighConfidence ? 3 : 2;

      final fill = Paint()
        ..color = color.withValues(alpha: isHighConfidence ? 0.15 : 0.08)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, stroke);

      final label = detection.label ??
          (isHighConfidence ? 'Vehicle' : 'Scanning…');
      final confidence = '${(detection.confidence * 100).round()}%';
      final text = '$label · $confidence';

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isHighConfidence ? FontWeight.w700 : FontWeight.w500,
            shadows: const [
              Shadow(blurRadius: 4, color: Colors.black54),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width);

      final labelTop = rect.top - textPainter.height - 6;
      final labelRect = Rect.fromLTWH(
        rect.left,
        labelTop < 0 ? rect.top + 4 : labelTop,
        textPainter.width + 12,
        textPainter.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );
      textPainter.paint(
        canvas,
        Offset(labelRect.left + 6, labelRect.top + 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DetectionOverlayPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.highlightThreshold != highlightThreshold;
  }
}
