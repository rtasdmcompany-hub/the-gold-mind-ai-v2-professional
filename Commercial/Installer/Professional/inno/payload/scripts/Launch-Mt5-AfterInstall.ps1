# Launch official MetaQuotes MetaTrader 5 only — never Exness/FTMO/XM broker terminals.
param(
  [string]$InstallRoot = "$env:LOCALAPPDATA\THE GOLD MIND PROFESSIONAL",
  [string]$TerminalDataPath = ""
)

$ErrorActionPreference = "Continue"

$BrokerMarkers = @(
  "exness", "ftmo", "xm global", "xm.com", "ic markets", "icmarkets",
  "pepperstone", "roboforex", "fxpro", "tickmill"
)

function Test-BrokerPath([string]$Path) {
  if (-not $Path) { return $false }
  $lower = $Path.ToLowerInvariant()
  foreach ($m in $BrokerMarkers) {
    if ($lower.Contains($m)) { return $true }
  }
  return $false
}

function Test-MetaQuotesOfficialExe([string]$Exe) {
  if (-not $Exe -or -not (Test-Path $Exe)) { return $false }
  if (Test-BrokerPath $Exe) { return $false }
  try {
    $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Exe)
    $blob = ("{0} {1} {2}" -f $vi.CompanyName, $vi.ProductName, $vi.FileDescription).ToLowerInvariant()
    foreach ($m in $BrokerMarkers) {
      if ($blob.Contains($m)) { return $false }
    }
    return $blob.Contains("metaquotes")
  } catch {
    return $false
  }
}

function Get-OfficialMt5Exe {
  $dirs = @(
    (Join-Path ${env:ProgramFiles} "MetaTrader 5")
    (Join-Path ${env:ProgramFiles(x86)} "MetaTrader 5")
  )
  foreach ($pf in $dirs) {
    foreach ($name in @("terminal64.exe", "Terminal64.exe", "terminal.exe")) {
      $exe = Join-Path $pf $name
      if (Test-MetaQuotesOfficialExe $exe) { return $exe }
    }
  }
  return $null
}

function Get-OfficialMt5DataFolder {
  $officialExe = Get-OfficialMt5Exe
  $officialDir = if ($officialExe) { Split-Path $officialExe -Parent } else { $null }

  foreach ($root in @(
    (Join-Path $env:APPDATA "MetaQuotes\Terminal")
    (Join-Path $env:LOCALAPPDATA "MetaQuotes\Terminal")
  )) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
      $origin = Join-Path $_.FullName "origin.txt"
      if (-not (Test-Path $origin)) { return }
      try {
        $installDir = (Get-Content $origin -Raw).Trim().Trim('"')
        if (Test-BrokerPath $installDir) { return }
        $exe = Join-Path $installDir "terminal64.exe"
        if (-not (Test-Path $exe)) { $exe = Join-Path $installDir "terminal.exe" }
        if (Test-MetaQuotesOfficialExe $exe) {
          if ($officialDir -and ([IO.Path]::GetFullPath($installDir).TrimEnd('\') -ieq [IO.Path]::GetFullPath($officialDir).TrimEnd('\'))) {
            return $_.FullName
          }
        }
      } catch { }
    }
  }
  return $officialDir
}

function Enable-Mt5AlgoTrading([string]$DataPath) {
  if (-not $DataPath) { return }
  foreach ($iniName in @("terminal.ini", "common.ini")) {
    $ini = Join-Path $DataPath "config\$iniName"
    if (-not (Test-Path $ini)) { continue }
    try {
      $text = Get-Content $ini -Raw -ErrorAction Stop
      if ($text -match '\[Experts\]') {
        if ($text -notmatch 'Enabled\s*=') {
          $text = $text -replace '\[Experts\]', "[Experts]`r`nEnabled=1"
        } else {
          $text = $text -replace '(?m)^Enabled\s*=.*$', 'Enabled=1'
        }
      } else {
        $text += "`r`n[Experts]`r`nEnabled=1`r`n"
      }
      Set-Content -Path $ini -Value $text -Encoding Unicode
    } catch { }
  }
}

$dataPath = Get-OfficialMt5DataFolder
if ($dataPath) { Enable-Mt5AlgoTrading -DataPath $dataPath }

$exe = Get-OfficialMt5Exe
if (-not $exe) {
  Write-Warning "Official MetaQuotes MetaTrader 5 not found. Broker terminals (Exness) will NOT be launched."
  try { Start-Process "https://www.metatrader5.com/en/download" } catch { }
  exit 3
}

Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe -Parent)
exit 0
