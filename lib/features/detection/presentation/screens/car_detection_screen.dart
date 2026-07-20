import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:iq_motors/features/detection/data/services/car_detection_service.dart';
import 'package:iq_motors/features/detection/domain/models/car_bounding_box.dart';
import 'package:iq_motors/features/detection/presentation/providers/car_detection_providers.dart';
import 'package:iq_motors/features/detection/presentation/widgets/camera_view.dart';
import 'package:iq_motors/features/marketplace/domain/models/car.dart';
import 'package:iq_motors/features/marketplace/presentation/screens/car_details_screen.dart';
import 'package:iq_motors/shared/widgets/car_network_image.dart';
import 'package:iq_motors/shared/data/dummy_brands.dart';
import 'package:iq_motors/shared/data/car_models_by_brand.dart';
import 'package:iq_motors/features/storage/presentation/providers/storage_providers.dart';

/// Point the camera at a car to detect it and find matching marketplace listings.
class CarDetectionScreen extends ConsumerStatefulWidget {
  const CarDetectionScreen({super.key});

  @override
  ConsumerState<CarDetectionScreen> createState() => _CarDetectionScreenState();
}

class _CarDetectionScreenState extends ConsumerState<CarDetectionScreen> {
  final _cameraKey = GlobalKey<CameraViewState>();
  final _imagePicker = ImagePicker();

  CarDetectionLookupResult? _lookupResult;
  bool _identifying = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final detectionService = ref.watch(carDetectionServiceProvider);
    final unsupported = kIsWeb || !(Platform.isAndroid || Platform.isIOS);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: const Text('Car Model Detection'),
        elevation: 0,
      ),
      body: unsupported
          ? _buildUnsupported()
          : Column(
              children: [
                Expanded(
                  child: CameraView(
                    key: _cameraKey,
                    detectionService: detectionService,
                    onDetectionsUpdated: (_) {},
                    onHighConfidenceDetection: _onHighConfidence,
                  ),
                ),
                _buildStatusPanel(),
                if (_lookupResult != null) _buildResultsPanel(_lookupResult!),
              ],
            ),
    );
  }

  Widget _buildUnsupported() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Car Model Detection',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload a photo of a vehicle to identify its make/model and search matching marketplace listings.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _identifying ? null : _onUploadImage,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: const Text(
                            'Select Image',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildStatusPanel(),
        if (_lookupResult != null) _buildResultsPanel(_lookupResult!),
      ],
    );
  }

  Future<void> _onUploadImage() async {
    if (_identifying) return;

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _identifying = true;
      _statusMessage = 'Identifying make and model from image…';
      _lookupResult = null;
    });

    try {
      final bytes = await image.readAsBytes();
      final visionService = ref.read(carVisionServiceProvider);
      
      // Analyze image using Gemini Vision API
      final analysis = await visionService.analyzeCarImageBytes(
        bytes,
        mimeType: image.mimeType ?? 'image/jpeg',
      );

      final suggestion = visionService.mapAnalysisToFormKeys(analysis);
      if (suggestion.brandId == null) {
        setState(() {
          _identifying = false;
          _statusMessage = 'No vehicle identified. Please upload a clear photo of a car.';
        });
        return;
      }

      // Map brand & model labels from catalogs
      final brand = dummyBrands.firstWhere(
        (b) => b.id == suggestion.brandId,
        orElse: () => dummyBrands.first,
      );
      final modelLabel = suggestion.modelKey != null
          ? CarModelsByBrand.labelForModel(brand, suggestion.modelKey!, 'en')
          : null;

      final identification = CarIdentificationResult(
        brandId: suggestion.brandId!,
        modelKey: suggestion.modelKey,
        year: _nullableYear(analysis['year']),
        brandLabel: brand.displayName('en'),
        modelLabel: modelLabel,
        confidence: 0.95, // High confidence for file upload
      );

      // Search Firestore
      final database = ref.read(carDatabaseServiceProvider);
      final listings = await database.findListingsByDetection(
        brandId: identification.brandId,
        modelKey: identification.modelKey,
        year: identification.year,
      );

      if (!mounted) return;

      setState(() {
        _identifying = false;
        _lookupResult = CarDetectionLookupResult(
          identification: identification,
          listings: listings,
        );
        _statusMessage = 'Match found in marketplace listings.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _identifying = false;
        _statusMessage = 'Identification failed. Check your network and retry.';
      });
    }
  }

  String? _nullableYear(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'\d{4}').firstMatch(raw.trim());
    return match?.group(0);
  }


  Widget _buildStatusPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: const Color(0xFF1C1C1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _identifying ? Icons.auto_awesome : Icons.center_focus_strong,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusMessage ??
                      'Aim at a car. A green box appears above '
                      '${(CarDetectionService.confidenceThreshold * 100).round()}% confidence.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (_identifying)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel(CarDetectionLookupResult result) {
    final id = result.identification;
    final title = [
      id.brandLabel,
      if (id.modelLabel != null && id.modelLabel!.isNotEmpty) id.modelLabel,
      if (id.year != null) id.year,
    ].join(' ');

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Detected: $title',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              result.listings.isEmpty
                  ? 'No active listings match this vehicle yet.'
                  : '${result.listings.length} matching listing(s) on IQ Motors',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: result.listings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final car = result.listings[index];
                return _ListingChip(
                  car: car,
                  onTap: () => _openListing(car),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onHighConfidence(CarBoundingBox detection) async {
    if (_identifying) return;

    setState(() {
      _identifying = true;
      _statusMessage = 'Identifying make and model…';
    });

    final photo = await _cameraKey.currentState?.captureStillPhoto();
    if (photo == null || !mounted) {
      setState(() {
        _identifying = false;
        _statusMessage = 'Could not capture photo. Try holding the phone steady.';
      });
      return;
    }

    try {
      final service = ref.read(carDetectionServiceProvider);
      final result = await service.lookupIfConfident(
        detection: detection,
        imageFile: photo,
      );

      if (!mounted) return;

      setState(() {
        _identifying = false;
        if (result == null) {
          _statusMessage =
              'Vehicle detected — still analyzing. Point at the full car.';
        } else {
          _lookupResult = result;
          _statusMessage = 'Match found in marketplace listings.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _identifying = false;
        _statusMessage = 'Identification failed. Check your network and retry.';
      });
    } finally {
      try {
        if (photo.existsSync()) await photo.delete();
      } catch (_) {}
    }
  }

  void _openListing(Car car) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CarDetailsScreen(car: car.toMap()),
      ),
    );
  }
}

class _ListingChip extends StatelessWidget {
  const _ListingChip({
    required this.car,
    required this.onTap,
  });

  final Car car;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = car.data;
    final imageUrl = data['imageUrl']?.toString() ?? '';
    final make = data['make']?.toString() ?? '';
    final model = data['model']?.toString() ?? '';
    final price = data['price']?.toString() ?? '';

    return Material(
      color: const Color(0xFF3A3A3C),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: imageUrl.isNotEmpty
                      ? CarNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                      : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$make $model'.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (price.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        price,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
