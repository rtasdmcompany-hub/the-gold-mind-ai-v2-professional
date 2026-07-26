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
$DestRelative = "MQL5\Experts\The Gold Mind\TheGoldMindAI_Professional.ex5"

function Write-Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Yellow }

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
      $label = $_.Name
      if (Test-Path $origin) {
        try { $label = (Get-Content $origin -Raw).Trim() } catch { }
      }
      $list += [pscustomobject]@{
        Id          = $_.Name
        Path        = $_.FullName
        ExpertsPath = $experts
        Label       = $label
        HasExperts  = (Test-Path $experts)
      }
    }
  }
  foreach ($pf in @("${env:ProgramFiles}\MetaTrader 5", "${env:ProgramFiles(x86)}\MetaTrader 5")) {
    if (Test-Path $pf) {
      $list += [pscustomobject]@{
        Id          = "INSTALL_$([guid]::NewGuid().ToString('N').Substring(0,8))"
        Path        = $pf
        ExpertsPath = (Join-Path $pf "MQL5\Experts")
        Label       = "Program Files: $pf"
        HasExperts  = (Test-Path (Join-Path $pf "MQL5\Experts"))
      }
    }
  }
  return $list | Sort-Object -Property Path -Unique
}

function Deploy-Ea([string]$terminalPath) {
  if (-not (Test-Path $EaSource)) {
    throw "EA binary not found: $EaSource"
  }
  $destDir = Join-Path $terminalPath "MQL5\Experts\The Gold Mind"
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
  $selected = $terminals | Where-Object { $_.Path -match 'MetaQuotes\\Terminal' -and $_.HasExperts } | Select-Object -First 1
  if (-not $selected) { $selected = $terminals[0] }
} else {
  $choice = Read-Host "Select terminal number (1-$($terminals.Count))"
  $idx = [int]$choice - 1
  if ($idx -lt 0 -or $idx -ge $terminals.Count) { throw "Invalid selection." }
  $selected = $terminals[$idx]
}

Write-Step "Deploying TheGoldMindAI_Professional.ex5"
$destPath = Deploy-Ea -terminalPath $selected.Path
Write-Host "  Installed: $destPath" -ForegroundColor Green
Write-Host "  Open MT5 -> Navigator -> Expert Advisors -> The Gold Mind"
Write-Host "  Attach TheGoldMindAI_Professional to a chart."

$stateDir = Join-Path $InstallRoot "config"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
@{
  terminalId   = $selected.Id
  terminalPath = $selected.Path
  eaPath       = $destPath
  deployedAt   = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json | Set-Content (Join-Path $stateDir "mt5-deploy.json") -Encoding UTF8

exit 0
