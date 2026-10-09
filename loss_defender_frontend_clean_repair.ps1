$ErrorActionPreference = "Stop"

Set-Location "D:\Loss Defender\frontend"

Write-Host "===== LOSS DEFENDER FRONTEND CLEAN REPAIR =====" -ForegroundColor Cyan

# 1) Remove repair backups accidentally created inside lib/.
$backupDirs = Get-ChildItem ".\lib" -Recurse -Directory -Filter "_repair_backup_*" -ErrorAction SilentlyContinue
if ($backupDirs) {
    foreach ($dir in $backupDirs) {
        Write-Host "Removing invalid backup directory: $($dir.FullName)" -ForegroundColor Yellow
        Remove-Item $dir.FullName -Recurse -Force
    }
} else {
    Write-Host "No invalid lib backup directories found." -ForegroundColor Green
}

# 2) Ensure the canonical app root is intact.
$appPath = ".\lib\app\app.dart"
$app = Get-Content $appPath -Raw

if ($app -notmatch "package:flutter/material.dart") {
    throw "Canonical lib/app/app.dart does not contain the expected Flutter import."
}
if ($app -notmatch "screens/session/session_gate.dart") {
    throw "Canonical lib/app/app.dart does not contain the expected session gate import."
}
if ($app -notmatch "class LossDefenderApp") {
    throw "Canonical LossDefenderApp class is missing."
}

# 3) Replace the widget regression test with a self-contained Flutter test.
$testPath = ".\test\widget_test.dart"

$test = @'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loss_defender/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Loss Defender app shell renders without overflow', (tester) async {
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

    await tester.pumpWidget(
      const LossDefenderApp(useSessionGate: false),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LossDefenderApp), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Scan & Pack'), findsWidgets);
    expect(overflowErrors, isEmpty);
  });
}
'@

Set-Content -Path $testPath -Value $test -Encoding UTF8

Write-Host ""
Write-Host "===== FORMAT =====" -ForegroundColor Cyan
dart format lib test
if ($LASTEXITCODE -ne 0) { throw "dart format failed." }

Write-Host ""
Write-Host "===== FLUTTER ANALYZE =====" -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed." }

Write-Host ""
Write-Host "===== WIDGET TEST =====" -ForegroundColor Cyan
flutter test .\test\widget_test.dart
if ($LASTEXITCODE -ne 0) { throw "widget test failed." }

Write-Host ""
Write-Host "===== REPAIR COMPLETE =====" -ForegroundColor Green
Write-Host "No Prisma, migration, reset, push, or database command was executed." -ForegroundColor Green
