<#
.SYNOPSIS
  THE GOLD MIND PROFESSIONAL - Final commercial packaging build.
.DESCRIPTION
  Produces Setup.exe, Professional ZIP, checksums, SBOM, manifests, GitHub assets.
  NEVER modifies Experts/*.mq5 or Core Trading Engine logic.
#>
param(
  [string]$Version = "1.0.0",
  [string]$Channel = "stable",
  [string]$PortalBase = "https://the-gold-mind-ai-v2-professional.vercel.app",
  [ValidateSet("unsigned", "standard", "ev")]
  [string]$SignMode = "unsigned",
  [string]$SignCertPath = "",
  [string]$SignCertPassword = "",
  [string]$SignThumbprint = "",
  [switch]$SkipValidate,
  # When set, mq5 source SHA is reported but does not abort packaging (EX5 freeze gate still applies).
  [switch]$SkipMq5Gate,
  # Production freeze EX5 — packaging aborts if Experts binary differs (unless empty to skip).
  [string]$ExpectedEx5Sha = "21503FA83938CF80AA24947A512EBE2F238AC7512BF9E48A21FBFF647D77F9B7"
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
$Commercial = Join-Path $Root "Commercial"
$InstallerProf = Join-Path $Commercial "Installer\Professional"
$PayloadRoot = Join-Path $InstallerProf "inno\payload"
$Tools = Join-Path $InstallerProf "tools"
$OutDir = Join-Path $Commercial "Releases\$Version"
$InstallerOut = Join-Path $OutDir "installer"
$GhAssets = Join-Path $OutDir "github-assets"

$CertSha = "1965551f7b88f403cf8a0af5475211a562b9c05500a0bb530e0136d38d403f1e"
$Mq5 = Join-Path $Root "Experts\TheGoldMindAI_Professional.mq5"
$Ex5 = Join-Path $Root "Experts\TheGoldMindAI_Professional.ex5"
$Csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $Csc)) { $Csc = "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe" }

function Write-Banner([string]$m) {
  Write-Host ""
  Write-Host "========================================================" -ForegroundColor DarkYellow
  Write-Host "  $m" -ForegroundColor Yellow
  Write-Host "========================================================"
}

function Assert-CoreFrozen {
  Write-Banner "Core SHA-256 gate"
  if (-not (Test-Path $Mq5)) { throw "Core mq5 NOT FOUND: $Mq5" }
  if (-not (Test-Path $Ex5)) { throw "Compiled ex5 NOT FOUND: $Ex5. Compile in MetaEditor first." }

  $ex5Hash = (Get-FileHash -Algorithm SHA256 $Ex5).Hash.ToUpperInvariant()
  if ($ExpectedEx5Sha) {
    Write-Host "  Expected EX5: $($ExpectedEx5Sha.ToUpperInvariant())"
    Write-Host "  Actual EX5:   $ex5Hash"
    if ($ex5Hash -ne $ExpectedEx5Sha.ToUpperInvariant()) {
      throw "EX5 FREEZE MISMATCH - packaging aborted. Restore freeze binary or pass authorized ExpectedEx5Sha."
    }
    Write-Host "  EX5 freeze MATCH." -ForegroundColor Green
  }

  $hash = (Get-FileHash -Algorithm SHA256 $Mq5).Hash.ToLowerInvariant()
  Write-Host "  Expected mq5: $CertSha"
  Write-Host "  Actual mq5:   $hash"
  if ($hash -ne $CertSha) {
    if ($SkipMq5Gate) {
      Write-Host "  mq5 SHA differs (SkipMq5Gate) — packaging EX5 freeze only." -ForegroundColor Yellow
    } else {
      throw "CORE SHA MISMATCH - packaging aborted. Do not redistribute."
    }
  } else {
    Write-Host "  MATCH - Core frozen. Packaging commercial surfaces only." -ForegroundColor Green
  }
}

function New-Payload {
  Write-Banner "Prepare installer payload"
  foreach ($d in @(
      (Join-Path $PayloadRoot "bin"),
      (Join-Path $PayloadRoot "config"),
      (Join-Path $PayloadRoot "docs"),
      (Join-Path $PayloadRoot "ea"),
      (Join-Path $PayloadRoot "scripts")
    )) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
  }

  Copy-Item -Force $Ex5 (Join-Path $PayloadRoot "ea\TheGoldMindAI_Professional.ex5")
  $ex5Hash = (Get-FileHash -Algorithm SHA256 $Ex5).Hash.ToLowerInvariant()
  $coreTxt = @"
Core source (mq5) SHA-256 (certified, frozen):
$CertSha

Packaged binary (ex5) SHA-256:
$ex5Hash

Rule: Commercial packaging copies the certified binary only.
Trading / Risk / Recovery / Money / Entry / Exit / Order logic: NOT MODIFIED.
"@
  Set-Content -Path (Join-Path $PayloadRoot "ea\CORE_SHA256.txt") -Value $coreTxt -Encoding UTF8

  $verObj = [ordered]@{
    product    = "THE GOLD MIND PROFESSIONAL"
    version    = $Version
    channel    = $Channel
    buildAt    = (Get-Date).ToUniversalTime().ToString("o")
    portalBase = $PortalBase
    coreMq5Sha = $CertSha
    coreEx5Sha = $ex5Hash
    coreFrozen = $true
  }
  $verObj | ConvertTo-Json | Set-Content (Join-Path $PayloadRoot "config\version.json") -Encoding UTF8
  @{ portalBase = $PortalBase } | ConvertTo-Json | Set-Content (Join-Path $PayloadRoot "config\portal.json") -Encoding UTF8

  $scriptSrc = Join-Path $InstallerProf "inno\payload\scripts"
  $scriptDst = Join-Path $PayloadRoot "scripts"
  if ((Resolve-Path $scriptSrc).Path -ne (Resolve-Path $scriptDst -EA SilentlyContinue).Path) {
    Copy-Item -Force (Join-Path $scriptSrc "*.ps1") $scriptDst
  }
  # Commercial updater must ship with install payload and use production portal
  Copy-Item -Force (Join-Path $InstallerProf "scripts\Update-TheGoldMindProfessional.ps1") (Join-Path $scriptDst "Update-TheGoldMindProfessional.ps1")
  if (-not (Test-Path (Join-Path $scriptDst "Deploy-EA-To-MT5.ps1"))) {
    throw "Deploy-EA-To-MT5.ps1 missing under payload scripts"
  }
  if (-not (Test-Path (Join-Path $scriptDst "Activate-License.ps1"))) {
    throw "Activate-License.ps1 missing under payload scripts"
  }

  $readme = @"
THE GOLD MIND PROFESSIONAL
Version $Version ($Channel)

Commercial package - Customer Portal licensing + MT5 EA deployment.
Core Trading Engine is certified and frozen.

Quick start:
1. Run Setup.exe
2. Activate license
3. Confirm EA under MT5 Navigator -> The Gold Mind
4. Attach TheGoldMindAI_Professional to a chart
"@
  Set-Content (Join-Path $PayloadRoot "README.txt") -Value $readme -Encoding UTF8

  $eula = @"
END-USER LICENSE AGREEMENT (SUMMARY)
RTAS Group of Companies - THE GOLD MIND PROFESSIONAL

By installing you agree to the Terms published on the Customer Portal.
Trading involves risk of loss. Past performance is not indicative of future results.
The Core Trading Engine binary is licensed for authorized use only.
Full legal text: Portal -> Terms / EULA / Risk Disclosure.
"@
  Set-Content (Join-Path $PayloadRoot "EULA.txt") -Value $eula -Encoding UTF8

  $info = @"
Welcome to THE GOLD MIND PROFESSIONAL Setup.

This wizard installs the commercial shell and can deploy
TheGoldMindAI_Professional.ex5 into your MetaTrader 5 terminal.

The certified Core Trading Engine is never modified by this installer.
"@
  Set-Content (Join-Path $PayloadRoot "INFO_BEFORE.txt") -Value $info -Encoding UTF8
}

function Build-LauncherCsc {
  Write-Banner "Build launcher EXE (csc)"
  if (-not (Test-Path $Csc)) { throw "csc.exe NOT FOUND" }
  $src = Join-Path $Tools "launcher\Program.net48.cs"
  $out = Join-Path $PayloadRoot "bin\TGM-Professional-Launcher.exe"
  $refs = @(
    "/reference:System.dll",
    "/reference:System.Windows.Forms.dll",
    "/reference:System.Drawing.dll"
  )
  & $Csc /nologo /target:winexe /platform:anycpu /out:$out @refs $src
  if ($LASTEXITCODE -ne 0) { throw "Launcher csc build failed." }
  if (-not (Test-Path $out)) { throw "Launcher EXE missing." }
  Write-Host "  $out"
}

function New-PayloadZip {
  Write-Banner "Create payload.zip"
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = Join-Path $Tools "setup\payload.zip"
  if (Test-Path $zip) { Remove-Item $zip -Force }
  [System.IO.Compression.ZipFile]::CreateFromDirectory($PayloadRoot, $zip, [System.IO.Compression.CompressionLevel]::Optimal, $false)
  Write-Host "  payload.zip bytes: $((Get-Item $zip).Length)"
  return $zip
}

function Build-SetupCsc {
  Write-Banner "Build Setup.exe (single canonical binary — no alias copies)"
  New-Item -ItemType Directory -Force -Path $InstallerOut | Out-Null
  $src = Join-Path $Tools "setup\Program.net48.cs"
  $zip = Join-Path $Tools "setup\payload.zip"
  $out = Join-Path $InstallerOut "Setup.exe"
  # Remove prior installer outputs so old/alias binaries cannot linger
  Get-ChildItem $InstallerOut -File -ErrorAction SilentlyContinue | Remove-Item -Force
  if (Test-Path $Csc) {
    $refs = @(
      "/reference:System.dll",
      "/reference:System.Core.dll",
      "/reference:System.Windows.Forms.dll",
      "/reference:System.Drawing.dll",
      "/reference:System.IO.Compression.dll",
      "/reference:System.IO.Compression.FileSystem.dll"
    )
    & $Csc /nologo /target:winexe /platform:anycpu /out:$out /resource:"$zip,payload.zip" @refs $src
    if ($LASTEXITCODE -ne 0) { throw "Setup.exe csc build failed." }
  } else {
    $mcs = Get-Command mcs -ErrorAction SilentlyContinue
    if (-not $mcs) { throw "Neither csc.exe nor mcs found — cannot build Setup.exe." }
    Write-Host "  Using mono mcs (non-Windows build host)" -ForegroundColor Yellow
    & mcs -sdk:4.5 -target:winexe -platform:anycpu -out:$out `
      -r:System.dll -r:System.Core.dll -r:System.Windows.Forms.dll -r:System.Drawing.dll `
      -r:System.IO.Compression.dll -r:System.IO.Compression.FileSystem.dll `
      "-resource:$zip,payload.zip" $src
    if ($LASTEXITCODE -ne 0) { throw "Setup.exe mcs build failed." }
  }
  if (-not (Test-Path $out)) { throw "Setup.exe NOT FOUND after compile." }
  # Discard staging payload.zip — never keep a second copy next to sources
  if (Test-Path $zip) { Remove-Item $zip -Force }
  Write-Host "  Output: $out" -ForegroundColor Green
  Write-Host "  Bytes: $((Get-Item $out).Length)"
}

function New-ProfessionalZip {
  Write-Banner "Professional ZIP package"
  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
  $zipName = "TGM_PROFESSIONAL_${Version}_${Channel}.zip"
  $zipPath = Join-Path $OutDir $zipName
  if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
  $stage = Join-Path $env:TEMP "tgm-pro-zip-$([guid]::NewGuid().ToString('N'))"
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  Copy-Item -Recurse -Force (Join-Path $PayloadRoot "*") $stage
  Copy-Item -Force (Join-Path $InstallerOut "Setup.exe") (Join-Path $stage "Setup.exe")
  [System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
  Remove-Item $stage -Recurse -Force
  Write-Host "  $zipPath"
  return $zipPath
}

function New-Checksums([string[]]$paths) {
  Write-Banner "Checksums"
  $lines = @()
  foreach ($p in $paths) {
    if (-not (Test-Path $p)) { continue }
    $h = (Get-FileHash -Algorithm SHA256 $p).Hash.ToLowerInvariant()
    $rel = Split-Path $p -Leaf
    $lines += "$h  $rel"
    Set-Content -Path ($p + ".sha256") -Value "$h  $rel" -Encoding ASCII
    Write-Host "  $rel = $h"
  }
  $sumPath = Join-Path $OutDir "SHA256SUMS.txt"
  $lines | Set-Content $sumPath -Encoding ASCII
  return $sumPath
}

function New-Sbom {
  Write-Banner "SBOM (CycloneDX-lite JSON)"
  $ex5Hash = (Get-FileHash -Algorithm SHA256 $Ex5).Hash.ToLowerInvariant()
  $sbom = [ordered]@{
    bomFormat   = "CycloneDX"
    specVersion = "1.5"
    version     = 1
    metadata    = @{
      timestamp = (Get-Date).ToUniversalTime().ToString("o")
      component = @{
        type      = "application"
        name      = "THE GOLD MIND PROFESSIONAL"
        version   = $Version
        publisher = "RTAS Group of Companies"
      }
    }
    components = @(
      @{
        type        = "file"
        name        = "TheGoldMindAI_Professional.ex5"
        version     = $Version
        hashes      = @(@{ alg = "SHA-256"; content = $ex5Hash })
        description = "Certified Core EA binary (logic frozen; packaging copy only)"
      },
      @{
        type        = "application"
        name        = "Setup.exe"
        version     = $Version
        description = "Windows commercial installer"
      },
      @{
        type        = "library"
        name        = "CustomerPortal"
        version     = "1.0.10-phase12.s1"
        description = "License activation backend (commercial)"
      }
    )
  }
  $path = Join-Path $OutDir "SBOM.json"
  ($sbom | ConvertTo-Json -Depth 8) | Set-Content $path -Encoding UTF8
  Write-Host "  $path"
  return $path
}

function New-Manifests([string]$zipPath, [string]$setupPath) {
  Write-Banner "Version manifest + release notes"
  $zipHash = (Get-FileHash -Algorithm SHA256 $zipPath).Hash.ToLowerInvariant()
  $setupHash = (Get-FileHash -Algorithm SHA256 $setupPath).Hash.ToLowerInvariant()
  $ex5Hash = (Get-FileHash -Algorithm SHA256 $Ex5).Hash.ToLowerInvariant()

  $manifest = [ordered]@{
    product    = "THE GOLD MIND PROFESSIONAL"
    version    = $Version
    channel    = $Channel
    releasedAt = (Get-Date).ToUniversalTime().ToString("o")
    core       = @{
      mq5       = "Experts/TheGoldMindAI_Professional.mq5"
      mq5Sha256 = $CertSha
      ex5Sha256 = $ex5Hash
      frozen    = $true
    }
    artifacts  = @{
      setupExe        = @{ file = "installer/Setup.exe"; sha256 = $setupHash }
      professionalZip = @{ file = (Split-Path $zipPath -Leaf); sha256 = $zipHash }
      sbom            = "SBOM.json"
      checksums       = "SHA256SUMS.txt"
    }
    installer  = @{
      desktopShortcut            = $true
      startMenu                  = $true
      uninstallRegistry          = "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\TheGoldMindProfessional"
      mt5DeployPath              = "MQL5/Experts/The Gold Mind/TheGoldMindAI_Professional.ex5"
      licenseActivation          = $true
      licenseRequiredBeforeFinish = $true
      googleLoginOptional        = $true
    }
    signMode   = $SignMode
  }
  ($manifest | ConvertTo-Json -Depth 8) | Set-Content (Join-Path $OutDir "VERSION_MANIFEST.json") -Encoding UTF8

  $notes = @"
# THE GOLD MIND PROFESSIONAL - Release Notes $Version

## Channel
$Channel

## What's included
- Windows Setup.exe (single canonical installer — no alias copies)
- Desktop + Start Menu shortcuts
- Add/Remove Programs uninstall entry
- MetaTrader 5 detection and EA deploy to MQL5/Experts/The Gold Mind/
- Strict license activation (email + key required; portal Active before finish)
- Professional ZIP, SHA-256 checksums, SBOM

## Core Trading Engine
- File: TheGoldMindAI_Professional.mq5 / .ex5
- SHA-256 (mq5): $CertSha
- Status: FROZEN trading logic - packaging/UI only

## Install
1. Generate license key in Customer Portal
2. Run installer/Setup.exe
3. Paste same portal email + key (required)
4. Confirm EA in MT5 Navigator -> The Gold Mind
5. Attach to chart

## Signing
Sign mode for this build: $SignMode
"@
  Set-Content (Join-Path $OutDir "RELEASE_NOTES.md") -Value $notes -Encoding UTF8

  $pkgManifest = Join-Path $InstallerProf "packages\manifest.stable.json"
  $sigStatus = if ($SignMode -eq "unsigned") { "pending_code_sign" } else { "signed_$SignMode" }
  $sigSubject = if ($SignMode -eq "unsigned") { "Code signing pending" } else { "RTAS Group of Companies" }
  $buildNumber = "{0}{1:D3}" -f ([datetime]::UtcNow.ToString("yy")), [datetime]::UtcNow.DayOfYear
  @{
    product          = "THE GOLD MIND PROFESSIONAL"
    edition          = "Website"
    channel          = $Channel
    version          = $Version
    buildNumber      = $buildNumber
    releasedAt       = (Get-Date).ToUniversalTime().ToString("o")
    packageFile      = (Split-Path $zipPath -Leaf)
    packageSizeBytes = (Get-Item $zipPath).Length
    sha256           = $zipHash
    signature        = @{
      type     = "authenticode"
      required = ($SignMode -ne "unsigned")
      subject  = $sigSubject
      status   = $sigStatus
    }
    compatibility    = @{
      os         = @("Windows 10", "Windows 11")
      mt5        = "build 3800+"
      coreTag    = $Version
      coreFrozen = $true
    }
    releaseNotes     = "Commercial packaging release $Version - Core frozen."
    httpsOnly        = $true
  } | ConvertTo-Json -Depth 6 | Set-Content $pkgManifest -Encoding UTF8
}

function Invoke-Sign([string]$setupPath) {
  Write-Banner "Authenticode signing ($SignMode)"
  $wf = @"
# Authenticode workflow

## Modes
- unsigned - local/dev (default)
- standard - Standard Code Signing Certificate
- ev - EV Code Signing Certificate

## Commands
signtool sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com /sha1 THUMBPRINT path\Setup.exe
signtool sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com /f cert.pfx /p PASSWORD path\Setup.exe
signtool verify /pa /v path\Setup.exe

## Build
.\Build-CommercialRelease.ps1 -SignMode standard -SignThumbprint <THUMBPRINT>
.\Build-CommercialRelease.ps1 -SignMode ev -SignCertPath .\ev.pfx -SignCertPassword <SECRET>
"@
  Set-Content (Join-Path $OutDir "SIGNING_WORKFLOW.md") -Value $wf -Encoding UTF8

  if ($SignMode -eq "unsigned") {
    Write-Host "  Unsigned development build - skipping signtool."
    return
  }

  $signtool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Recurse -Filter signtool.exe -EA SilentlyContinue |
    Where-Object { $_.FullName -match '\\x64\\' } | Select-Object -First 1
  if (-not $signtool) { throw "signtool.exe NOT FOUND. Install Windows SDK." }

  $t = $setupPath
  if ($SignThumbprint) {
    & $signtool.FullName sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com /sha1 $SignThumbprint $t
  } elseif ($SignCertPath) {
    & $signtool.FullName sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com /f $SignCertPath /p $SignCertPassword $t
  } else {
    throw "SignMode=$SignMode requires -SignThumbprint or -SignCertPath"
  }
  if ($LASTEXITCODE -ne 0) { throw "Signing failed for $t" }
  & $signtool.FullName verify /pa $t
}

function Publish-GitHubAssets {
  Write-Banner "GitHub Release notes (no mirror folder — use canonical Releases/$Version paths)"
  # Discipline: do not keep a second copy of binaries under github-assets/
  if (Test-Path $GhAssets) { Remove-Item $GhAssets -Recurse -Force }
  $gh = @"
# GitHub Release $Version

Upload from ``Commercial/Releases/$Version/`` (canonical — no duplicates):

``````
gh release create v$Version --title "THE GOLD MIND PROFESSIONAL $Version" --notes-file RELEASE_NOTES.md installer/Setup.exe TGM_PROFESSIONAL_${Version}_${Channel}.zip SHA256SUMS.txt SBOM.json VERSION_MANIFEST.json
``````
"@
  Set-Content (Join-Path $OutDir "GITHUB_RELEASE.md") -Value $gh -Encoding UTF8
}

function Publish-PortalReleaseAsset([string]$zipPath) {
  Write-Banner "Customer Portal download asset"
  $portalReleases = Join-Path $Commercial "CustomerPortal\web\public\releases"
  New-Item -ItemType Directory -Force -Path $portalReleases | Out-Null
  $destZip = Join-Path $portalReleases (Split-Path $zipPath -Leaf)
  Copy-Item -Force $zipPath $destZip
  $zipHash = (Get-FileHash -Algorithm SHA256 $zipPath).Hash.ToLowerInvariant()
  $zipSize = (Get-Item $zipPath).Length
  $buildNumber = "{0}{1:D3}" -f ([datetime]::UtcNow.ToString("yy")), [datetime]::UtcNow.DayOfYear
  $seed = [ordered]@{
    id               = "rel_$($Version.Replace('.',''))_stable"
    product          = "THE GOLD MIND PROFESSIONAL"
    version          = $Version
    buildNumber      = $buildNumber
    channel          = $Channel
    status           = "published"
    releasedAt       = (Get-Date).ToUniversalTime().ToString("o")
    packageFile      = (Split-Path $zipPath -Leaf)
    packageUrl       = "$PortalBase/api/releases/download/rel_$($Version.Replace('.',''))_stable"
    externalAssetUrl = "$PortalBase/releases/$(Split-Path $zipPath -Leaf)"
    packageSizeBytes = $zipSize
    sha256           = $zipHash
    signatureRequired = ($SignMode -ne "unsigned")
    signatureSubject  = if ($SignMode -eq "unsigned") { "Code signing pending" } else { "RTAS Group of Companies" }
    signatureStatus   = if ($SignMode -eq "unsigned") { "pending_code_sign" } else { "valid" }
    releaseNotes      = "Commercial packaging release $Version - extract ZIP, run Setup.exe, activate with existing license email/key."
    compatibility     = @{
      os         = @("Windows 10", "Windows 11")
      mt5        = "build 3800+"
      coreTag    = $Version
      coreFrozen = $true
    }
  }
  ($seed | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $portalReleases "latest-stable.json") -Encoding UTF8
  Write-Host "  Portal ZIP: $destZip"
  Write-Host "  Catalog seed: $(Join-Path $portalReleases 'latest-stable.json')"
  Write-Host "  After deploy, set RELEASE_STABLE_ZIP_URL if serverless FS cannot read public/releases."
}

function Write-Guides {
  Write-Banner "Documentation guides"
  $doc = Join-Path $Commercial "Documentation"

  Set-Content (Join-Path $doc "INSTALLATION_GUIDE.md") -Encoding UTF8 -Value @"
# INSTALLATION_GUIDE.md

**Product:** THE GOLD MIND PROFESSIONAL $Version
**Installer:** ``Commercial/Releases/$Version/installer/Setup.exe``

## Requirements
- Windows 10/11 (64-bit)
- MetaTrader 5 installed and opened at least once
- Customer Portal account + valid license key

## Steps
1. Download ``Setup.exe`` (verify SHA-256 against ``SHA256SUMS.txt``).
2. Run ``Setup.exe``.
3. Confirm install location (default: ``%LOCALAPPDATA%\THE GOLD MIND PROFESSIONAL``).
4. Allow MT5 detection / EA deploy when prompted.
5. Activate license (email + key). Optional: Google login via
   https://the-gold-mind-ai-v2-professional.vercel.app/login?provider=google
6. Open MT5 -> Navigator -> Expert Advisors -> **The Gold Mind**.
7. Attach ``TheGoldMindAI_Professional`` to your chart.

## Uninstall
Settings -> Apps -> THE GOLD MIND PROFESSIONAL -> Uninstall

## Core note
Installer copies the certified ``.ex5`` only. Trading engine logic is never modified.
"@

  Set-Content (Join-Path $doc "FIRST_RUN_GUIDE.md") -Encoding UTF8 -Value @"
# FIRST_RUN_GUIDE.md

1. Complete installation with ``Setup.exe``.
2. Activate license if skipped (Start Menu -> Activate License).
3. Confirm ``config\license-activation.json`` exists under the install folder.
4. Confirm ``config\mt5-deploy.json`` shows your terminal path.
5. In MT5, enable Algo Trading / AutoTrading.
6. Drag ``TheGoldMindAI_Professional`` onto a chart.
7. If EA missing: Start Menu -> Deploy EA to MT5, then restart MT5.
"@

  Set-Content (Join-Path $doc "RELEASE_PACKAGE.md") -Encoding UTF8 -Value @"
# RELEASE_PACKAGE.md

## Location
``Commercial/Releases/$Version/``

## Contents
| Artifact | Purpose |
|----------|---------|
| ``installer/Setup.exe`` | Windows installer (single canonical) |
| ``TGM_PROFESSIONAL_${Version}_${Channel}.zip`` | Full professional ZIP |
| ``SHA256SUMS.txt`` | Checksums |
| ``SBOM.json`` | Software Bill of Materials |
| ``VERSION_MANIFEST.json`` | Version + Core SHA metadata |
| ``RELEASE_NOTES.md`` | Notes |
| ``GITHUB_RELEASE.md`` | gh release upload commands |
| ``SIGNING_WORKFLOW.md`` | Authenticode modes |

## Core
- mq5 SHA-256: ``$CertSha`` (frozen)
"@

  Set-Content (Join-Path $doc "BUILD_GUIDE.md") -Encoding UTF8 -Value @"
# BUILD_GUIDE.md

## Prerequisite
- Windows ``csc.exe`` (.NET Framework 4.x) **or** Linux ``mcs`` (mono) - used automatically
- Certified ``Experts/TheGoldMindAI_Professional.ex5`` present
- Core mq5 SHA must equal ``$CertSha``
- No duplicate alias installers / no ``github-assets/`` mirror in git

## Build (unsigned / default)
``````powershell
cd "Commercial\Installer\Professional\scripts"
powershell -ExecutionPolicy Bypass -File .\Build-CommercialRelease.ps1
``````

## Sign (standard)
``````powershell
.\Build-CommercialRelease.ps1 -SignMode standard -SignThumbprint <THUMBPRINT>
``````

## Sign (EV PFX)
``````powershell
.\Build-CommercialRelease.ps1 -SignMode ev -SignCertPath .\ev.pfx -SignCertPassword <SECRET>
``````

## Validate
``````powershell
.\Validate-Installer.ps1 -SetupExe "..\..\..\Releases\$Version\installer\Setup.exe"
``````

## Output
``Commercial/Releases/$Version/installer/Setup.exe``

## Absolute rule
Do not modify Trading Engine / Risk / Recovery / Money / Entry / Exit / Order logic / Core SHA.
"@
}

Write-Banner "THE GOLD MIND - Final Commercial Packaging"
Assert-CoreFrozen
New-Payload
Build-LauncherCsc
New-PayloadZip | Out-Null
Build-SetupCsc
$setup = Join-Path $InstallerOut "Setup.exe"
$zip = New-ProfessionalZip
New-Checksums @($setup, $zip) | Out-Null
New-Sbom | Out-Null
New-Manifests -zipPath $zip -setupPath $setup
Invoke-Sign -setupPath $setup
Publish-GitHubAssets
Publish-PortalReleaseAsset -zipPath $zip
Write-Guides

if (-not $SkipValidate) {
  $val = Join-Path $PSScriptRoot "Validate-Installer.ps1"
  & $val -SetupExe $setup -InstallRoot (Join-Path $env:TEMP "TGM-VALIDATE-INSTALL") -SkipActivation
}

Write-Banner "PACKAGING COMPLETE"
Write-Host "Setup.exe: $setup"
if (-not (Test-Path $setup)) { throw "Setup.exe missing - NOT READY" }
Write-Host "READY FOR CUSTOMER INSTALLATION" -ForegroundColor Green

