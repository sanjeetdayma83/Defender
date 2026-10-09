import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loss_defender_frontend/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Loss Defender app shell renders without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final overflowErrors = <FlutterError>[];
    final previousOnError = FlutterError.onError;

    FlutterError.onError = (details) {
      final exception = details.exception;
      if (exception is FlutterError &&
          exception.message.contains('overflowed')) {
        overflowErrors.add(exception);
        return;
      }
      previousOnError?.call(details);
    };

    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    await tester.pumpWidget(const LossDefenderApp(useSessionGate: false));
    await tester.pumpAndSettle();

    expect(find.byType(LossDefenderApp), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Companies'), findsWidgets);
    expect(find.text('Users'), findsWidgets);
    expect(find.text('Subscriptions'), findsWidgets);
    expect(find.text('Plans'), findsWidgets);
    expect(find.text('Storage'), findsWidgets);
    expect(overflowErrors, isEmpty);
  });
}
