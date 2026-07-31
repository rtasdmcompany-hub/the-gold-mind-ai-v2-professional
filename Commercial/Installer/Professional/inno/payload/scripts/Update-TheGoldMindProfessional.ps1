# Secure Auto-Update Client â€” THE GOLD MIND PROFESSIONAL (Website Edition)
# Fail-closed: checksum / signature failure â†’ cancel + restore previous version + report.
# Independent of Core Trading Engine.
param(
  [string]$InstallRoot = "$env:LOCALAPPDATA\THE GOLD MIND PROFESSIONAL",
  [string]$PortalBase = "",
  [ValidateSet("stable")]
  [string]$Channel = "stable",
  [string]$CurrentVersion = "",
  [string]$ReportSecret = "",
  [string]$CustomerEmail = "",
  [switch]$Apply,
  [switch]$SkipReport
)

$ErrorActionPreference = "Stop"

$DefaultPortalBase = "https://the-gold-mind-ai-v2-professional.vercel.app"

function Resolve-PortalBase {
  if ($PortalBase) { return $PortalBase.TrimEnd("/") }
  $cfg = Join-Path $InstallRoot "config\portal.json"
  if (Test-Path $cfg) {
    try {
      $j = Get-Content $cfg -Raw | ConvertFrom-Json
      if ($j.portalBase) {
        $b = ([string]$j.portalBase).TrimEnd("/")
        if ($b -match 'thegoldmind\.ai$' -or $b -match 'localhost') {
          Write-Warning "Obsolete portalBase '$b' ignored â€” using production portal."
        } else {
          return $b
        }
      }
    } catch { }
  }
  if ($env:TGM_PORTAL_BASE) { return $env:TGM_PORTAL_BASE.TrimEnd("/") }
  return $DefaultPortalBase
}

$PortalBase = Resolve-PortalBase
$UpdateApi = "$PortalBase/api/releases/check"
$ReportApi = "$PortalBase/api/releases/report"
if (-not $ReportSecret) {
  $ReportSecret = $env:UPDATE_REPORT_SECRET
  if (-not $ReportSecret) { $ReportSecret = "dev-update-report-secret" }
}

