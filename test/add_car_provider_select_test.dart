import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iq_motors/features/listings/presentation/providers/add_car_flow_provider.dart';

void main() {
  test('addCarFlowProvider supports select', () {
    const session = AddCarFlowSession();
    final provider = addCarFlowProvider(session);

    // Verify select extension is available.
    final selected = provider.select((s) => s.currentStep);
    expect(selected, isNotNull);
  });
}
