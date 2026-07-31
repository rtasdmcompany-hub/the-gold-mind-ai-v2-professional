# THE GOLD MIND PROFESSIONAL â€” Installation Wizard (commercial shell)
# Independent of Core Trading Engine / Strategy / Risk / Recovery / Execution / Magic.
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\Install-TheGoldMindProfessional.ps1
#   powershell -ExecutionPolicy Bypass -File .\Install-TheGoldMindProfessional.ps1 -Silent -Channel stable

param(
  [string]$InstallRoot = "$env:LOCALAPPDATA\THE GOLD MIND PROFESSIONAL",
  [ValidateSet("stable", "rc", "development")]
  [string]$Channel = "stable",
  [switch]$Silent,
  [switch]$SkipShortcuts
)

$ErrorActionPreference = "Stop"
$ProductName = "THE GOLD MIND PROFESSIONAL"
$Publisher = "RTAS Group of Companies"
$Version = "2.0.0"
$BuildNumber = "21060"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackagesDir = Join-Path $ScriptDir "..\packages"

function Write-Banner {
  Write-Host ""
  Write-Host "========================================================" -ForegroundColor DarkYellow
  Write-Host "  $ProductName" -ForegroundColor Yellow
  Write-Host "  Professional Installation Wizard" -ForegroundColor Yellow
  Write-Host "  $Publisher" -ForegroundColor DarkYellow
  Write-Host "========================================================"
  Write-Host "  Commercial shell only â€” Core Trading Engine untouched."
  Write-Host ""
}

function Write-Step([string]$msg) {
  Write-Host ""
  Write-Host "==> $msg" -ForegroundColor Yellow
}

function Test-SystemRequirements {
  Write-Step "Step 1 Â· System requirement validation"
  $os = [System.Environment]::OSVersion.Version
  if ($os.Major -lt 10) { throw "Windows 10 or later required." }
  $arch = [Environment]::Is64BitOperatingSystem
  if (-not $arch) { Write-Warning "64-bit Windows recommended." }
  $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
  if ($ramGB -lt 4) { Write-Warning "Recommended RAM is 4 GB+. Detected: ${ramGB} GB" }
  $freeGB = [math]::Round((Get-PSDrive -Name ($InstallRoot.Substring(0, 1))).Free / 1GB, 1)
  if ($freeGB -lt 0.5) { Write-Warning "Low disk space on install drive: ${freeGB} GB free" }
  Write-Host "  OS: Windows $($os.Major).$($os.Minor) Â· RAM: ${ramGB} GB Â· Free: ${freeGB} GB Â· OK"
}

function Find-MetaTrader5 {
  Write-Step "Step 2 Â· MT5 detection"
  $candidates = @(
    "$env:ProgramFiles\MetaTrader 5",
    "${env:ProgramFiles(x86)}\MetaTrader 5",
    "$env:APPDATA\MetaQuotes\Terminal"
  )
  $found = @()
  foreach ($c in $candidates) {
    if (Test-Path $c) {
      $found += $c
      Write-Host "  Found: $c"
    }
  }
  $terminals = @(Get-ChildItem "$env:APPDATA\MetaQuotes\Terminal" -Directory -ErrorAction SilentlyContinue)
  if ($terminals.Count -gt 0) {
    Write-Host "  MetaQuotes terminal profiles: $($terminals.Count)"
    foreach ($t in $terminals | Select-Object -First 5) {
      Write-Host "    - $($t.Name)"
    }
  } else {
    Write-Warning "  No MetaQuotes Terminal folder found. Commercial shell can still install."
  }
  $mt5Json = @{
    detectedPaths = $found
    terminalProfiles = @($terminals | ForEach-Object { $_.Name })
    detectedAt = (Get-Date).ToUniversalTime().ToString("o")
  } | ConvertTo-Json -Depth 4
  return $mt5Json
}

function New-ProductFolders([string]$root) {
  Write-Step "Step 3 Â· Configuration / Log / Backup folders"
  $dirs = @(
    $root,
    (Join-Path $root "bin"),
    (Join-Path $root "config"),
    (Join-Path $root "logs"),
    (Join-Path $root "backup"),
    (Join-Path $root "updates"),
    (Join-Path $root "packages"),
    (Join-Path $root "rollback"),
    (Join-Path $root "icons")
  )
  foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    Write-Host "  $d"
  }
}

