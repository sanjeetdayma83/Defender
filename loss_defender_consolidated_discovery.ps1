$ErrorActionPreference = "Continue"

Set-Location "D:\Loss Defender"

Write-Host "========== LOSS DEFENDER CONSOLIDATED DISCOVERY ==========" -ForegroundColor Cyan

Write-Host "`n===== GIT =====" -ForegroundColor Yellow
git branch --show-current
git status --short
git log -1 --oneline

Write-Host "`n===== FRONTEND TEST FILES =====" -ForegroundColor Yellow
Get-ChildItem ".\frontend\test" -Recurse -File -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName

Write-Host "`n===== FRONTEND ROLE/SCREEN FILES =====" -ForegroundColor Yellow
Get-ChildItem ".\frontend\lib" -Recurse -File -Filter "*.dart" |
    Where-Object {
        $_.FullName -match "role|permission|session|platform|company|warehouse|claim|pack|scan|record|evidence|order|billing|storage"
    } |
    ForEach-Object { $_.FullName }

Write-Host "`n===== FRONTEND PUBSPEC =====" -ForegroundColor Yellow
Get-Content ".\frontend\pubspec.yaml" |
    Select-String "^(name:|flutter:|environment:|  sdk:)"

Write-Host "`n===== BACKEND TEST FILES =====" -ForegroundColor Yellow
Get-ChildItem ".\backend" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "\.(spec|test)\.(ts|tsx)$" } |
    Select-Object -ExpandProperty FullName

Write-Host "`n===== BACKEND PACKAGE SCRIPTS =====" -ForegroundColor Yellow
$pkg = Get-Content ".\backend\package.json" -Raw | ConvertFrom-Json
$pkg.scripts | Format-List

Write-Host "`n===== FRONTEND TEST RUN =====" -ForegroundColor Cyan
Set-Location ".\frontend"
flutter test
$frontendTestExit = $LASTEXITCODE
Write-Host "FRONTEND_TEST_EXIT=$frontendTestExit"

Write-Host "`n===== FRONTEND ANALYZE =====" -ForegroundColor Cyan
flutter analyze
$frontendAnalyzeExit = $LASTEXITCODE
Write-Host "FRONTEND_ANALYZE_EXIT=$frontendAnalyzeExit"

Write-Host "`n===== BACKEND TYPECHECK =====" -ForegroundColor Cyan
Set-Location "..\backend"
npm.cmd run typecheck
$backendTypecheckExit = $LASTEXITCODE
Write-Host "BACKEND_TYPECHECK_EXIT=$backendTypecheckExit"

Write-Host "`n===== BACKEND BUILD =====" -ForegroundColor Cyan
npm.cmd run build
$backendBuildExit = $LASTEXITCODE
Write-Host "BACKEND_BUILD_EXIT=$backendBuildExit"

Write-Host "`n===== CONSOLIDATED DISCOVERY RESULT =====" -ForegroundColor Green
Write-Host "Frontend tests exit : $frontendTestExit"
Write-Host "Frontend analyze    : $frontendAnalyzeExit"
Write-Host "Backend typecheck   : $backendTypecheckExit"
Write-Host "Backend build       : $backendBuildExit"
Write-Host ""
Write-Host "NO Prisma/migration/reset/db-push command was executed." -ForegroundColor Green
