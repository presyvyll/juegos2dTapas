param([switch]$Release)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$env:JAVA_HOME = (Get-ChildItem -LiteralPath '.tools/jdk' -Directory | Select-Object -First 1).FullName
$env:ANDROID_HOME = Join-Path $projectRoot '.tools/sdk'
$env:GRADLE_USER_HOME = Join-Path $projectRoot '.tools/gradle'
$env:DEBUG = ''
if (-not (Test-Path -LiteralPath 'android/build/gradlew.bat')) {
    throw 'Install the Godot 4.3 Android Gradle template first: python tools/setup_aab.py'
}
if ($Release -and (-not $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH -or -not $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER -or -not $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD)) {
    throw 'Set the three GODOT_ANDROID_KEYSTORE_RELEASE_* environment variables for an existing release key. No keys are created or changed.'
}
$mode = if ($Release) { '--export-release' } else { '--export-debug' }
$stdout = Join-Path $projectRoot 'builds/logs/aab_stdout.tmp'
$stderr = Join-Path $projectRoot 'builds/logs/aab_stderr.tmp'
New-Item -ItemType Directory -Path 'builds/logs','builds/android' -Force | Out-Null
$process = Start-Process -FilePath '.tools/godot/Godot_v4.3-stable_win64_console.exe' -ArgumentList @('--headless','--path',('"' + $projectRoot + '"'),$mode,'"Android AAB"') -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$null = $process.Handle
$process.WaitForExit()
$output = @(Get-Content -LiteralPath $stdout) + @(Get-Content -LiteralPath $stderr)
foreach ($secret in @($env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD, $env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD)) {
    if ($secret) { $output = @($output | ForEach-Object { $_.Replace($secret, '[REDACTED]') }) }
}
$output | Set-Content -LiteralPath 'builds/logs/Android_AAB.log' -Encoding UTF8
if ($process.ExitCode -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:|BUILD FAILED')) {
    $output | Select-Object -Last 60 | Write-Output
    throw 'AAB export failed; see builds/logs/Android_AAB.log'
}
& (Join-Path $PSScriptRoot 'sign_aab.ps1') -Release:$Release
Get-Item -LiteralPath 'builds/android/tapa-racing.aab' | Select-Object Name,Length
