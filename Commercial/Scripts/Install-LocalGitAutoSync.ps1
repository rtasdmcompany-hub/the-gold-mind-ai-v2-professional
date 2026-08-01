<#
.SYNOPSIS
  Install a Windows Scheduled Task that auto-pulls GitHub main into this local repo.

.DESCRIPTION
  One-time Owner setup on the Windows machine that holds the project on H: (or any path).
  After install, every GitHub update on main is pulled locally on a timer.

.PARAMETER IntervalMinutes
  How often to sync (default: 5).

.PARAMETER AllowDirty
  Pass -AllowDirty through to the sync script (stashes local edits).

.EXAMPLE
  Right-click → Run with PowerShell (as your normal Windows user):
  .\Commercial\Scripts\Install-LocalGitAutoSync.ps1
#>
[CmdletBinding()]
param(
  [ValidateRange(1, 120)]
  [int]$IntervalMinutes = 5,
  [switch]$AllowDirty
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$syncScript = Join-Path $scriptDir "Sync-LocalFromGitHub.ps1"
if (-not (Test-Path $syncScript)) {
  throw "Missing sync script: $syncScript"
}

$taskName = "TGM-LocalGitAutoSync"
$args = "-NoProfile -ExecutionPolicy Bypass -File `"$syncScript`""
if ($AllowDirty) { $args += " -AllowDirty" }

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $args -WorkingDirectory (Split-Path $syncScript)
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn
$triggerRepeat = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
  -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
  -RepetitionDuration ([TimeSpan]::MaxValue)

$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -MultipleInstances IgnoreNew

# Remove previous registration if present
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask `
  -TaskName $taskName `
  -Action $action `
  -Trigger @($triggerLogon, $triggerRepeat) `
  -Settings $settings `
  -Description "THE GOLD MIND — auto git pull origin/main so local Commercial/Releases stay aligned with GitHub." `
  -Force | Out-Null

Write-Host ""
Write-Host "Installed Scheduled Task: $taskName"
Write-Host "  Interval : every $IntervalMinutes minute(s) + at logon"
Write-Host "  Script   : $syncScript"
Write-Host ""
Write-Host "Running first sync now..."
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $syncScript @(if ($AllowDirty) { "-AllowDirty" })
Write-Host ""
Write-Host "Done. Logs: $(Join-Path $scriptDir 'logs')"
Write-Host "To remove later: .\Commercial\Scripts\Uninstall-LocalGitAutoSync.ps1"
