import 'package:flutter_test/flutter_test.dart';
import 'package:loss_defender_frontend/app/app.dart';

void main() {
  testWidgets('Loss Defender app loads dashboard', (tester) async {
    await tester.pumpWidget(const LossDefenderApp());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LossDefenderApp), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Warehouse Overview'), findsOneWidget);
    expect(find.text('Scan & Pack'), findsWidgets);
  });
}
