# Phase 11D — launch real MT5 Strategy Tester (AI ON then AI OFF)
# Uses existing terminal data folder credentials when available.
param(
  [string]$Mode = 'AI_ON'  # AI_ON | AI_OFF | BOTH
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\')).Path
$d0 = Join-Path $env:APPDATA 'MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075'
$exInstall = Join-Path $env:APPDATA 'MetaTrader 5 EXNESS'
$evidence = Join-Path $repo 'Documentation\Guides\Phase11D\evidence'
New-Item -ItemType Directory -Force -Path $evidence | Out-Null

$terminalExe = Join-Path $env:ProgramFiles 'MetaTrader 5\terminal64.exe'
$testerExe = $terminalExe
if (-not (Test-Path $testerExe)) { throw "No MT5 tester executable found" }

function Build-Ini([string]$report, [string]$setName) {
  @"
[Tester]
Expert=TheGoldMindAI_Professional
Symbol=XAUUSDm
Period=H4
Login=262523237
Server=Exness-MT5Trial16
Optimization=0
Model=4
FromDate=2026.06.02
ToDate=2026.06.20
ForwardMode=0
Deposit=10000
Currency=USD
ProfitInPips=0
Leverage=100
ExecutionMode=0
Visual=0
ExpertParameters=$setName
Report=$report
ReplaceReport=1
ShutdownTerminal=1
UseLocal=1
"@ 
}

function Run-Case([string]$name, [string]$setName) {
  $iniPath = Join-Path $d0 "config\Phase11D_$name.ini"
  $report = "Phase11D_$name"
  Build-Ini $report $setName | Set-Content -Encoding ASCII $iniPath
  Remove-Item (Join-Path $d0 "$report.htm") -ErrorAction SilentlyContinue
  Remove-Item (Join-Path $d0 "$report.png") -ErrorAction SilentlyContinue
  Write-Host "Running $name ..."
  Get-Process -Name terminal64,metatester64 -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep -Seconds 3
  $p = Start-Process -FilePath $testerExe -ArgumentList "/config:`"$iniPath`"" -PassThru -Wait -WindowStyle Hidden
  $htm = Join-Path $d0 "$report.htm"
  $ok = Test-Path $htm
  if ($ok) {
    Copy-Item -Force $htm (Join-Path $evidence "$report.htm")
    if (Test-Path (Join-Path $d0 "$report.png")) { Copy-Item -Force (Join-Path $d0 "$report.png") (Join-Path $evidence "$report.png") }
  }
  $log = Get-ChildItem (Join-Path $d0 'Tester\logs') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($log) { Copy-Item -Force $log.FullName (Join-Path $evidence "tester_$name.log") }
  return @{ name = $name; exitCode = $p.ExitCode; reportExists = $ok; report = $htm }
}

# Ensure EA + sets in D0
Copy-Item -Force (Join-Path $repo 'Scripts\Phase11D\Phase11D_AI_ON.set') (Join-Path $d0 'MQL5\Profiles\Tester\Phase11D_AI_ON.set')
Copy-Item -Force (Join-Path $repo 'Scripts\Phase11D\Phase11D_AI_OFF.set') (Join-Path $d0 'MQL5\Profiles\Tester\Phase11D_AI_OFF.set')

$results = @()
if ($Mode -eq 'AI_ON' -or $Mode -eq 'BOTH') { $results += Run-Case 'AI_ON' 'Phase11D_AI_ON.set' }
if ($Mode -eq 'AI_OFF' -or $Mode -eq 'BOTH') { $results += Run-Case 'AI_OFF' 'Phase11D_AI_OFF.set' }

$learn = Join-Path $env:APPDATA 'MetaQuotes\Terminal\Common\Files\GM_P11B_EXEC_LEARN.csv'
if (Test-Path $learn) { Copy-Item -Force $learn (Join-Path $evidence 'GM_P11B_EXEC_LEARN.csv') }

$results | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $evidence 'tester-run-results.json') -Encoding UTF8
Write-Host ($results | ConvertTo-Json -Depth 4)
