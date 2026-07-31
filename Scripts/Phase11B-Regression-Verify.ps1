# Phase 11B static regression verifier
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ea = Join-Path $root 'Experts\TheGoldMindAI_Professional.mq5'
$p11b = Join-Path $root 'Include\AI\ExecutionSupervisor\Phase11B'

$fail = 0
$content = Get-Content -LiteralPath $ea -Raw

if ($content -notmatch 'TGM_RISK_PER_TRADE_FRACTION\s+0\.03') { Write-Host 'FAIL: risk fraction changed'; $fail++ }
if ($content -notmatch 'GmP11B_AdjustLot') { Write-Host 'FAIL: P11B lot hook missing'; $fail++ }
if ($content -notmatch 'GmP11B_OnTick') { Write-Host 'FAIL: P11B tick hook missing'; $fail++ }
if ($content -match 'CalculateAutoLotSize[\s\S]{0,200}GmP11B') { Write-Host 'FAIL: AI inside CalculateAutoLotSize'; $fail++ }

$auth = Get-Content (Join-Path $p11b 'CPhase11BExecutionAuthority.mqh') -Raw
if ($auth -match 'PositionClose|OrderModify|TRADE_ACTION_SLTP') { Write-Host 'FAIL: AI modifies active trades'; $fail++ }

$required = @(
  'Phase11BConstants.mqh',
  'CPhase11BExecutionAuthority.mqh',
  'CGmEAPreActivationBridge.mqh'
)
foreach ($f in $required) {
  if (-not (Test-Path (Join-Path $p11b $f))) { Write-Host "FAIL: missing $f"; $fail++ }
}

if ($fail -eq 0) {
  Write-Host 'Phase 11B regression static verification: PASS'
  exit 0
}
Write-Host "Phase 11B regression static verification: FAIL ($fail issues)"
exit 1
