import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iq_motors/core/localization/app_localization_delegates.dart';
import 'package:iq_motors/core/localization/locale_config.dart';
import 'package:iq_motors/features/listings/presentation/add_car_flow_screen.dart';

void main() {
  testWidgets('AddCarFlowScreen renders wizard chrome and location step',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: AppLocaleConfig.defaultLocale,
          supportedLocales: AppLocaleConfig.supportedLocales,
          localizationsDelegates: appLocalizationDelegates,
          builder: (context, child) {
            return Directionality(
              textDirection: AppLocaleConfig.textDirectionFor(
                AppLocaleConfig.defaultLocale,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AddCarFlowScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('شوێن'), findsOneWidget);
    expect(find.text('ئۆتۆمبێلەکەت لە چ شوێنێکە؟'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
