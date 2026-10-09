$ErrorActionPreference = "Stop"

$Root = "D:\Loss Defender"
Set-Location $Root

Write-Host "===== LOSS DEFENDER CODE REPAIR PASS 01 =====" -ForegroundColor Cyan

function Backup-Once([string]$Path) {
    if (Test-Path $Path) {
        $backup = "$Path.repair-backup"
        if (-not (Test-Path $backup)) {
            Copy-Item $Path $backup -Force
            Write-Host "Backup: $backup" -ForegroundColor DarkGray
        }
    }
}

# ------------------------------------------------------------
# 1. Isolate browser-only camera APIs from the shared Flutter
#    import path. This prevents dart:js_interop from loading in
#    VM/test targets.
# ------------------------------------------------------------
$camera = Join-Path $Root "frontend\lib\services\camera\camera_recording_service.dart"
$cameraWeb = Join-Path $Root "frontend\lib\services\camera\camera_recording_service_web.dart"
$cameraStub = Join-Path $Root "frontend\lib\services\camera\camera_recording_service_stub.dart"

if (-not (Test-Path $camera)) { throw "Missing camera service: $camera" }

Backup-Once $camera

$currentCamera = Get-Content $camera -Raw

if ($currentCamera -notmatch "dart:js_interop") {
    Write-Host "[SKIP] Camera service already appears platform-isolated." -ForegroundColor Yellow
} else {
    if (-not (Test-Path $cameraWeb)) {
        Set-Content -Path $cameraWeb -Value $currentCamera -Encoding UTF8
        Write-Host "[CREATE] $cameraWeb" -ForegroundColor Green
    } else {
        Write-Host "[KEEP] Existing web implementation: $cameraWeb" -ForegroundColor DarkGray
    }

    @'
export 'camera_recording_service_stub.dart'
    if (dart.library.js_interop) 'camera_recording_service_web.dart';
'@ | Set-Content -Path $camera -Encoding UTF8

    @'
class CameraDeviceInfo {
  final String deviceId;
  final String label;
  final String groupId;

  const CameraDeviceInfo({
    required this.deviceId,
    required this.label,
    required this.groupId,
  });

  String get displayName {
    if (label.trim().isEmpty) {
      if (deviceId.isEmpty) return 'Camera';
      final shortId = deviceId.length > 8 ? deviceId.substring(0, 8) : deviceId;
      return 'Camera $shortId';
    }
    return label;
  }

  @override
  String toString() =>
      'CameraDeviceInfo(deviceId: $deviceId, label: $label)';
}

class RecordingResult {
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final int durationMs;
  final String objectUrl;

  const RecordingResult({
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    required this.durationMs,
    required this.objectUrl,
  });
}

/// Non-web implementation.
///
/// Browser MediaRecorder APIs are isolated in the web implementation so
/// Flutter VM/test targets never load dart:js_interop.
class CameraRecordingService {
  bool get isRecording => false;

  Future<bool> isSupported() async => false;

  Future<List<CameraDeviceInfo>> getCameras() async => const [];

  Future<Object> openCamera({
    String? deviceId,
    int width = 1280,
    int height = 720,
  }) {
    throw UnsupportedError(
      'Camera recording is only supported on Flutter Web.',
    );
  }

  Object? get stream => null;

  Future<void> stopPreview() async {}

  Future<bool> startRecording() async => false;

  Future<RecordingResult?> stopRecording({required String identifier}) async =>
      null;

  void downloadRecording(RecordingResult recording) {
    throw UnsupportedError(
      'Camera downloads are only supported on Flutter Web.',
    );
  }

  void releaseRecordingUrl(RecordingResult recording) {}

  Future<void> dispose() async {}
}
'@ | Set-Content -Path $cameraStub -Encoding UTF8

    Write-Host "[FIX] Camera platform separation applied." -ForegroundColor Green
}

