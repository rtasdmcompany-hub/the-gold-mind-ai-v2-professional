<#
.SYNOPSIS
  Remove the TGM local GitHub auto-sync Scheduled Task.
#>
[CmdletBinding()]
param()

$taskName = "TGM-LocalGitAutoSync"
$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (-not $existing) {
  Write-Host "Task '$taskName' is not installed."
  exit 0
}
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
Write-Host "Removed Scheduled Task: $taskName"
