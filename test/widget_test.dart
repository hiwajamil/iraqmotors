import 'package:flutter_test/flutter_test.dart';

import 'package:iq_motors/core/locale_config.dart';

void main() {
  test('default app locale is Kurdish', () {
    expect(AppLocaleConfig.defaultLocale.languageCode, 'ku');
    expect(AppLocaleConfig.isRtl(AppLocaleConfig.defaultLocale), isTrue);
  });
}
