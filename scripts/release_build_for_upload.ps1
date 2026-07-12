$ErrorActionPreference = 'Stop'

function Step([string]$text) {
  Write-Host ""
  Write-Host "=== $text ===" -ForegroundColor Cyan
}

function RunStep([string]$description, [string]$command) {
  Step $description
  Write-Host "> $command" -ForegroundColor DarkGray
  Invoke-Expression $command
}

RunStep "1/4 Flutter-Abhaengigkeiten aktualisieren" "flutter pub get"

Step "2/4 Statische Analyse starten (Info-Warnungen sind erlaubt)"
Write-Host "> flutter analyze" -ForegroundColor DarkGray
flutter analyze
if ($LASTEXITCODE -ne 0) {
  Write-Host "Analyse meldet Warnungen/Hinweise. Build wird trotzdem fortgesetzt." -ForegroundColor Yellow
}

$buildCommand = "flutter build appbundle"
if ($env:REVENUECAT_API_KEY) {
  $buildCommand += " --dart-define=REVENUECAT_API_KEY=$env:REVENUECAT_API_KEY"
} else {
  Write-Host "Hinweis: REVENUECAT_API_KEY ist nicht gesetzt - Build nutzt den im Code hinterlegten Standard-Key." -ForegroundColor DarkGray
}
RunStep "3/4 Signiertes Android App Bundle bauen" $buildCommand

Step "4/4 Upload-Artefakt pruefen"
$aabPath = "build/app/outputs/bundle/release/app-release.aab"
if (-not (Test-Path $aabPath)) {
  throw "AAB nicht gefunden: $aabPath"
}

Get-Item $aabPath |
  Select-Object FullName, Length, LastWriteTime |
  Format-List |
  Out-String |
  Write-Host

Write-Host "Release-AAB ist bereit fuer den Play-Console-Upload." -ForegroundColor Green
