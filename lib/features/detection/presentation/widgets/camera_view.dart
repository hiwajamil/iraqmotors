import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:iq_motors/features/detection/core/camera_image_input.dart';
import 'package:iq_motors/features/detection/data/services/car_detection_service.dart';
import 'package:iq_motors/features/detection/domain/models/car_bounding_box.dart';
import 'package:iq_motors/features/detection/presentation/widgets/detection_overlay_painter.dart';

typedef OnDetectionsUpdated = void Function(List<CarBoundingBox> detections);
typedef OnHighConfidenceDetection = Future<void> Function(
  CarBoundingBox detection,
);

/// Live camera feed with real-time ML Kit object detection and bounding boxes.
class CameraView extends StatefulWidget {
  const CameraView({
    super.key,
    required this.detectionService,
    required this.onDetectionsUpdated,
    required this.onHighConfidenceDetection,
    this.highlightThreshold = CarDetectionService.confidenceThreshold,
  });

  final CarDetectionService detectionService;
  final OnDetectionsUpdated onDetectionsUpdated;
  final OnHighConfidenceDetection onHighConfidenceDetection;
  final double highlightThreshold;

  @override
  State<CameraView> createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  List<CarBoundingBox> _detections = const [];
  bool _initializing = true;
  String? _error;
  bool _processingFrame = false;
  bool _capturingForLookup = false;
  int _frameSkipCounter = 0;

  static const _frameSkipInterval = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopStream());
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      unawaited(_stopStream());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_startStream());
    }
  }

  Future<void> _initCamera() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      setState(() {
        _initializing = false;
        _error = 'Camera detection is only available on Android and iOS.';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'No camera found on this device.';
        });
        return;
      }

      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      setState(() => _initializing = false);
      await _startStream();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Could not start camera: $e';
      });
    }
  }

  Future<void> _startStream() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    try {
      await controller.startImageStream(_onCameraFrame);
    } catch (e) {
      debugPrint('Camera stream error: $e');
    }
  }

  Future<void> _stopStream() async {
    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.isStreamingImages) return;

    try {
      await controller.stopImageStream();
    } catch (e) {
      debugPrint('Stop camera stream error: $e');
    }
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (_processingFrame) return;

    _frameSkipCounter++;
    if (_frameSkipCounter % _frameSkipInterval != 0) return;

    final controller = _controller;
    if (controller == null) return;

    _processingFrame = true;
    try {
      final inputImage = inputImageFromCameraImage(
        image: image,
        camera: controller.description,
        deviceOrientationDegrees: _deviceOrientationDegrees(),
      );
      if (inputImage == null) return;

      final detections =
          await widget.detectionService.detectVehicles(inputImage);
      if (!mounted) return;

      setState(() => _detections = detections);
      widget.onDetectionsUpdated(detections);

      final top = detections.isNotEmpty ? detections.first : null;
      if (top != null &&
          top.confidence >= widget.highlightThreshold &&
          !_capturingForLookup) {
        _capturingForLookup = true;
        unawaited(_handleHighConfidence(top));
      }
    } finally {
      _processingFrame = false;
    }
  }

  Future<void> _handleHighConfidence(CarBoundingBox detection) async {
    try {
      await widget.onHighConfidenceDetection(detection);
    } finally {
      _capturingForLookup = false;
    }
  }

  int _deviceOrientationDegrees() {
    final orientation = MediaQuery.orientationOf(context);
    return switch (orientation) {
      Orientation.landscape => 90,
      Orientation.portrait => 0,
    };
  }

  /// Captures a still photo for Gemini + Firestore lookup (called by parent).
  Future<File?> captureStillPhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;

    final wasStreaming = controller.value.isStreamingImages;
    if (wasStreaming) {
      await _stopStream();
    }

    try {
      final file = await controller.takePicture();
      return File(file.path);
    } catch (e) {
      debugPrint('Still capture failed: $e');
      return null;
    } finally {
      if (wasStreaming) {
        await _startStream();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'Camera unavailable',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize?.height ?? constraints.maxWidth,
              height: controller.value.previewSize?.width ?? constraints.maxHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  CustomPaint(
                    painter: DetectionOverlayPainter(
                      detections: _detections,
                      highlightThreshold: widget.highlightThreshold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
