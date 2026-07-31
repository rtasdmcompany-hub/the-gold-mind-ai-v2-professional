# Run AFTER manual MT5 Strategy Tester completes (AI ON and AI OFF).
# Parses real MT5 artifacts — no synthetic decisions.
param(
  [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\')).Path
$out = Join-Path $repo 'Documentation\Guides\Phase11D'
$evidence = Join-Path $out 'evidence'
New-Item -ItemType Directory -Force -Path $evidence | Out-Null

function Copy-IfExists($src, $dstName) {
  if (Test-Path $src) {
    Copy-Item -Force $src (Join-Path $evidence $dstName)
    return $true
  }
  return $false
}

$artifacts = @{
  reportOn = Copy-IfExists (Join-Path $TerminalData 'Phase11D_AI_ON.htm') 'Phase11D_AI_ON.htm'
  reportOff = Copy-IfExists (Join-Path $TerminalData 'Phase11D_AI_OFF.htm') 'Phase11D_AI_OFF.htm'
  learn = Copy-IfExists (Join-Path $env:APPDATA 'MetaQuotes\Terminal\Common\Files\GM_P11B_EXEC_LEARN.csv') 'GM_P11B_EXEC_LEARN.csv'
}
$latestTesterLog = Get-ChildItem (Join-Path $TerminalData 'Tester\logs') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestTesterLog) { Copy-Item -Force $latestTesterLog.FullName (Join-Path $evidence 'latest-tester.log') }

$summary = @{
  collectedAt = (Get-Date).ToString('o')
  terminalData = $TerminalData
  artifacts = $artifacts
  certified = ($artifacts.reportOn -and $artifacts.reportOff -and $artifacts.learn)
}
$summary | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $evidence 'collection-summary.json') -Encoding UTF8
Write-Host ($summary | ConvertTo-Json -Depth 4)
if (-not $summary.certified) {
  Write-Host 'INCOMPLETE — run Strategy Tester manually for both AI ON and AI OFF, then re-run this script.'
  exit 2
}
exit 0
