<#
.SYNOPSIS
  Pull latest GitHub main into this local repo (keeps H: / local drive in sync).

.DESCRIPTION
  Cloud agents update GitHub + Vercel only. This script is the Owner-side half:
  it fast-forwards local main from origin/main so Commercial/Releases, Setup.exe,
  portal sources, and docs match GitHub.

.PARAMETER Branch
  Remote branch to sync (default: main).

.PARAMETER Remote
  Git remote name (default: origin).

.PARAMETER AllowDirty
  If set, stashes local tracked changes before pull and restores after.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\Commercial\Scripts\Sync-LocalFromGitHub.ps1
#>
[CmdletBinding()]
param(
  [string]$Branch = "main",
  [string]$Remote = "origin",
  [switch]$AllowDirty
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
$logDir = Join-Path $scriptDir "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFile = Join-Path $logDir ("sync-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))

function Write-Log([string]$Message) {
  $line = "{0:u}  {1}" -f (Get-Date).ToUniversalTime(), $Message
  Add-Content -Path $logFile -Value $line
  Write-Host $line
}

Set-Location $repoRoot
Write-Log "Repo: $repoRoot"
Write-Log "Log:  $logFile"

if (-not (Test-Path (Join-Path $repoRoot ".git"))) {
  Write-Log "ERROR: This folder is not a git clone. Clone the GitHub repo here first, then re-run."
  Write-Log "  git clone https://github.com/rtasdmcompany-hub/the-gold-mind-ai-v2-professional.git"
  exit 2
}

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
  Write-Log "ERROR: git is not installed or not on PATH."
  exit 3
}

$stashed = $false
$status = & git status --porcelain
if ($status) {
  if (-not $AllowDirty) {
    Write-Log "ERROR: Working tree has local changes. Commit/stash them, or re-run with -AllowDirty."
    Write-Log ($status -join "`n")
    exit 4
  }
  Write-Log "Stashing local changes (-AllowDirty)..."
  & git stash push -u -m "TGM auto-sync $(Get-Date -Format o)" | Out-Host
  $stashed = $true
}

Write-Log "Fetching $Remote..."
& git fetch $Remote $Branch
if ($LASTEXITCODE -ne 0) { Write-Log "ERROR: git fetch failed ($LASTEXITCODE)"; exit 5 }

$before = (& git rev-parse --short HEAD).Trim()
Write-Log "Local HEAD before: $before"

# Prefer ff-only so local never rewrites history unexpectedly
& git checkout $Branch 2>&1 | Out-Host
& git pull --ff-only $Remote $Branch
if ($LASTEXITCODE -ne 0) {
  Write-Log "ERROR: git pull --ff-only failed. Resolve divergence manually, then re-run."
  if ($stashed) { & git stash pop | Out-Host }
  exit 6
}

$after = (& git rev-parse --short HEAD).Trim()
Write-Log "Local HEAD after:  $after"

if ($stashed) {
  Write-Log "Restoring stash..."
  & git stash pop | Out-Host
}

$setup = Join-Path $repoRoot "Commercial\Releases\1.0.0\installer\Setup.exe"
$shaFile = Join-Path $repoRoot "Commercial\Releases\1.0.0\installer\Setup.exe.sha256"
if (Test-Path $setup) {
  $item = Get-Item $setup
  $hash = (Get-FileHash -Algorithm SHA256 -Path $setup).Hash.ToLowerInvariant()
  Write-Log ("Setup.exe: {0} bytes · {1:u} · SHA256 {2}" -f $item.Length, $item.LastWriteTimeUtc, $hash)
  if (Test-Path $shaFile) {
    $expected = ((Get-Content $shaFile -Raw) -split "\s+")[0].Trim().ToLowerInvariant()
    if ($expected -and $expected -ne $hash) {
      Write-Log "WARNING: Setup.exe hash does not match Setup.exe.sha256 ($expected)"
    } else {
      Write-Log "Setup.exe checksum OK."
    }
  }
} else {
  Write-Log "WARNING: Setup.exe missing after sync at $setup"
}

# Duplicate alias must not return
$alias = Join-Path $repoRoot "Commercial\Releases\1.0.0\installer\TheGoldMindSetup.exe"
if (Test-Path $alias) {
  Write-Log "Removing obsolete alias TheGoldMindSetup.exe (canonical is Setup.exe only)..."
  Remove-Item -Force $alias -ErrorAction SilentlyContinue
  Remove-Item -Force ($alias + ".sha256") -ErrorAction SilentlyContinue
}

Write-Log "Sync complete."
exit 0
