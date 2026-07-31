<#
.SYNOPSIS
  Validate Setup.exe packaging (structure + timed silent install).
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$SetupExe,
  [string]$InstallRoot = "$env:TEMP\TGM-VALIDATE-INSTALL",
  [switch]$SkipActivation,
  [switch]$SkipMt5,
  [int]$SilentTimeoutSec = 120
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Yellow }

if (-not (Test-Path $SetupExe)) { throw "Setup.exe NOT FOUND: $SetupExe" }

Write-Step "Artifact checks"
$setupHash = (Get-FileHash -Algorithm SHA256 $SetupExe).Hash.ToLowerInvariant()
Write-Host "  Setup.exe SHA-256: $setupHash"
$size = (Get-Item $SetupExe).Length
if ($size -lt 350KB) { throw "Setup.exe suspiciously small ($size bytes)" }
Write-Host "  Size: $size bytes - OK"

Write-Step "Payload zip structural check"
$payloadZip = Join-Path (Split-Path $SetupExe -Parent) "..\..\..\Installer\Professional\tools\setup\payload.zip"
# Resolve relative from Releases/1.0.0/installer -> Commercial/Installer/...
$cand = @(
  (Join-Path (Split-Path $SetupExe -Parent) "..\..\..\Installer\Professional\tools\setup\payload.zip"),
  (Join-Path $PSScriptRoot "..\tools\setup\payload.zip")
)
$pz = $null
foreach ($c in $cand) {
  $r = Resolve-Path $c -EA SilentlyContinue
  if ($r) { $pz = $r.Path; break }
}
if (-not $pz) { throw "payload.zip NOT FOUND for structural validation" }
if (Test-Path $InstallRoot) { Remove-Item $InstallRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($pz, $InstallRoot)
$ea = Join-Path $InstallRoot "ea\TheGoldMindAI_Professional.ex5"
$launcher = Join-Path $InstallRoot "bin\TGM-Professional-Launcher.exe"
if (-not (Test-Path $ea)) { throw "EA missing in payload" }
if (-not (Test-Path $launcher)) { throw "Launcher missing in payload" }
foreach ($s in @("Deploy-EA-To-MT5.ps1", "Activate-License.ps1", "PostInstall-Wizard.ps1", "Update-TheGoldMindProfessional.ps1")) {
  if (-not (Test-Path (Join-Path $InstallRoot "scripts\$s"))) { throw "Missing script: $s" }
}
$portalCfg = Join-Path $InstallRoot "config\portal.json"
if (-not (Test-Path $portalCfg)) { throw "portal.json missing after install" }
$pb = (Get-Content $portalCfg -Raw | ConvertFrom-Json).portalBase
if ($pb -notmatch 'the-gold-mind-ai-v2-professional\.vercel\.app') {
  throw "portalBase must be production Vercel URL, got: $pb"
}
if ($pb -match 'thegoldmind\.ai') { throw "Obsolete thegoldmind.ai still packaged" }
Write-Host "  Portal base OK: $pb" -ForegroundColor Green
Write-Host "  Payload structure OK" -ForegroundColor Green

if ($SkipActivation) {
  Write-Step "Mandatory activation marker check"
  # Compiled string constants land at arbitrary byte offsets inside the PE image (IL bytes,
  # embedded payload.zip resource bytes, etc. all precede them). A naive single-pass UTF-16
  # decode of the whole file can start out of phase with a given string's 2-byte char boundary
  # and miss a real, correctly-embedded literal. Decode at both possible byte alignments before
  # concluding a marker is actually missing.
  $setupBytes = [IO.File]::ReadAllBytes($SetupExe)
  $binaryTextEven = [Text.Encoding]::Unicode.GetString($setupBytes)
  $binaryTextOdd = [Text.Encoding]::Unicode.GetString($setupBytes, 1, $setupBytes.Length - 1)
  foreach ($marker in @(
      "SILENT install requires TGM_LICENSE_EMAIL and TGM_LICENSE_KEY.",
      "License activation failed:",
      "License key is required."
    )) {
    if (-not $binaryTextEven.Contains($marker) -and -not $binaryTextOdd.Contains($marker)) {
      throw "Strict activation marker missing from Setup.exe: $marker"
    }
  }
  Write-Host "  Strict email/key + activation-failure gates embedded - OK" -ForegroundColor Green
  Write-Step "Validation PASSED"
  Write-Host "Setup.exe structure and mandatory activation gates are valid." -ForegroundColor Green
  exit 0
}

Write-Step "Timed silent Setup.exe install"
$email = [string][Environment]::GetEnvironmentVariable("TGM_LICENSE_EMAIL")
$key = [string][Environment]::GetEnvironmentVariable("TGM_LICENSE_KEY")
$email = $email.Trim()
$key = $key.Trim()
if (-not $email -or -not $key) {
  throw "Live silent validation requires TGM_LICENSE_EMAIL and TGM_LICENSE_KEY."
}
$defaultRoot = Join-Path $env:LOCALAPPDATA "THE GOLD MIND PROFESSIONAL"
if (Test-Path $defaultRoot) { Remove-Item $defaultRoot -Recurse -Force -EA SilentlyContinue }
$p = Start-Process -FilePath $SetupExe -ArgumentList "/SILENT" -PassThru
$sw = [Diagnostics.Stopwatch]::StartNew()
while (-not $p.HasExited -and $sw.Elapsed.TotalSeconds -lt $SilentTimeoutSec) {
  Start-Sleep -Seconds 2
}
if (-not $p.HasExited) {
  Write-Warning "Silent setup exceeded ${SilentTimeoutSec}s - terminating"
  try { $p.Kill() } catch { }
  throw "Silent Setup.exe hung"
}
Write-Host "  Setup exit code: $($p.ExitCode)"
if ($p.ExitCode -ne 0) { throw "Silent Setup.exe failed with exit $($p.ExitCode)" }

$ea2 = Join-Path $defaultRoot "ea\TheGoldMindAI_Professional.ex5"
if (-not (Test-Path $ea2)) { throw "EA not found after silent install: $ea2" }
Write-Host "  Installed EA: $ea2" -ForegroundColor Green

$uninst = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\TheGoldMindProfessional" -EA SilentlyContinue
if (-not $uninst) { throw "Uninstall registry entry missing" }
Write-Host "  Uninstall entry present" -ForegroundColor Green

$startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\THE GOLD MIND PROFESSIONAL"
if (-not (Test-Path $startMenu)) { throw "Start Menu folder missing" }
Write-Host "  Start Menu present" -ForegroundColor Green

if (-not $SkipMt5) {
  Write-Step "MT5 detect (list only)"
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $defaultRoot "scripts\Deploy-EA-To-MT5.ps1") -InstallRoot $defaultRoot -ListOnly
  Write-Host "  ListOnly exit: $LASTEXITCODE"
}

Write-Step "Validation PASSED"
Write-Host "Setup.exe works correctly." -ForegroundColor Green
exit 0