# Secure Auto-Update Client — THE GOLD MIND PROFESSIONAL (Website Edition)
# Fail-closed: checksum / signature failure → cancel + restore previous version + report.
# Independent of Core Trading Engine.
param(
  [string]$InstallRoot = "$env:LOCALAPPDATA\THE GOLD MIND PROFESSIONAL",
  [string]$PortalBase = "http://localhost:3000",
  [ValidateSet("stable", "rc", "development")]
  [string]$Channel = "stable",
  [string]$CurrentVersion = "",
  [string]$ReportSecret = "",
  [string]$CustomerEmail = "",
  [switch]$Apply,
  [switch]$SkipReport
)

$ErrorActionPreference = "Stop"
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
    [string]$Detail,
    [string]$PackageId = ""
  )
  if ($SkipReport) { return }
  try {
    $body = @{
      fromVersion = $FromVersion
      toVersion   = $ToVersion
      channel     = $Channel
      result      = $Result
      detail      = $Detail
      packageId   = $PackageId
      email       = $CustomerEmail
    } | ConvertTo-Json
    Invoke-RestMethod -Uri $ReportApi -Method POST -Body $body -ContentType "application/json" -Headers @{
      "x-tgm-update-secret" = $ReportSecret
    } | Out-Null
    Write-Host "  Telemetry reported: $Result"
  } catch {
    Write-Warning "  Could not report update result to portal: $_"
  }
}

function Invoke-Backup {
  Write-Host "==> Pre-update backup (config + settings + log preservation)" -ForegroundColor Yellow
  $stamp = Get-Date -Format "yyyyMMddHHmmss"
  $dest = Join-Path $InstallRoot "backup\$stamp"
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  foreach ($name in @("config", "logs")) {
    $src = Join-Path $InstallRoot $name
    if (Test-Path $src) {
      Copy-Item $src (Join-Path $dest $name) -Recurse -Force
    }
  }
  # Never overwrite critical user data — backup only
  $rb = Join-Path $InstallRoot "rollback\previous"
  if (Test-Path (Join-Path $InstallRoot "bin")) {
    if (Test-Path $rb) { Remove-Item $rb -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Force -Path $rb | Out-Null
    Copy-Item (Join-Path $InstallRoot "bin") (Join-Path $rb "bin") -Recurse -Force
    Copy-Item (Join-Path $InstallRoot "config\version.json") (Join-Path $rb "version.json") -Force -ErrorAction SilentlyContinue
    if (Test-Path (Join-Path $InstallRoot "config\installed-manifest.json")) {
      Copy-Item (Join-Path $InstallRoot "config\installed-manifest.json") (Join-Path $rb "installed-manifest.json") -Force
    }
  }
  Write-Host "  Backup: $dest"
  Write-Host "  Rollback package: $rb"
  return $dest
}

function Restore-Rollback {
  param([string]$FromVersion, [string]$ToVersion, [string]$PackageId = "", [string]$Reason = "verification failed")
  Write-Host "==> $Reason — restoring previous version" -ForegroundColor Red
  $rb = Join-Path $InstallRoot "rollback\previous"
  if (-not (Test-Path $rb)) {
    Write-Error "No rollback package available. Current install left untouched where possible."
    Send-UpdateReport -FromVersion $FromVersion -ToVersion $ToVersion -Result "fail" -Detail $Reason -PackageId $PackageId
    return
  }
  if (Test-Path (Join-Path $rb "bin")) {
    Remove-Item (Join-Path $InstallRoot "bin") -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $rb "bin") (Join-Path $InstallRoot "bin") -Recurse -Force
  }
  if (Test-Path (Join-Path $rb "version.json")) {
    Copy-Item (Join-Path $rb "version.json") (Join-Path $InstallRoot "config\version.json") -Force
  }
  if (Test-Path (Join-Path $rb "installed-manifest.json")) {
    Copy-Item (Join-Path $rb "installed-manifest.json") (Join-Path $InstallRoot "config\installed-manifest.json") -Force
  }
  Write-Host "Previous version restored. Update cancelled. Customer informed via console."
  Send-UpdateReport -FromVersion $FromVersion -ToVersion $ToVersion -Result "rollback" -Detail $Reason -PackageId $PackageId
}

if (-not $CurrentVersion) { $CurrentVersion = Get-InstalledVersion }

Write-Host "========================================================" -ForegroundColor DarkYellow
Write-Host " THE GOLD MIND PROFESSIONAL — Secure Auto Update" -ForegroundColor Yellow
Write-Host "========================================================"
Write-Host "Checking · channel=$Channel · current=$CurrentVersion · portal=$PortalBase"

$uri = "$UpdateApi`?channel=$Channel&version=$([uri]::EscapeDataString($CurrentVersion))&edition=Professional"
try {
  $resp = Invoke-RestMethod -Uri $uri -Method GET
} catch {
  Write-Warning "Update check failed (network). Keeping current version."
  exit 0
}

if (-not $resp.updateAvailable) {
  Write-Host "Already up to date ($CurrentVersion)."
  exit 0
}

$latest = $resp.latest
Write-Host ""
Write-Host "Update available: $($latest.version) build $($latest.buildNumber)" -ForegroundColor Green
Write-Host "Release notes:"
Write-Host "  $($latest.releaseNotes)"
Write-Host "SHA-256: $($latest.sha256)"
Write-Host "Signature: $($latest.signatureStatus) · $($latest.signatureSubject)"
Write-Host "Size: $([math]::Round($latest.packageSizeBytes/1KB,1)) KB · Core frozen: $($latest.compatibility.coreFrozen)"

