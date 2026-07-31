# Post-install: deploy EA (if not done) and open MT5 — license handled in Setup wizard.
param(
  [Parameter(Mandatory = $true)]
  [string]$InstallRoot,
  [ValidateSet("Yes", "No")]
  [string]$DeployEA = "Yes"
)

$ErrorActionPreference = "Continue"
$scripts = Join-Path $InstallRoot "scripts"

if ($DeployEA -eq "Yes") {
  try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts "Deploy-EA-To-MT5.ps1") -InstallRoot $InstallRoot -Silent
  } catch {
    Write-Warning "EA deploy deferred: $_"
  }
}

try {
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts "Launch-Mt5-AfterInstall.ps1") -InstallRoot $InstallRoot
} catch {
  Write-Warning "Could not launch MT5: $_"
}

Write-Host "Post-install finished."
