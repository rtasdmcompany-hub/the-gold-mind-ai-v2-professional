param(
  [string]$InstallRoot = "$env:LOCALAPPDATA\THE GOLD MIND PROFESSIONAL",
  [switch]$KeepLogs
)

$ErrorActionPreference = "Stop"
$ProductName = "THE GOLD MIND PROFESSIONAL"

Write-Host "========================================================" -ForegroundColor DarkYellow
Write-Host " Uninstall · $ProductName" -ForegroundColor Yellow
Write-Host "========================================================"
Write-Host "Target: $InstallRoot"
Write-Host "MT5 terminals and Core Trading Engine paths outside this root are not touched."

# Remove shortcuts
$desktop = Join-Path ([Environment]::GetFolderPath("Desktop")) "$ProductName.lnk"
if (Test-Path $desktop) { Remove-Item $desktop -Force; Write-Host "Removed desktop shortcut" }
$startDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\$ProductName"
if (Test-Path $startDir) { Remove-Item $startDir -Recurse -Force; Write-Host "Removed Start Menu folder" }

# Unregister
$key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\TheGoldMindProfessional"
if (Test-Path $key) { Remove-Item $key -Recurse -Force; Write-Host "Removed uninstall registry key" }

# Preserve user logs/config backup unless full wipe requested
$preserve = @("logs", "backup", "config")
if (Test-Path $InstallRoot) {
  if ($KeepLogs) {
    Write-Host "Keeping logs/backup/config per -KeepLogs"
    Get-ChildItem $InstallRoot -Force | Where-Object { $preserve -notcontains $_.Name } | Remove-Item -Recurse -Force
  } else {
    # Never delete user backup folder contents silently — move aside
    $safe = Join-Path $env:LOCALAPPDATA "THE GOLD MIND PROFESSIONAL.backup.$(Get-Date -Format yyyyMMddHHmmss)"
    if (Test-Path (Join-Path $InstallRoot "backup")) {
      Copy-Item (Join-Path $InstallRoot "backup") $safe -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "User backup copied to $safe"
    }
    if (Test-Path (Join-Path $InstallRoot "config")) {
      $cfgSafe = "$safe-config"
      Copy-Item (Join-Path $InstallRoot "config") $cfgSafe -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "User config copied to $cfgSafe"
    }
    Remove-Item $InstallRoot -Recurse -Force
  }
}

Write-Host "Uninstall complete. Core Trading Engine / MT5 installs were not touched."