# ------------------------------------------------------------
# 2. Fix malformed Flutter web index.html bridge injection.
# ------------------------------------------------------------
$index = Join-Path $Root "frontend\web\index.html"
if (Test-Path $index) {
    Backup-Once $index
    $html = Get-Content $index -Raw
    $bridgeLine = '<script src="clerk_bridge.js"></script>' + [Environment]::NewLine + '  <script src="razorpay_bridge.js"></script>'
    $html = $html.Replace('<script src="clerk_bridge.js"></script>`r`n<script src="razorpay_bridge.js"></script>', $bridgeLine)
    $html = $html.Replace('<script src="clerk_bridge.js"></script>`n<script src="razorpay_bridge.js"></script>', $bridgeLine)
    Set-Content -Path $index -Value $html -Encoding UTF8
    Write-Host "[FIX] frontend/web/index.html bridge scripts." -ForegroundColor Green
}

# ------------------------------------------------------------
# 3. Repair accidental .gitignore concatenation.
# ------------------------------------------------------------
$gitignore = Join-Path $Root ".gitignore"
if (Test-Path $gitignore) {
    Backup-Once $gitignore
    $g = Get-Content $gitignore -Raw
    $g = $g -replace '\.vscode/launch\.json_UPLOAD_QUEUE_BACKUP_20261007_231751/', ".vscode/launch.json`r`n_UPLOAD_QUEUE_BACKUP_20261007_231751/"
    Set-Content -Path $gitignore -Value $g -Encoding UTF8
    Write-Host "[FIX] .gitignore concatenation." -ForegroundColor Green
}

# ------------------------------------------------------------
# 4. Add explicit Prisma migration/status scripts. These are
#    intentionally non-destructive. DO NOT reset or db-push.
# ------------------------------------------------------------
$package = Join-Path $Root "backend\package.json"
if (Test-Path $package) {
    Backup-Once $package
    $pkg = Get-Content $package -Raw | ConvertFrom-Json
    if (-not $pkg.scripts.'db:migrate:deploy') {
        $pkg.scripts | Add-Member -NotePropertyName 'db:migrate:deploy' -NotePropertyValue 'prisma migrate deploy'
    }
    if (-not $pkg.scripts.'db:migrate:status') {
        $pkg.scripts | Add-Member -NotePropertyName 'db:migrate:status' -NotePropertyValue 'prisma migrate status'
    }
    if (-not $pkg.scripts.'db:generate') {
        $pkg.scripts | Add-Member -NotePropertyName 'db:generate' -NotePropertyValue 'prisma generate'
    }
    $pkg | ConvertTo-Json -Depth 20 | Set-Content -Path $package -Encoding UTF8
    Write-Host "[FIX] Prisma migration/status scripts added." -ForegroundColor Green
}

# ------------------------------------------------------------
# 5. Verify the edits syntactically where possible.
# ------------------------------------------------------------
Write-Host ""
Write-Host "===== VERIFY =====" -ForegroundColor Cyan

Set-Location (Join-Path $Root "frontend")
flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed." }

flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "[EXPECTED NEXT CHECK] If flutter test still reports a camera/js_interop issue, inspect any direct imports of camera_recording_service_web.dart." -ForegroundColor Yellow
    exit 2
}

Set-Location (Join-Path $Root "backend")
npm.cmd run typecheck
if ($LASTEXITCODE -ne 0) { throw "backend typecheck failed." }

npm.cmd run build
if ($LASTEXITCODE -ne 0) { throw "backend build failed." }

Write-Host ""
Write-Host "===== DB CHECK (READ/DEPLOY ONLY) =====" -ForegroundColor Cyan
npm.cmd run db:migrate:status

Write-Host ""
Write-Host "===== REPAIR PASS COMPLETE =====" -ForegroundColor Cyan
Write-Host "Next: if migration status shows pending migrations, run: npm.cmd run db:migrate:deploy" -ForegroundColor Yellow
Write-Host "Then rerun: npm.cmd run test:phase5-6" -ForegroundColor Yellow
Write-Host "DO NOT run prisma migrate reset or prisma db push on the production database." -ForegroundColor Red
