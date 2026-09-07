$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$binary = Join-Path $projectRoot 'builds/windows/TapaRacing.exe'
$logDirectory = Join-Path $projectRoot 'builds/logs'
if (-not (Test-Path -LiteralPath $binary)) { throw 'Build Windows Debug first.' }
$cases = @(
    @{ Name = 'export_menu'; Arguments = @('--headless', '--quit-after', '120') },
    @{ Name = 'export_race'; Arguments = @('--headless', 'res://levels/race.tscn', '--quit-after', '360') },
    @{ Name = 'export_integration'; Arguments = @('--headless', '--fixed-fps', '60', '--script', ('"' + (Join-Path $projectRoot 'tests/test_game.gd') + '"')) }
)
foreach ($case in $cases) {
    $stdout = Join-Path $logDirectory ($case.Name + '.log')
    $stderr = Join-Path $logDirectory ($case.Name + '.errors.log')
    # Run away from project.godot to exercise the embedded game pack.
    $process = Start-Process -FilePath $binary -WorkingDirectory $env:TEMP -ArgumentList $case.Arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null = $process.Handle
    if (-not $process.WaitForExit(45000)) {
        Stop-Process -Id $process.Id
        throw "Timed out: $($case.Name)"
    }
    $content = @(Get-Content -LiteralPath $stdout) + @(Get-Content -LiteralPath $stderr)
    if ($process.ExitCode -ne 0 -or ($content -match 'SCRIPT ERROR:|ERROR:|WARNING:')) {
        $content | Write-Output
        throw "Export test failed: $($case.Name)"
    }
    if ($case.Name -eq 'export_integration' -and -not ($content -match 'RESULT: 0 failures')) {
        throw 'Integration test did not complete.'
    }
    Write-Output "PASS: $($case.Name)"
}
