param([switch]$WithRendering)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$engine = Join-Path $projectRoot '.tools/godot/Godot_v4.3-stable_win64_console.exe'
New-Item -ItemType Directory -Path 'builds/logs' -Force | Out-Null
$tests = @('test_content_data','test_circuit_loading','test_championships','test_champion_presentations','test_cup_flow','test_cup_races','test_motion','test_game','test_arcade','test_powerups','test_touch_hud','test_race_setup','test_circuit_layout','test_all_courses','test_storm_finish','test_mobile_lifecycle','test_transitions','test_matrix')
if ($WithRendering) { $tests += @('test_android_layouts','test_cup_layouts') }
foreach ($test in $tests) {
    $arguments = @('--path',('"' + $projectRoot + '"'),'--fixed-fps','60','--script',('tests/' + $test + '.gd'))
    if ($test -notin @('test_android_layouts','test_cup_layouts') -and -not ($WithRendering -and $test -eq 'test_champion_presentations')) { $arguments += '--headless' }
    $stdout = Join-Path $projectRoot ('builds/logs/' + $test + '.stdout.tmp')
    $stderr = Join-Path $projectRoot ('builds/logs/' + $test + '.stderr.tmp')
    $process = Start-Process -FilePath $engine -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null = $process.Handle
    $timeoutMs = if ($test -eq 'test_matrix') { 2700000 } else { 900000 }
    if (-not $process.WaitForExit($timeoutMs)) {
        $process.Kill()
        throw "Test timeout: $test"
    }
    $output = @(Get-Content -LiteralPath $stdout) + @(Get-Content -LiteralPath $stderr)
    $output | Set-Content -LiteralPath ('builds/logs/' + $test + '.log') -Encoding UTF8
    if ($process.ExitCode -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:|FAIL:')) {
        throw "Test failed: $test; see builds/logs/$test.log"
    }
    Write-Output "PASS: $test"
}
