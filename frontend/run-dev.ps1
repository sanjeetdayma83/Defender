Set-Location "D:\Loss Defender\frontend"

if (-not (Test-Path ".\pubspec.yaml")) {
    Write-Host "[ERROR] Flutter project not found." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path ".\.env")) {
    Write-Host "[ERROR] frontend\.env not found." -ForegroundColor Red
    Write-Host "Run the setup block again." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " LOSS DEFENDER - DEVELOPMENT SERVER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

flutter.bat run -d chrome --dart-define-from-file=.env
