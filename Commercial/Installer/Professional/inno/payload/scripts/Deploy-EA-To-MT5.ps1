# THE GOLD MIND PROFESSIONAL - Detect MT5 terminals and deploy certified EA.
# Commercial packaging only. Does NOT modify Core Trading Engine source/logic.
param(
  [string]$InstallRoot = "$env:LOCALAPPDATA\THE GOLD MIND PROFESSIONAL",
  [string]$TerminalId = "",
  [switch]$Silent,
  [switch]$ListOnly
)

$ErrorActionPreference = "Stop"
$Product = "THE GOLD MIND PROFESSIONAL"
$EaSource = Join-Path $InstallRoot "ea\TheGoldMindAI_Professional.ex5"
$EaFolder = "The Gold Mind Professional"
$DestRelative = "MQL5\Experts\$EaFolder\TheGoldMindAI_Professional.ex5"

function Write-Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Yellow }

$BrokerMarkers = @(
  "exness", "ftmo", "xm global", "xm.com", "ic markets", "icmarkets",
  "pepperstone", "roboforex", "fxpro", "tickmill"
)

function Test-BrokerPath([string]$Path) {
  if (-not $Path) { return $false }
  $lower = $Path.ToLowerInvariant()
  foreach ($m in $BrokerMarkers) { if ($lower.Contains($m)) { return $true } }
  return $false
}

function Test-MetaQuotesOfficialExe([string]$Exe) {
  if (-not $Exe -or -not (Test-Path $Exe)) { return $false }
  if (Test-BrokerPath $Exe) { return $false }
  try {
    $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Exe)
    $blob = ("{0} {1} {2}" -f $vi.CompanyName, $vi.ProductName, $vi.FileDescription).ToLowerInvariant()
    foreach ($m in $BrokerMarkers) { if ($blob.Contains($m)) { return $false } }
    return $blob.Contains("metaquotes")
  } catch { return $false }
}

function Test-OfficialMt5InstallDir([string]$InstallDir) {
  if (-not $InstallDir) { return $false }
  $exe = Join-Path $InstallDir "terminal64.exe"
  if (-not (Test-Path $exe)) { $exe = Join-Path $InstallDir "terminal.exe" }
  return (Test-MetaQuotesOfficialExe $exe)
}

function Get-Mt5Terminals {
  $roots = @(
    (Join-Path $env:APPDATA "MetaQuotes\Terminal"),
    (Join-Path $env:LOCALAPPDATA "MetaQuotes\Terminal")
  )
  $list = @()
  foreach ($root in $roots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
      $experts = Join-Path $_.FullName "MQL5\Experts"
      $origin = Join-Path $_.FullName "origin.txt"
      $originPath = $null
      if (Test-Path $origin) {
        try { $originPath = (Get-Content $origin -Raw).Trim().Trim('"') } catch { }
      }
      $isOfficial = Test-OfficialMt5InstallDir $originPath
      $label = if ($originPath) { $originPath } else { $_.Name }
      if ($isOfficial) {
        $label = "Official MetaTrader 5 (MetaQuotes) — recommended"
      } elseif ($originPath) {
        $label = "Broker terminal (skip): $label"
      }
      $list += [pscustomobject]@{
        Id          = $_.Name
        Path        = $_.FullName
        ExpertsPath = $experts
        Label       = $label
        HasExperts  = (Test-Path $experts)
        IsOfficial  = $isOfficial
      }
    }
  }
  foreach ($pf in @("${env:ProgramFiles}\MetaTrader 5", "${env:ProgramFiles(x86)}\MetaTrader 5")) {
    if (-not (Test-Path $pf)) { continue }
    if (-not (Test-OfficialMt5InstallDir $pf)) { continue }
    $list += [pscustomobject]@{
      Id          = "INSTALL_OFFICIAL_$pf"
      Path        = $pf
      ExpertsPath = (Join-Path $pf "MQL5\Experts")
      Label       = "Official MetaTrader 5 (MetaQuotes) — recommended"
      HasExperts  = (Test-Path (Join-Path $pf "MQL5\Experts"))
      IsOfficial  = $true
    }
  }
  return $list | Sort-Object -Property @{ Expression = { -not $_.IsOfficial }; Ascending = $true }, Path
}

