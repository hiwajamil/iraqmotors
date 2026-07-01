import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/features/detection/data/services/car_detection_service.dart';

final carDetectionServiceProvider = Provider<CarDetectionService>((ref) {
  final service = CarDetectionService();
  ref.onDispose(service.dispose);
  return service;
});