function Install-PackageFiles([string]$root, [string]$mt5Json) {
  Write-Step "Step 4 Â· Installing commercial package files"
  $manifestName = switch ($Channel) {
    "rc" { "manifest.rc.json" }
    "development" { "manifest.development.json" }
    default { "manifest.stable.json" }
  }
  $manifestSrc = Join-Path $PackagesDir $manifestName
  $readmeSrc = Join-Path $PackagesDir "README_INSTALL.txt"
  if (Test-Path $manifestSrc) {
    Copy-Item -Force $manifestSrc (Join-Path $root "config\installed-manifest.json")
  } else {
    Copy-Item -Force (Join-Path $PackagesDir "manifest.stable.json") (Join-Path $root "config\installed-manifest.json") -ErrorAction SilentlyContinue
  }
  Copy-Item -Force $readmeSrc (Join-Path $root "README.txt") -ErrorAction SilentlyContinue

  # Application icon for Desktop / Start Menu shortcuts
  $iconSrc = Join-Path $ScriptDir "..\inno\payload\icons\tgm-professional.ico"
  $iconDir = Join-Path $root "icons"
  New-Item -ItemType Directory -Force -Path $iconDir | Out-Null
  if (Test-Path $iconSrc) {
    Copy-Item -Force $iconSrc (Join-Path $iconDir "tgm-professional.ico")
  } else {
    @"
Place branded .ico files here for Desktop / Start Menu shortcuts.
Recommended: tgm-professional.ico (multi-resolution).
"@ | Set-Content -Path (Join-Path $iconDir "README_ICONS.txt") -Encoding UTF8
  }

  $versionJson = @{
    product = $ProductName
    version = $Version
    buildNumber = $BuildNumber
    channel = $Channel
    installedAt = (Get-Date).ToUniversalTime().ToString("o")
    installRoot = $root
    coreNote = "Core Trading Engine is certified and separate â€” installer does not alter strategy/risk/execution/magic."
  } | ConvertTo-Json
  Set-Content -Path (Join-Path $root "config\version.json") -Value $versionJson -Encoding UTF8
  Set-Content -Path (Join-Path $root "config\mt5-detection.json") -Value $mt5Json -Encoding UTF8

  $launcher = Join-Path $root "bin\TGM-Professional-Launcher.cmd"
  @"
@echo off
title $ProductName
echo ========================================================
echo  $ProductName
echo  Version $Version Build $BuildNumber ($Channel)
echo ========================================================
echo  Open MetaTrader 5 and attach the Professional EA from
echo  your licensed package (Customer Portal Downloads).
echo  Core Trading Engine remains the sole execution authority.
echo ========================================================
pause
"@ | Set-Content -Path $launcher -Encoding ASCII

  Set-Content -Path (Join-Path $root "bin\VERSION.txt") -Value "$Version`r`n$BuildNumber`r`n$Channel" -Encoding ASCII
  return $launcher
}

function New-Shortcuts([string]$launcher, [string]$root) {
  if ($SkipShortcuts) { return }
  Write-Step "Step 5 Â· Desktop and Start Menu shortcuts"
  $wsh = New-Object -ComObject WScript.Shell
  $iconPath = Join-Path $root "icons\tgm-professional.ico"
  $desktop = Join-Path $wsh.SpecialFolders.Item("Desktop") "$ProductName.lnk"
  $sc = $wsh.CreateShortcut($desktop)
  $sc.TargetPath = $launcher
  $sc.WorkingDirectory = Split-Path $launcher
  $sc.Description = "$ProductName â€” Commercial Shell"
  if (Test-Path $iconPath) { $sc.IconLocation = "$iconPath,0" }
  $sc.Save()
  Write-Host "  Desktop: $desktop"

  $startDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\$ProductName"
  New-Item -ItemType Directory -Force -Path $startDir | Out-Null
  $startLnk = Join-Path $startDir "$ProductName.lnk"
  $sc2 = $wsh.CreateShortcut($startLnk)
  $sc2.TargetPath = $launcher
  $sc2.WorkingDirectory = Split-Path $launcher
  $sc2.Description = $ProductName
  if (Test-Path $iconPath) { $sc2.IconLocation = "$iconPath,0" }
  $sc2.Save()
  Write-Host "  Start Menu: $startLnk"

  $uninstLnk = Join-Path $startDir "Uninstall $ProductName.lnk"
  $uninstaller = Join-Path $ScriptDir "Uninstall-TheGoldMindProfessional.ps1"
  $sc3 = $wsh.CreateShortcut($uninstLnk)
  $sc3.TargetPath = "powershell.exe"
  $sc3.Arguments = "-ExecutionPolicy Bypass -File `"$uninstaller`" -InstallRoot `"$root`""
  $sc3.WorkingDirectory = $root
  $sc3.Description = "Uninstall $ProductName"
  $sc3.Save()
}