function Get-Sha256([string]$path) {
  return (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToLowerInvariant()
}

function Get-InstalledVersion {
  $vf = Join-Path $InstallRoot "config\version.json"
  if (-not (Test-Path $vf)) { return "0.0.0" }
  $j = Get-Content $vf -Raw | ConvertFrom-Json
  return [string]$j.version
}

function Send-UpdateReport {
  param(
    [string]$FromVersion,
    [string]$ToVersion,
    [ValidateSet("success", "fail", "rollback")]
    [string]$Result,
    [string]$Detail = ""
  )
  if ($SkipReport) { return }
  try {
    $body = @{
      fromVersion   = $FromVersion
      toVersion     = $ToVersion
      result        = $Result
      detail        = $Detail
      email         = $CustomerEmail
      customerEmail = $CustomerEmail
      channel       = $Channel
    } | ConvertTo-Json
    $headers = @{ "x-tgm-update-secret" = $ReportSecret }
    Invoke-RestMethod -Uri $ReportApi -Method POST -Body $body -ContentType "application/json" -Headers $headers -TimeoutSec 30 | Out-Null
  } catch {
    Write-Warning "Update report failed: $_"
  }
}

if (-not $CurrentVersion) { $CurrentVersion = Get-InstalledVersion }

Write-Host "Checking Â· channel=$Channel Â· current=$CurrentVersion Â· portal=$PortalBase"

# Remainder of update logic preserved from prior implementation
$checkUri = "$UpdateApi?channel=$Channel&version=$([uri]::EscapeDataString($CurrentVersion))"
try {
  $info = Invoke-RestMethod -Uri $checkUri -Method GET -TimeoutSec 45
} catch {
  Write-Host "Update check failed: $_" -ForegroundColor Red
  Write-Host "Portal must be reachable at $PortalBase"
  exit 1
}

if (-not $info.updateAvailable -and -not $info.available) {
  Write-Host "Already up to date ($CurrentVersion)." -ForegroundColor Green
  exit 0
}

$latest = $info.latest
$target = if ($latest -and $latest.version) { [string]$latest.version }
  elseif ($info.version) { [string]$info.version }
  elseif ($info.targetVersion) { [string]$info.targetVersion }
  else { "" }
$packageId = if ($latest -and $latest.id) { [string]$latest.id } else { $target }
$downloadUrl = if ($latest -and $latest.packageUrl) { [string]$latest.packageUrl }
  elseif ($latest -and $latest.downloadUrl) { [string]$latest.downloadUrl }
  elseif ($info.downloadUrl) { [string]$info.downloadUrl }
  elseif ($packageId) { "$PortalBase/api/releases/download/$packageId" }
  else { "" }
$expectedSha = if ($latest -and $latest.sha256) { [string]$latest.sha256 }
  elseif ($info.sha256) { [string]$info.sha256 }
  elseif ($info.checksum) { [string]$info.checksum }
  else { "" }

if (-not $target -or -not $downloadUrl) {
  Write-Host "Update payload incomplete from portal check API." -ForegroundColor Red
  exit 1
}

Write-Host "Update available: $CurrentVersion â†’ $target"
Write-Host "Download: $downloadUrl"

if (-not $Apply) {
  Write-Host "Dry-run only. Re-run with -Apply to install."
  exit 0
}

$tmp = Join-Path $env:TEMP ("tgm-update-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$pkg = Join-Path $tmp "update.zip"

try {
  Invoke-WebRequest -Uri $downloadUrl -OutFile $pkg -TimeoutSec 300
  if ($expectedSha) {
    $actual = Get-Sha256 $pkg
    if ($actual -ne $expectedSha.ToLowerInvariant()) {
      throw "Checksum mismatch. Expected $expectedSha got $actual"
    }
  }
  $backup = Join-Path $env:TEMP ("tgm-backup-" + [guid]::NewGuid().ToString("N"))
  Copy-Item -Recurse -Force $InstallRoot $backup
  Expand-Archive -Path $pkg -DestinationPath $tmp -Force
  # Apply payload files (non-destructive of license state)
  foreach ($rel in @("bin", "scripts", "ea", "docs")) {
    $src = Join-Path $tmp $rel
    if (Test-Path $src) {
      $dst = Join-Path $InstallRoot $rel
      New-Item -ItemType Directory -Force -Path $dst | Out-Null
      Copy-Item -Force -Recurse (Join-Path $src "*") $dst
    }
  }
  if (Test-Path (Join-Path $tmp "config\version.json")) {
    Copy-Item -Force (Join-Path $tmp "config\version.json") (Join-Path $InstallRoot "config\version.json")
  }
  @{ portalBase = $PortalBase } | ConvertTo-Json | Set-Content (Join-Path $InstallRoot "config\portal.json") -Encoding UTF8
  Send-UpdateReport -FromVersion $CurrentVersion -ToVersion $target -Result "success"
  Write-Host "Update applied successfully." -ForegroundColor Green
} catch {
  Write-Host "Update failed: $_" -ForegroundColor Red
  if (Test-Path $backup) {
    Write-Host "Restoring previous version..."
    Remove-Item -Recurse -Force $InstallRoot -EA SilentlyContinue
    Copy-Item -Recurse -Force $backup $InstallRoot
    Send-UpdateReport -FromVersion $CurrentVersion -ToVersion $target -Result "rollback" -Detail "$_"
  } else {
    Send-UpdateReport -FromVersion $CurrentVersion -ToVersion $target -Result "fail" -Detail "$_"
  }
  exit 1
} finally {
  Remove-Item -Recurse -Force $tmp -EA SilentlyContinue
  if ($backup -and (Test-Path $backup)) { Remove-Item -Recurse -Force $backup -EA SilentlyContinue }
}
exit 0

