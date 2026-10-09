# ============================================================
# LOSS DEFENDER PRO - FRONTEND CONSOLIDATION
# Safe coding pass: NO DATABASE / PRISMA COMMANDS
# ============================================================

$ErrorActionPreference = "Stop"

Set-Location "D:\Loss Defender\frontend"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " LOSS DEFENDER PRO - FRONTEND CONSOLIDATION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$appPath  = ".\lib\app\app.dart"
$mainPath = ".\lib\main.dart"
$testPath = ".\test\widget_test.dart"

# ------------------------------------------------------------
# 1. Backup current files
# ------------------------------------------------------------
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = ".\_repair_backup_$stamp"

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Copy-Item $appPath  "$backupDir\app.dart"  -Force
Copy-Item $mainPath "$backupDir\main.dart" -Force
Copy-Item $testPath "$backupDir\widget_test.dart" -Force

Write-Host "[PASS] Backups created: $backupDir" -ForegroundColor Green

# ------------------------------------------------------------
# 2. Canonical app shell
# ------------------------------------------------------------
$app = @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../screens/session/session_gate.dart';

class LossDefenderApp extends StatelessWidget {
  const LossDefenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionProvider>(
      create: (_) => SessionProvider(),
      child: MaterialApp(
        title: 'Loss Defender Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0061FC),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF021F4F),
            elevation: 0,
          ),
        ),
        home: const LDSessionGate(),
      ),
    );
  }
}
'@

Set-Content -LiteralPath $appPath -Value $app -Encoding UTF8

# ------------------------------------------------------------
# 3. main.dart becomes bootstrap only
# ------------------------------------------------------------
$main = @'
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LossDefenderApp());
}
'@

Set-Content -LiteralPath $mainPath -Value $main -Encoding UTF8

# ------------------------------------------------------------
# 4. Stable widget regression test
# ------------------------------------------------------------
$test = @'
import 'package:flutter/material.dart';
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

      await tester.pumpWidget(const LossDefenderApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LossDefenderApp), findsOneWidget);

      final exceptions = <FlutterErrorDetails>[];

      FlutterError.onError = (details) {
        exceptions.add(details);
      };

      await tester.pump(const Duration(milliseconds: 500));

      expect(
        exceptions.where(
          (e) =>
              e.exceptionAsString().contains('overflowed') ||
              e.exceptionAsString().contains('RenderFlex'),
        ),
        isEmpty,
        reason: 'No layout overflow should be present.',
      );

      FlutterError.onError = FlutterError.dumpErrorToConsole;
    },
  );
}
'@

Set-Content -LiteralPath $testPath -Value $test -Encoding UTF8

Write-Host "[PASS] Canonical app shell written." -ForegroundColor Green
Write-Host "[PASS] main.dart reduced to Firebase bootstrap." -ForegroundColor Green
Write-Host "[PASS] Widget regression test updated." -ForegroundColor Green

# ------------------------------------------------------------
# 5. Format
# ------------------------------------------------------------
Write-Host ""
Write-Host "===== DART FORMAT =====" -ForegroundColor Cyan

& flutter format lib test
if ($LASTEXITCODE -ne 0) {
    throw "flutter format failed."
}

# ------------------------------------------------------------
# 6. Analyze
# ------------------------------------------------------------
Write-Host ""
Write-Host "===== FLUTTER ANALYZE =====" -ForegroundColor Cyan

& flutter analyze
if ($LASTEXITCODE -ne 0) {
    throw "flutter analyze failed."
}

# ------------------------------------------------------------
# 7. Widget test
# ------------------------------------------------------------
Write-Host ""
Write-Host "===== WIDGET TEST =====" -ForegroundColor Cyan

& flutter test .\test\widget_test.dart
if ($LASTEXITCODE -ne 0) {
    throw "widget_test.dart failed."
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " FRONTEND CONSOLIDATION PASSED" -ForegroundColor Green
Write-Host " NO DATABASE COMMANDS WERE EXECUTED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
