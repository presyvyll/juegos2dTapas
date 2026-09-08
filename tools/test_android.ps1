param([switch]$WithRendering)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$engine = Join-Path $projectRoot '.tools/godot/Godot_v4.3-stable_win64_console.exe'
New-Item -ItemType Directory -Path 'builds/logs' -Force | Out-Null
$tests = @('test_motion','test_game','test_arcade','test_powerups','test_touch_hud','test_race_setup','test_mobile_lifecycle','test_transitions','test_matrix')
if ($WithRendering) { $tests += 'test_android_layouts' }
foreach ($test in $tests) {
    $arguments = @('--path',('"' + $projectRoot + '"'),'--fixed-fps','60','--script',('tests/' + $test + '.gd'))
    if ($test -ne 'test_android_layouts') { $arguments += '--headless' }
    $stdout = Join-Path $projectRoot ('builds/logs/' + $test + '.stdout.tmp')
    $stderr = Join-Path $projectRoot ('builds/logs/' + $test + '.stderr.tmp')
    $process = Start-Process -FilePath $engine -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null = $process.Handle
    if (-not $process.WaitForExit(900000)) {
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