function Register-Uninstall([string]$root) {
  Write-Step "Step 6 Â· Safe uninstall registration"
  $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\TheGoldMindProfessional"
  New-Item -Path $key -Force | Out-Null
  $props = @{
    DisplayName     = $ProductName
    Publisher       = $Publisher
    DisplayVersion  = $Version
    InstallLocation = $root
    InstallDate     = (Get-Date -Format yyyyMMdd)
    EstimatedSize   = 8192
    HelpLink        = "https://the-gold-mind-ai-v2-professional.vercel.app/portal/support"
    URLInfoAbout    = "https://the-gold-mind-ai-v2-professional.vercel.app"
  }
  foreach ($k in $props.Keys) {
    New-ItemProperty -Path $key -Name $k -Value $props[$k] -PropertyType String -Force | Out-Null
  }
  $uninstaller = Join-Path $ScriptDir "Uninstall-TheGoldMindProfessional.ps1"
  New-ItemProperty -Path $key -Name "UninstallString" -Value "powershell.exe -ExecutionPolicy Bypass -File `"$uninstaller`" -InstallRoot `"$root`"" -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $key -Name "NoModify" -Value 1 -PropertyType DWord -Force | Out-Null
  New-ItemProperty -Path $key -Name "NoRepair" -Value 1 -PropertyType DWord -Force | Out-Null
  Write-Host "  Registered: $key"
}

# --- Wizard ---
if (-not $Silent) {
  Write-Banner
  Write-Host "Channel: $Channel Â· Version: $Version Â· Build: $BuildNumber"
  $custom = Read-Host "Install path [$InstallRoot]"
  if ($custom) { $InstallRoot = $custom }
  $ch = Read-Host "Release channel [stable] ($Channel)"
  if ($ch$ch -match '^(stable)) { $Channel = $ch }
}

Test-SystemRequirements
$mt5Json = Find-MetaTrader5
New-ProductFolders -root $InstallRoot
$launcher = Install-PackageFiles -root $InstallRoot -mt5Json $mt5Json
New-Shortcuts -launcher $launcher -root $InstallRoot
Register-Uninstall -root $InstallRoot

Write-Step "Installation complete"
Write-Host "  Installed to : $InstallRoot"
Write-Host "  Channel      : $Channel"
Write-Host "  Version      : $Version ($BuildNumber)"
Write-Host "  Next: Activate license in Customer Portal, then attach EA in MT5."
Write-Host "  Updates: Update-TheGoldMindProfessional.ps1 -Apply"
if (-not $Silent) { Read-Host "Press Enter to exit" }
) { $Channel = $ch }
}

Test-SystemRequirements
$mt5Json = Find-MetaTrader5
New-ProductFolders -root $InstallRoot
$launcher = Install-PackageFiles -root $InstallRoot -mt5Json $mt5Json
New-Shortcuts -launcher $launcher -root $InstallRoot
Register-Uninstall -root $InstallRoot

Write-Step "Installation complete"
Write-Host "  Installed to : $InstallRoot"
Write-Host "  Channel      : $Channel"
Write-Host "  Version      : $Version ($BuildNumber)"
Write-Host "  Next: Activate license in Customer Portal, then attach EA in MT5."
Write-Host "  Updates: Update-TheGoldMindProfessional.ps1 -Apply"
if (-not $Silent) { Read-Host "Press Enter to exit" }
