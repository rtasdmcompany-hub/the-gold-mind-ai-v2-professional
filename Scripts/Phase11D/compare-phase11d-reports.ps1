# Phase 11D — compare real MT5 ON vs OFF HTML reports (evidence only).
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\')).Path
$ev = Join-Path $repo 'Documentation\Guides\Phase11D\evidence'
$onPath = Join-Path $ev 'Phase11D_AI_ON.htm'
$offPath = Join-Path $ev 'Phase11D_AI_OFF.htm'
$learnPath = Join-Path $ev 'GM_P11B_EXEC_LEARN.csv'

function Get-VolumePriceRows([string]$html) {
  $ms = [regex]::Matches($html, '(?is)<td[^>]*>\s*(buy|sell)\s*</td>\s*<td[^>]*>[^<]*</td>\s*<td[^>]*>\s*([\d\.\s]+)\s*</td>\s*<td[^>]*>\s*([\d\.\s]+)\s*</td>')
  $list = @()
  foreach ($m in $ms) {
    $list += [pscustomobject]@{
      Dir   = $m.Groups[1].Value
      Vol   = [double](($m.Groups[2].Value -replace '\s', ''))
      Price = [double](($m.Groups[3].Value -replace '\s', ''))
    }
  }
  return $list
}

function Get-Metric([string]$html, [string]$label) {
  $re = '(?s)' + [regex]::Escape($label) + '.*?<b>(.*?)</b>'
  if ($html -match $re) { return $Matches[1].Trim() }
  return $null
}

$onHtml = Get-Content $onPath -Raw
$offHtml = Get-Content $offPath -Raw
$onVP = Get-VolumePriceRows $onHtml
$offVP = Get-VolumePriceRows $offHtml
$n = [Math]::Min($onVP.Count, $offVP.Count)
$priceSame = 0
$volDiff = 0
$dirDiff = 0
for ($i = 0; $i -lt $n; $i++) {
  if ($onVP[$i].Dir -ne $offVP[$i].Dir) { $dirDiff++ }
  if ([Math]::Abs($onVP[$i].Price - $offVP[$i].Price) -lt 0.0001) { $priceSame++ }
  if ([Math]::Abs($onVP[$i].Vol - $offVP[$i].Vol) -gt 0.0001) { $volDiff++ }
}

$learn = @(Get-Content $learnPath)
$actions = $learn | ForEach-Object {
  $p = $_.Split(',')
  if ($p.Count -ge 2) { $p[1] }
} | Group-Object | Sort-Object Count -Descending | ForEach-Object {
  [pscustomobject]@{ Action = $_.Name; Count = $_.Count }
}
$forbidden = @($learn | Where-Object {
  $_ -match 'MODIFY_TP|MODIFY_SL|CHANGE_DIRECTION|ACTIVE_TRADE_MODIFY|MOVE_PENDING_PRICE|OVERRIDE_H4|OVERRIDE_ATR'
})

$summary = [ordered]@{
  collectedAt = (Get-Date).ToString('o')
  historyQualityOn = (Get-Metric $onHtml 'History Quality')
  historyQualityOff = (Get-Metric $offHtml 'History Quality')
  ticksOn = if ($onHtml -match 'Ticks:</td>\s*<td[^>]*>\s*<b>(.*?)</b>') { $Matches[1] } else { $null }
  ticksOff = if ($offHtml -match 'Ticks:</td>\s*<td[^>]*>\s*<b>(.*?)</b>') { $Matches[1] } else { $null }
  totalTradesOn = (Get-Metric $onHtml 'Total Trades')
  totalTradesOff = (Get-Metric $offHtml 'Total Trades')
  netProfitOn = (Get-Metric $onHtml 'Total Net Profit')
  netProfitOff = (Get-Metric $offHtml 'Total Net Profit')
  profitFactorOn = (Get-Metric $onHtml 'Profit Factor')
  profitFactorOff = (Get-Metric $offHtml 'Profit Factor')
  dealRowsCompared = $n
  priceSame = $priceSame
  volumeDifferent = $volDiff
  directionDifferent = $dirDiff
  learnActions = $actions
  forbiddenLearnLines = $forbidden.Count
  priceIntegrityPass = ($priceSame -eq $n -and $n -gt 0 -and $dirDiff -eq 0)
  volumePolicyObserved = ($volDiff -gt 0)
  sameTradeCount = ((Get-Metric $onHtml 'Total Trades') -eq (Get-Metric $offHtml 'Total Trades'))
}

$summary | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $ev 'phase11d-comparison.json') -Encoding UTF8
Write-Host ($summary | ConvertTo-Json -Depth 6)
Write-Host 'FIRST_10_ON'
$onVP | Select-Object -First 10 | Format-Table -AutoSize | Out-String | Write-Host
Write-Host 'FIRST_10_OFF'
$offVP | Select-Object -First 10 | Format-Table -AutoSize | Out-String | Write-Host
