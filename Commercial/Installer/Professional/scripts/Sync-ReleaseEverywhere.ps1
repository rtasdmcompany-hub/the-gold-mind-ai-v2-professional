<#
.SYNOPSIS
  One-command sync: local certified package → Releases → Customer Portal → (optional) git push / live site.

.DESCRIPTION
  When you update the local commercial folder (freeze EX5, presets, payload), run this script.
  It rebuilds Setup.exe + ZIP, copies them into portal public/releases, updates catalog seed +
  website version constants, then optionally pushes to GitHub so Vercel redeploys the same version.

  Absolute rule: packages the freeze EX5 only (default SHA below). Does not recompile the EA.

.EXAMPLE
  .\Sync-ReleaseEverywhere.ps1 -Version 1.0.1 -Push

.EXAMPLE
  .\Sync-ReleaseEverywhere.ps1 -Version 1.0.1 -WhatIf
#>
param(
  [string]$Version = "1.0.1",
  [string]$Channel = "stable",
  [string]$PortalBase = "https://the-gold-mind-ai-v2-professional.vercel.app",
  # Production freeze binary - change only with explicit Owner authorization
  [string]$ExpectedEx5Sha = "21503FA83938CF80AA24947A512EBE2F238AC7512BF9E48A21FBFF647D77F9B7",
  [switch]$Push,
  [switch]$SkipBuild,
  [switch]$SkipValidate,
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
$Commercial = Join-Path $Root "Commercial"
$PayloadEa = Join-Path $Commercial "Installer\Professional\inno\payload\ea\TheGoldMindAI_Professional.ex5"
$ExpertsEx5 = Join-Path $Root "Experts\TheGoldMindAI_Professional.ex5"
$PresetSrc = Join-Path $Commercial "Documentation\Phase18\Phase18_DEFAULT_PROTECTIONS.set"
$PayloadPresets = Join-Path $Commercial "Installer\Professional\inno\payload\presets"
$PortalWeb = Join-Path $Commercial "CustomerPortal\web"
$PortalReleases = Join-Path $PortalWeb "public\releases"
$BrandTs = Join-Path $PortalWeb "src\lib\brand.ts"
$ProductTs = Join-Path $PortalWeb "src\lib\product.ts"
$CommercialSrc = Join-Path $PortalWeb "src\server\releases\commercial-source.ts"
$PkgJson = Join-Path $PortalWeb "package.json"
$BuildScript = Join-Path $PSScriptRoot "Build-CommercialRelease.ps1"

function Write-Banner([string]$m) {
  Write-Host ""
  Write-Host "========================================================" -ForegroundColor DarkCyan
  Write-Host "  $m" -ForegroundColor Cyan
  Write-Host "========================================================"
}

function Get-Sha256([string]$path) {
  return (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToUpperInvariant()
}

function Assert-FreezeEx5 {
  Write-Banner "Freeze EX5 gate"
  if (-not (Test-Path $PayloadEa)) { throw "Payload EX5 missing: $PayloadEa" }
  $payloadHash = Get-Sha256 $PayloadEa
  Write-Host "  Expected freeze: $ExpectedEx5Sha"
  Write-Host "  Payload EX5:     $payloadHash"
  if ($payloadHash -ne $ExpectedEx5Sha.ToUpperInvariant()) {
    throw "Payload EX5 is NOT the freeze binary. Restore freeze before sync."
  }
  # Keep Experts aligned so Build-CommercialRelease copies the same bytes
  if (-not (Test-Path $ExpertsEx5) -or ((Get-Sha256 $ExpertsEx5) -ne $payloadHash)) {
    Write-Host "  Restoring Experts EX5 from freeze payload..." -ForegroundColor Yellow
    if (-not $WhatIf) {
      Copy-Item -Force $PayloadEa $ExpertsEx5
    }
  }
  Write-Host "  FREEZE MATCH" -ForegroundColor Green
}

function Sync-Presets {
  Write-Banner "Sync power presets into payload"
  if (Test-Path $PresetSrc) {
    New-Item -ItemType Directory -Force -Path $PayloadPresets | Out-Null
    if (-not $WhatIf) {
      Copy-Item -Force $PresetSrc (Join-Path $PayloadPresets "Phase18_DEFAULT_PROTECTIONS.set")
      Copy-Item -Force $PresetSrc (Join-Path (Split-Path $PayloadEa) "Phase18_DEFAULT_PROTECTIONS.set")
    }
    Write-Host "  Preset synced (range 250 / act 1 expected in source)" -ForegroundColor Green
  } else {
    Write-Host "  Preset source missing (skipped): $PresetSrc" -ForegroundColor Yellow
  }
}

function Invoke-CommercialBuild {
  Write-Banner "Build commercial release $Version"
  if ($SkipBuild) {
    Write-Host "  SkipBuild set - using existing Releases/$Version" -ForegroundColor Yellow
    return
  }
  if ($WhatIf) {
    Write-Host "  WhatIf: would run Build-CommercialRelease.ps1 -Version $Version"
    return
  }
  $args = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $BuildScript,
    "-Version", $Version,
    "-Channel", $Channel,
    "-PortalBase", $PortalBase,
    "-SkipMq5Gate",
    "-ExpectedEx5Sha", $ExpectedEx5Sha
  )
  if ($SkipValidate) { $args += "-SkipValidate" }
  & powershell @args
  if ($LASTEXITCODE -ne 0) { throw "Build-CommercialRelease failed (exit $LASTEXITCODE)" }
}

function Update-WebsiteVersionConstants([string]$zipPath, [string]$seedPath) {
  Write-Banner "Update website version constants"
  $seed = Get-Content $seedPath -Raw | ConvertFrom-Json
  $zipHash = $seed.sha256.ToLowerInvariant()
  $zipSize = [int64]$seed.packageSizeBytes
  $releasedAt = [string]$seed.releasedAt
  $pkgId = [string]$seed.id
  $zipName = [string]$seed.packageFile

  Write-Host "  version=$Version id=$pkgId sha256=$zipHash size=$zipSize"
  if ($WhatIf) { return }

  # brand.ts - replace firstEnv version fallback literal
  $brandLines = Get-Content $BrandTs
  $seenNpm = $false
  $brandOut = foreach ($line in $brandLines) {
    if ($line -match 'npm_package_version') { $seenNpm = $true }
    if ($seenNpm -and $line -match '^\s*"1\.\d+\.\d+"\s*$') {
      $seenNpm = $false
      ($line -replace '1\.\d+\.\d+', $Version)
    } else {
      $line
    }
  }
  $brandOut | Set-Content $BrandTs -Encoding UTF8

  # product.ts - stable package id default
  (Get-Content $ProductTs) | ForEach-Object {
    if ($_ -match 'PRODUCT_STABLE_PACKAGE_ID') {
      ($_ -replace 'rel_\d+_stable', $pkgId)
    } else { $_ }
  } | Set-Content $ProductTs -Encoding UTF8

  # commercial-source.ts fallbacks
  $cs = Get-Content $CommercialSrc
  for ($i = 0; $i -lt $cs.Count; $i++) {
    if ($cs[$i] -like '*Known SHA-256 of Commercial/Releases/*') {
      $cs[$i] = "/** Known SHA-256 of Commercial/Releases/$Version/$zipName */"
    }
    elseif ($cs[$i] -match '^\s*"[a-fA-F0-9]{64}";\s*$' -and $i -gt 0 -and $cs[$i - 1] -match 'STABLE_SHA256') {
      $cs[$i] = "  `"$zipHash`";"
    }
    elseif ($cs[$i] -match 'export const STABLE_SHA256\s*=\s*"[a-fA-F0-9]+";') {
      $cs[$i] = "export const STABLE_SHA256 = `"$zipHash`";"
    }
    elseif ($cs[$i] -match 'export const STABLE_SIZE_BYTES') {
      $cs[$i] = "export const STABLE_SIZE_BYTES = $zipSize;"
    }
    elseif ($cs[$i] -match 'export const STABLE_RELEASED_AT') {
      $cs[$i] = "export const STABLE_RELEASED_AT = `"$releasedAt`";"
    }
  }
  $cs | Set-Content $CommercialSrc -Encoding UTF8

  $pkg = Get-Content $PkgJson -Raw | ConvertFrom-Json
  $pkg.version = $Version
  $pkg | ConvertTo-Json -Depth 20 | Set-Content $PkgJson -Encoding UTF8

  Write-Host "  Portal constants updated for $Version" -ForegroundColor Green
}

function Publish-Verify {
  Write-Banner "Verify portal package EX5"
  $zipName = "TGM_PROFESSIONAL_${Version}_${Channel}.zip"
  $portalZip = Join-Path $PortalReleases $zipName
  if (-not (Test-Path $portalZip)) { throw "Portal ZIP missing: $portalZip" }

  $stage = Join-Path $env:TEMP ("tgm-sync-verify-" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($portalZip, $stage)
    $ex5 = Get-ChildItem -Path $stage -Recurse -Filter "TheGoldMindAI_Professional.ex5" | Select-Object -First 1
    if (-not $ex5) { throw "EX5 not found inside portal ZIP" }
    $h = Get-Sha256 $ex5.FullName
    Write-Host "  ZIP EX5 SHA-256: $h"
    if ($h -ne $ExpectedEx5Sha.ToUpperInvariant()) {
      throw "Portal ZIP contains wrong EX5 (not freeze)."
    }
    Write-Host "  PORTAL ZIP = FREEZE EX5" -ForegroundColor Green
  } finally {
    Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-GitPush {
  if (-not $Push) {
    Write-Host ""
    Write-Host "Offline pack ready. To publish live site:" -ForegroundColor Yellow
    Write-Host "  .\Sync-ReleaseEverywhere.ps1 -Version $Version -Push"
    Write-Host "  (or: git add/commit portal+releases, then git push origin main)"
    return
  }
  Write-Banner "Git commit + push (triggers Vercel if Git-linked)"
  if ($WhatIf) {
    Write-Host "  WhatIf: would commit + push release sync"
    return
  }
  Push-Location $Root
  try {
    $paths = @(
      "Commercial/Releases/$Version",
      "Commercial/Installer/Professional/inno/payload",
      "Commercial/Installer/Professional/scripts/Sync-ReleaseEverywhere.ps1",
      "Commercial/Installer/Professional/scripts/Build-CommercialRelease.ps1",
      "Commercial/CustomerPortal/web/public/releases",
      "Commercial/CustomerPortal/web/src/lib/brand.ts",
      "Commercial/CustomerPortal/web/src/lib/product.ts",
      "Commercial/CustomerPortal/web/src/server/releases/commercial-source.ts",
      "Commercial/CustomerPortal/web/package.json",
      "Commercial/Documentation/RELEASE_SYNC.md",
      ".github/workflows/portal-release-sync.yml",
      "Experts/TheGoldMindAI_Professional.ex5"
    )
    foreach ($p in $paths) {
      if (Test-Path (Join-Path $Root $p)) { git add -- $p 2>$null }
    }
    $status = git status --porcelain
    if (-not $status) {
      Write-Host "  Nothing new to commit." -ForegroundColor Yellow
    } else {
      git commit -m @"
Publish commercial $Version everywhere (freeze EX5 + portal sync).

Rebuilds installer ZIP, updates Customer Portal public/releases and version seed so local/online stay identical.
"@
      if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
    }
    git push origin HEAD
    if ($LASTEXITCODE -ne 0) { throw "git push failed - live site not updated until push succeeds" }
    Write-Host "  Pushed. Vercel should redeploy from GitHub." -ForegroundColor Green
    Write-Host "  Live: $PortalBase"
  } finally {
    Pop-Location
  }
}

# --- main ---
Write-Banner "THE GOLD MIND - Sync Release Everywhere ($Version)"
Assert-FreezeEx5
Sync-Presets
Invoke-CommercialBuild

$zipPath = Join-Path $Commercial "Releases\$Version\TGM_PROFESSIONAL_${Version}_${Channel}.zip"
$seedPath = Join-Path $PortalReleases "latest-stable.json"
if (-not (Test-Path $zipPath)) { throw "Release ZIP missing after build: $zipPath" }
if (-not (Test-Path $seedPath)) { throw "latest-stable.json missing after build: $seedPath" }

Update-WebsiteVersionConstants -zipPath $zipPath -seedPath $seedPath
Publish-Verify
Invoke-GitPush

Write-Banner "SYNC COMPLETE"
Write-Host "Local Releases:  $zipPath"
Write-Host "Portal asset:    $(Join-Path $PortalReleases (Split-Path $zipPath -Leaf))"
Write-Host "Catalog seed:    $seedPath"
Write-Host "After live deploy, download ZIP EX5 must equal: $ExpectedEx5Sha" -ForegroundColor Green