function Deploy-Ea([string]$terminalPath) {
  if (-not (Test-Path $EaSource)) {
    throw "EA binary not found: $EaSource"
  }
  $destDir = Join-Path $terminalPath "MQL5\Experts\$EaFolder"
  New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  $dest = Join-Path $destDir "TheGoldMindAI_Professional.ex5"
  Copy-Item -Force $EaSource $dest
  $srcHash = (Get-FileHash -Algorithm SHA256 $EaSource).Hash.ToLowerInvariant()
  $dstHash = (Get-FileHash -Algorithm SHA256 $dest).Hash.ToLowerInvariant()
  if ($srcHash -ne $dstHash) {
    throw "EA copy verification failed (SHA mismatch)."
  }
  $verify = Join-Path $destDir "INSTALL_VERIFY.json"
  @{
    product      = $Product
    installedAt  = (Get-Date).ToUniversalTime().ToString("o")
    source       = $EaSource
    destination  = $dest
    eaSha256     = $dstHash
    relativePath = $DestRelative
    coreNote     = "Binary copy only - Core Trading Engine logic unchanged."
  } | ConvertTo-Json | Set-Content -Path $verify -Encoding UTF8
  return $dest
}

Write-Step "License activation gate"
$activationFile = Join-Path $InstallRoot "config\license-activation.json"
if (-not (Test-Path $activationFile)) {
  Write-Host "  License activation failed: missing config\license-activation.json" -ForegroundColor Red
  Write-Host "  Run Setup.exe (or scripts\Activate-License.ps1) with your portal email + key first."
  Write-Host "  Trial and lifetime use the same Active rule — EA deploy is blocked until then."
  exit 1
}
try {
  $act = Get-Content $activationFile -Raw | ConvertFrom-Json
  $st = ([string]$act.status).ToLowerInvariant()
  if ($st -ne "active" -and $st -ne "grace") {
    Write-Host "  License activation failed: portal status='$st' (need active/grace)." -ForegroundColor Red
    exit 1
  }
  Write-Host "  License OK ($st) — device $($act.deviceId)" -ForegroundColor Green
} catch {
  Write-Host "  License activation failed: cannot read activation file." -ForegroundColor Red
  exit 1
}

Write-Step "MT5 terminal detection"
$terminals = @(Get-Mt5Terminals | Where-Object { $_.HasExperts -or $_.Path -match 'MetaQuotes\\Terminal' })
if ($terminals.Count -eq 0) {
  Write-Warning "No MetaTrader 5 terminal data folders found."
  Write-Host "Install MetaTrader 5, open it once, then re-run Deploy-EA-To-MT5.ps1"
  if ($Silent) { exit 2 }
  exit 2
}

Write-Host "Found $($terminals.Count) candidate(s):"
for ($i = 0; $i -lt $terminals.Count; $i++) {
  $t = $terminals[$i]
  Write-Host ("  [{0}] {1}" -f ($i + 1), $t.Label)
  Write-Host ("      {0}" -f $t.Path)
}

if ($ListOnly) { exit 0 }

$selected = $null
if ($TerminalId) {
  $selected = $terminals | Where-Object { $_.Id -eq $TerminalId } | Select-Object -First 1
  if (-not $selected) { throw "TerminalId not found: $TerminalId" }
} elseif ($Silent -and $terminals.Count -ge 1) {
  $selected = $terminals | Where-Object { $_.IsOfficial } | Select-Object -First 1
  if (-not $selected) {
    Write-Warning "Official MetaQuotes MetaTrader 5 not found. Broker terminals will not be used."
    Write-Host "Install from https://www.metatrader5.com/en/download then re-run Deploy-EA-To-MT5.ps1"
    exit 2
  }
} else {
  $choice = Read-Host "Select terminal number (1-$($terminals.Count))"
  $idx = [int]$choice - 1
  if ($idx -lt 0 -or $idx -ge $terminals.Count) { throw "Invalid selection." }
  $selected = $terminals[$idx]
}

Write-Step "Deploying TheGoldMindAI_Professional.ex5"
$destPath = Deploy-Ea -terminalPath $selected.Path
Write-Host "  Installed: $destPath" -ForegroundColor Green
Write-Host "  Open MT5 -> Navigator -> Expert Advisors -> $EaFolder"
Write-Host "  Double-click TheGoldMindAI_Professional to apply."

$stateDir = Join-Path $InstallRoot "config"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
@{
  terminalId   = $selected.Id
  terminalPath = $selected.Path
  eaPath       = $destPath
  deployedAt   = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json | Set-Content (Join-Path $stateDir "mt5-deploy.json") -Encoding UTF8

exit 0
