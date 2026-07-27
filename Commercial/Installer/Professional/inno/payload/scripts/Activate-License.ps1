# THE GOLD MIND PROFESSIONAL - License activation wizard (commercial).
# Calls Customer Portal activation API. Does NOT touch Core Trading Engine.
param(
  [string]$InstallRoot = "$env:LOCALAPPDATA\THE GOLD MIND PROFESSIONAL",
  [string]$PortalBase = "",
  [string]$Email = "",
  [string]$LicenseKey = "",
  [switch]$GoogleLogin,
  [switch]$Silent
)

$ErrorActionPreference = "Stop"

# Canonical production Customer Portal for THIS product only
$DefaultPortalBase = "https://the-gold-mind-ai-v2-professional.vercel.app"

function Write-Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Yellow }

function Get-MachineFingerprint {
  $raw = @(
    $env:COMPUTERNAME,
    $env:USERNAME,
    (Get-CimInstance Win32_ComputerSystemProduct -EA SilentlyContinue).UUID,
    (Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1).ProcessorId
  ) -join "|"
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [Text.Encoding]::UTF8.GetBytes($raw)
  return ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace "-", "").ToLowerInvariant()
}

function Get-PortalBase {
  if ($PortalBase) { return $PortalBase.TrimEnd("/") }
  $cfg = Join-Path $InstallRoot "config\portal.json"
  if (Test-Path $cfg) {
    try {
      $j = Get-Content $cfg -Raw | ConvertFrom-Json
      if ($j.portalBase) {
        $b = ([string]$j.portalBase).TrimEnd("/")
        # Block obsolete / non-existent domains from older installer builds
        if ($b -match 'thegoldmind\.ai$' -or $b -match 'localhost') {
          Write-Warning "Obsolete portalBase '$b' ignored — using production portal."
        } else {
          return $b
        }
      }
    } catch { }
  }
  if ($env:TGM_PORTAL_BASE) { return $env:TGM_PORTAL_BASE.TrimEnd("/") }
  return $DefaultPortalBase
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor DarkYellow
Write-Host "  THE GOLD MIND PROFESSIONAL - License Activation" -ForegroundColor Yellow
Write-Host "========================================================"
Write-Host "  Commercial entitlement only - Core Engine untouched."
Write-Host ""

$base = Get-PortalBase
Write-Host "Portal: $base"

if ($GoogleLogin) {
  Write-Step "Google Login"
  $url = "$base/login?provider=google&callbackUrl=%2Fportal%2Flicenses"
  Write-Host "  Opening production portal Google Sign-In..."
  Write-Host "  $url"
  try { Start-Process $url } catch { Write-Warning "Could not open browser: $_" }
  Write-Host ""
  Write-Host "  After Google sign-in:"
  Write-Host "    1. Open Licenses in the Customer Portal"
  Write-Host "    2. Copy your license key"
  Write-Host "    3. Return here and paste the key below"
  if (-not $Silent) { Read-Host "Press Enter when ready to paste your license key" | Out-Null }
}

if (-not $Email) {
  if ($Silent) { throw "Email required in Silent mode." }
  $Email = Read-Host "Customer email (portal login)"
}
if (-not $LicenseKey) {
  if ($Silent) { throw "LicenseKey required in Silent mode." }
  $LicenseKey = Read-Host "License key (paste from portal)"
}

$fp = Get-MachineFingerprint
$deviceName = $env:COMPUTERNAME

Write-Step "Activating machine"
$body = @{
  action            = "activate"
  licenseKey        = $LicenseKey.Trim()
  customerEmail     = $Email.Trim().ToLowerInvariant()
  deviceFingerprint = $fp
  deviceName        = $deviceName
} | ConvertTo-Json

$uri = "$base/api/licenses/actions"
try {
  $resp = Invoke-RestMethod -Uri $uri -Method POST -Body $body -ContentType "application/json" -TimeoutSec 60
} catch {
  Write-Host "  Activation API failed: $_" -ForegroundColor Red
  Write-Host "  Ensure the Customer Portal is reachable and the key is valid."
  Write-Host "  Portal: $base"
  Write-Host "  You can retry later: scripts\Activate-License.ps1"
  exit 1
}

if (-not $resp.ok -and -not $resp.license -and -not $resp.deviceId) {
  $err = if ($resp.error) { $resp.error } else { ($resp | ConvertTo-Json -Compress) }
  Write-Host "  Activation rejected: $err" -ForegroundColor Red
  exit 1
}

$stateDir = Join-Path $InstallRoot "config"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
@{
  email           = $Email.Trim().ToLowerInvariant()
  activatedAt     = (Get-Date).ToUniversalTime().ToString("o")
  portalBase      = $base
  deviceId        = $resp.deviceId
  licenseId       = $(if ($resp.license.id) { $resp.license.id } else { $resp.licenseId })
  status          = $(if ($resp.license.status) { $resp.license.status } else { "active" })
  fingerprintHash = $fp.Substring(0, [Math]::Min(16, $fp.Length)) + "…"
  googleLoginUsed = [bool]$GoogleLogin
} | ConvertTo-Json | Set-Content (Join-Path $stateDir "license-activation.json") -Encoding UTF8

@{ portalBase = $base } | ConvertTo-Json | Set-Content (Join-Path $stateDir "portal.json") -Encoding UTF8

Write-Host "  Activation OK" -ForegroundColor Green
Write-Host "  Device: $($resp.deviceId)"
Write-Host "  Subscription verified via portal."
exit 0
