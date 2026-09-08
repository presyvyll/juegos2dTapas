param([string]$Serial = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$adb = Join-Path $projectRoot '.tools/sdk/platform-tools/adb.exe'
$devices = @(& $adb devices | Select-String '^\S+\s+device$' | ForEach-Object { ($_.Line -split '\s+')[0] })
if (-not $Serial) {
    if ($devices.Count -ne 1) { throw 'Connect exactly one authorized Android device, or provide -Serial.' }
    $Serial = $devices[0]
}
if ($Serial -notin $devices) { throw 'The requested device is not connected and authorized.' }
$report = Join-Path $projectRoot ('builds/device-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $report -Force | Out-Null
& $adb -s $Serial shell getprop ro.product.model | Set-Content (Join-Path $report 'model.txt')
& $adb -s $Serial shell wm size | Set-Content (Join-Path $report 'screen.txt')
& $adb -s $Serial shell wm density | Add-Content (Join-Path $report 'screen.txt')
& $adb -s $Serial shell dumpsys meminfo com.taparacing.game | Set-Content (Join-Path $report 'memory.txt')
& $adb -s $Serial shell dumpsys thermalservice | Set-Content (Join-Path $report 'thermal.txt')
& $adb -s $Serial shell dumpsys gfxinfo com.taparacing.game framestats | Set-Content (Join-Path $report 'frames.txt')
Write-Output "Read-only device reports: $report"
Write-Output 'SurfaceView frame timing may require Perfetto; gfxinfo alone does not certify game FPS.'
