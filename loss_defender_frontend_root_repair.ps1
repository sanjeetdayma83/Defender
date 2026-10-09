$ErrorActionPreference = "Stop"

Set-Location "D:\Loss Defender\frontend"

Write-Host "===== LOSS DEFENDER FRONTEND ROOT REPAIR =====" -ForegroundColor Cyan

# Find repair backups anywhere under the Flutter package, not only under lib/.
$backupDirs = Get-ChildItem "." -Recurse -Directory -Filter "_repair_backup_*" -Force -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending

if ($backupDirs) {
    foreach ($dir in $backupDirs) {
        Write-Host "Removing analyzer-visible backup: $($dir.FullName)" -ForegroundColor Yellow
        Remove-Item -LiteralPath $dir.FullName -Recurse -Force
    }
} else {
    Write-Host "No repair backup directories found." -ForegroundColor Green
}

# Also remove the known accidental backup if it exists as a file/directory variant.
Get-ChildItem "." -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "_repair_backup_*" } |
    ForEach-Object {
        if (Test-Path -LiteralPath $_.FullName) {
            Write-Host "Removing remaining repair artifact: $($_.FullName)" -ForegroundColor Yellow
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

$appPath = ".\lib\app\app.dart"
if (-not (Test-Path $appPath)) { throw "Missing canonical app: $appPath" }

$app = Get-Content $appPath -Raw
if ($app -notmatch "class LossDefenderApp") {
    throw "Canonical LossDefenderApp is missing."
}

# The test uses a relative import, so it does not depend on the pubspec package name.
$testPath = ".\test\widget_test.dart"
$test = @'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/app/app.dart';

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
Write-Host "===== VERIFY PACKAGE ROOT =====" -ForegroundColor Cyan
Write-Host "Flutter package: $((Get-Content .\pubspec.yaml | Select-String '^name:' | Select-Object -First 1).Line)"

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
Write-Host "===== ROOT REPAIR COMPLETE =====" -ForegroundColor Green
Write-Host "No Prisma, migration, reset, push, or database command was executed." -ForegroundColor Green