if (-not $Apply) {
  Write-Host ""
  Write-Host "Run with -Apply to download, verify, and install."
  Write-Host "  .\Update-TheGoldMindProfessional.ps1 -Channel $Channel -Apply"
  exit 0
}

# HTTPS-only enforcement for non-localhost
if ($latest.packageUrl -notmatch '^https://' -and $latest.packageUrl -notmatch '^http://localhost' -and $latest.packageUrl -notmatch '^http://127\.0\.0\.1') {
  Write-Error "Refusing non-HTTPS package URL. Update cancelled. Previous version kept."
  Send-UpdateReport -FromVersion $CurrentVersion -ToVersion $latest.version -Result "fail" -Detail "non-https url" -PackageId $latest.id
  exit 1
}

$backup = Invoke-Backup
$pkgDir = Join-Path $InstallRoot "updates\download"
New-Item -ItemType Directory -Force -Path $pkgDir | Out-Null
$pkgPath = Join-Path $pkgDir "package-$($latest.version).zip"

Write-Host "==> Background download with progress"
try {
  Import-Module BitsTransfer -ErrorAction Stop
  Start-BitsTransfer -Source $latest.packageUrl -Destination $pkgPath -DisplayName "TGM Update $($latest.version)" -Description "THE GOLD MIND PROFESSIONAL secure update"
  Write-Host "  BITS transfer complete."
} catch {
  Write-Host "  BITS unavailable — using Invoke-WebRequest..."
  $ProgressPreference = "Continue"
  Invoke-WebRequest -Uri $latest.packageUrl -OutFile $pkgPath -UseBasicParsing
}

if (-not (Test-Path $pkgPath)) {
  Restore-Rollback -FromVersion $CurrentVersion -ToVersion $latest.version -PackageId $latest.id -Reason "download failed"
  exit 1
}

Write-Host "==> SHA-256 checksum validation"
$actual = Get-Sha256 $pkgPath
$expected = ([string]$latest.sha256).ToLowerInvariant()
if ($actual -ne $expected) {
  Write-Error "Checksum mismatch (tamper detection). Expected $expected got $actual"
  Remove-Item $pkgPath -Force -ErrorAction SilentlyContinue
  Restore-Rollback -FromVersion $CurrentVersion -ToVersion $latest.version -PackageId $latest.id -Reason "checksum mismatch"
  exit 1
}
Write-Host "  Checksum OK"

Write-Host "==> Digital signature verification"
$sigOk = $true
if ($latest.signatureRequired -eq $true) {
  $sig = Get-AuthenticodeSignature -FilePath $pkgPath
  if ($sig.Status -ne "Valid") {
    $sigOk = $false
    Write-Error "Digital signature invalid: $($sig.Status)"
  } else {
    Write-Host "  Authenticode Valid · $($sig.SignerCertificate.Subject)"
  }
} else {
  Write-Warning "  Signature not required for this channel package. Checksum passed."
}

if (-not $sigOk) {
  Restore-Rollback -FromVersion $CurrentVersion -ToVersion $latest.version -PackageId $latest.id -Reason "signature invalid"
  exit 1
}

Write-Host "==> Safe installation (bin only — config/user data preserved)"
try {
  $extract = Join-Path $InstallRoot "updates\extract"
  if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
  Expand-Archive -Path $pkgPath -DestinationPath $extract -Force

  # Apply commercial shell bin — never wipe user config/logs/backup
  if (Test-Path (Join-Path $extract "bin")) {
    Copy-Item (Join-Path $extract "bin\*") (Join-Path $InstallRoot "bin") -Recurse -Force
  }
  if (Test-Path (Join-Path $extract "config\package-manifest.json")) {
    Copy-Item (Join-Path $extract "config\package-manifest.json") (Join-Path $InstallRoot "config\installed-manifest.json") -Force
  }
  if (Test-Path (Join-Path $extract "README.txt")) {
    Copy-Item (Join-Path $extract "README.txt") (Join-Path $InstallRoot "README.txt") -Force
  }

  $versionJson = @{
    product        = "THE GOLD MIND PROFESSIONAL"
    version        = $latest.version
    buildNumber    = $latest.buildNumber
    channel        = $Channel
    installedAt    = (Get-Date).ToUniversalTime().ToString("o")
    previousBackup = $backup
    sha256         = $expected
    packageId      = $latest.id
  } | ConvertTo-Json
  Set-Content (Join-Path $InstallRoot "config\version.json") $versionJson -Encoding UTF8
} catch {
  Write-Error "Apply failed: $_"
  Restore-Rollback -FromVersion $CurrentVersion -ToVersion $latest.version -PackageId $latest.id -Reason "apply failed: $_"
  exit 1
}

Send-UpdateReport -FromVersion $CurrentVersion -ToVersion $latest.version -Result "success" -Detail "update applied" -PackageId $latest.id

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host " Update installed successfully: $($latest.version)" -ForegroundColor Green
Write-Host "========================================================"
Write-Host "Please restart MetaTrader 5 / commercial launcher when convenient."
Write-Host "Trading Engine behavior is unchanged unless this release ships an Owner-approved Core tag."
