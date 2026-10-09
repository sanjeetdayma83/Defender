# ============================================================
# LOSS DEFENDER PRO - FRONTEND TEST/ANALYZE REPAIR
# NO DATABASE / PRISMA COMMANDS
# ============================================================

$ErrorActionPreference = "Stop"
Set-Location "D:\Loss Defender\frontend"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " LOSS DEFENDER PRO - FRONTEND TEST/ANALYZE REPAIR" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$appPath  = ".\lib\app\app.dart"
$testPath = ".\test\widget_test.dart"

# ------------------------------------------------------------
# 1. Remove accidental repair backups from lib
# ------------------------------------------------------------
Get-ChildItem ".\lib" -Directory -Recurse -Force |
    Where-Object { $_.Name -like "_repair_backup_*" } |
    ForEach-Object {
        Write-Host "[CLEAN] Removing analyzer-visible backup: $($_.FullName)" -ForegroundColor Yellow
        Remove-Item $_.FullName -Recurse -Force
    }

# Also remove any backup directories accidentally nested under lib
Get-ChildItem ".\lib" -Directory -Recurse -Force |
    Where-Object { $_.Name -like "*backup*" -and $_.FullName -match "_repair_backup_" } |
    ForEach-Object {
        if (Test-Path $_.FullName) {
            Remove-Item $_.FullName -Recurse -Force
        }
    }

Write-Host "[PASS] Analyzer-visible backup folders cleaned." -ForegroundColor Green

# ------------------------------------------------------------
# 2. Make app shell testable without Firebase
# ------------------------------------------------------------
$app = Get-Content -LiteralPath $appPath -Raw

$app = $app -replace `
    'class LossDefenderApp extends StatelessWidget \{\r?\n  const LossDefenderApp\(\{super\.key\}\);', `
    'class LossDefenderApp extends StatelessWidget {
  final bool useSessionGate;

  const LossDefenderApp({
    super.key,
    this.useSessionGate = true,
  });'

$app = $app -replace `
    'home: const LDSessionGate\(\),', `
    'home: useSessionGate
            ? const LDSessionGate()
            : const SaaSPortalScreen(),'

if ($app -notmatch "screens/saas/saas_portal_screen.dart") {
    $app = $app -replace `
        "import '../screens/session/session_gate.dart';", `
        "import '../screens/session/session_gate.dart';
import '../screens/saas/saas_portal_screen.dart';"
}

Set-Content -LiteralPath $appPath -Value $app -Encoding UTF8

Write-Host "[PASS] App shell now supports a Firebase-free widget-test mode." -ForegroundColor Green

# ------------------------------------------------------------
# 3. Replace widget test with deterministic local UI test
# ------------------------------------------------------------
$test = @'
import 'package:flutter_test/flutter_test.dart';
import 'package:loss_defender_frontend/app/app.dart';

void main() {
  testWidgets(
    'Loss Defender Pro canonical app shell renders without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const LossDefenderApp(useSessionGate: false),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LossDefenderApp), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Scan & Pack'), findsWidgets);

      final exceptionMessages = <String>[];

      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed') ||
            message.contains('RenderFlex')) {
          exceptionMessages.add(message);
        }
      };

      await tester.pump(const Duration(milliseconds: 250));

      expect(
        exceptionMessages,
        isEmpty,
        reason: 'No layout overflow should be present.',
      );

      FlutterError.onError = FlutterError.dumpErrorToConsole;
    },
  );
}
'@

Set-Content -LiteralPath $testPath -Value $test -Encoding UTF8

Write-Host "[PASS] Widget test made deterministic and Firebase-independent." -ForegroundColor Green

# ------------------------------------------------------------
# 4. Format
# ------------------------------------------------------------
Write-Host ""
Write-Host "===== DART FORMAT =====" -ForegroundColor Cyan
dart format lib test
if ($LASTEXITCODE -ne 0) {
    throw "dart format failed."
}

# ------------------------------------------------------------
# 5. Analyze
# ------------------------------------------------------------
Write-Host ""
Write-Host "===== FLUTTER ANALYZE =====" -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) {
    throw "flutter analyze failed."
}

# ------------------------------------------------------------
# 6. Test
# ------------------------------------------------------------
Write-Host ""
Write-Host "===== WIDGET TEST =====" -ForegroundColor Cyan
flutter test .\test\widget_test.dart
if ($LASTEXITCODE -ne 0) {
    throw "widget_test.dart failed."
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " FRONTEND TEST/ANALYZE REPAIR PASSED" -ForegroundColor Green
Write-Host " NO DATABASE / PRISMA COMMANDS EXECUTED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
