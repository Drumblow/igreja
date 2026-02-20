# ==============================================
# Deploy Frontend (Flutter Web) to Vercel
# ==============================================
# Usage: .\deploy-frontend.ps1 [-Preview]
# ==============================================

param(
    [switch]$Preview
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FrontendDir = Resolve-Path "$ScriptDir\..\frontend"
$ApiUrl = if ($env:API_URL) { $env:API_URL } else { "/api" }

Write-Host "=== Igreja Manager - Frontend Deploy ===" -ForegroundColor Cyan
Write-Host "API URL: $ApiUrl"

# 1. Build Flutter web
Write-Host "`n>>> Building Flutter web..." -ForegroundColor Yellow
Set-Location $FrontendDir
flutter build web --release --dart-define="API_URL=$ApiUrl"
if ($LASTEXITCODE -ne 0) { throw "Flutter build failed" }

# 2. Copy vercel.json into build output
Write-Host "`n>>> Preparing Vercel config..." -ForegroundColor Yellow
Copy-Item "$FrontendDir\vercel.json" "$FrontendDir\build\web\vercel.json" -Force

# 3. Deploy to Vercel
Set-Location "$FrontendDir\build\web"

if ($Preview) {
    Write-Host ">>> Deploying PREVIEW to Vercel..." -ForegroundColor Yellow
    vercel --yes
} else {
    Write-Host ">>> Deploying PRODUCTION to Vercel..." -ForegroundColor Yellow
    vercel --yes --prod
}

if ($LASTEXITCODE -ne 0) { throw "Vercel deploy failed" }

Write-Host "`n=== Deploy complete! ===" -ForegroundColor Green
