# Post-install wizard: MT5 deploy + license activation prompts.
param(
  [Parameter(Mandatory = $true)]
  [string]$InstallRoot,
  [ValidateSet("Yes", "No")]
  [string]$DeployEA = "Yes"
)

$ErrorActionPreference = "Continue"
$scripts = Join-Path $InstallRoot "scripts"

Write-Host "THE GOLD MIND PROFESSIONAL - Post-Install"
Write-Host "Install root: $InstallRoot"

if ($DeployEA -eq "Yes") {
  try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts "Deploy-EA-To-MT5.ps1") -InstallRoot $InstallRoot
  } catch {
    Write-Warning "EA deploy deferred: $_"
    Write-Host "Run later: $scripts\Deploy-EA-To-MT5.ps1"
  }
}

Write-Host ""
Write-Host "License activation"
Write-Host "  You can activate now or later from Start Menu -> Activate License"
$doAct = Read-Host "Activate license now? [Y/n]"
if ($doAct -eq "" -or $doAct -match '^[Yy]') {
  $google = Read-Host "Use Google login in browser first? [y/N]"
  $gSwitch = @()
  if ($google -match '^[Yy]') { $gSwitch = @("-GoogleLogin") }
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts "Activate-License.ps1") -InstallRoot $InstallRoot @gSwitch
}

Write-Host "Post-install finished."
