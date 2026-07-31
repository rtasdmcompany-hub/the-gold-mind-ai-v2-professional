# Deploy latest compiled EA to all local MT5 data folders
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
$src  = Join-Path $root "Experts\TheGoldMindAI_Professional.ex5"
if (-not (Test-Path $src)) { throw "Compile first: $src not found" }

$targets = @(
  (Join-Path $root "Commercial\Installer\Professional\inno\payload\ea\TheGoldMindAI_Professional.ex5"),
  (Join-Path $env:LOCALAPPDATA "THE GOLD MIND PROFESSIONAL\ea\TheGoldMindAI_Professional.ex5")
)

Get-ChildItem "$env:APPDATA\MetaQuotes\Terminal" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $targets += Join-Path $_.FullName "MQL5\Experts\TheGoldMindAI_Professional.ex5"
  $targets += Join-Path $_.FullName "MQL5\Experts\The Gold Mind Professional\TheGoldMindAI_Professional.ex5"
  $targets += Join-Path $_.FullName "MQL5\Experts\The Gold Mind\TheGoldMindAI_Professional.ex5"
}

$srcHash = (Get-FileHash $src -Algorithm SHA256).Hash
Write-Host "Source: $src"
Write-Host "SHA256: $srcHash"
Write-Host ""

foreach ($t in ($targets | Select-Object -Unique)) {
  $dir = Split-Path $t
  if (-not (Test-Path $dir)) { continue }
  Copy-Item -Force $src $t
  Write-Host "OK $t"
}

Write-Host ""
Write-Host "Done. Restart MT5, remove EA from chart, cancel old pending orders, re-attach TheGoldMindAI_Professional."
