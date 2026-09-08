param([string]$GodotDirectory = (Join-Path $env:TEMP 'tapa-racing-verify'))
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$localTools = Join-Path $projectRoot '.tools'
$engineDir = Join-Path $localTools 'godot'
New-Item -ItemType Directory -Path $engineDir -Force | Out-Null
foreach ($binary in @('Godot_v4.3-stable_win64.exe', 'Godot_v4.3-stable_win64_console.exe')) {
    $source = Join-Path $GodotDirectory $binary
    if (-not (Test-Path -LiteralPath $source)) { throw "Godot 4.3 missing: $source" }
    Copy-Item -LiteralPath $source -Destination (Join-Path $engineDir $binary) -Force
}
New-Item -ItemType File -Path (Join-Path $engineDir '_sc_') -Force | Out-Null
$editorData = Join-Path $engineDir 'editor_data'
$templates = Join-Path $editorData 'export_templates/4.3.stable'
New-Item -ItemType Directory -Path $templates -Force | Out-Null
foreach ($template in @('android_debug.apk', 'version.txt')) {
    Copy-Item -LiteralPath (Join-Path $env:APPDATA "Godot/export_templates/4.3.stable/$template") -Destination (Join-Path $templates $template) -Force
}
$jdkDirectory = Get-ChildItem -LiteralPath (Join-Path $localTools 'jdk') -Directory | Select-Object -First 1
if (-not $jdkDirectory) { throw 'Extract JDK 17 under .tools/jdk first.' }
$javaPath = $jdkDirectory.FullName
$env:JAVA_HOME = $javaPath
$sdkPath = Join-Path $localTools 'sdk'
$oldBuildTools = Join-Path $sdkPath 'build-tools/android-14'
if (Test-Path -LiteralPath $oldBuildTools) {
    $resolvedOld = (Resolve-Path -LiteralPath $oldBuildTools).Path
    if (-not $resolvedOld.StartsWith($projectRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected tools directory' }
    Rename-Item -LiteralPath $resolvedOld -NewName '34.0.0'
}
$keyPath = Join-Path $localTools 'debug.keystore'
if (-not (Test-Path -LiteralPath $keyPath)) {
    & (Join-Path $javaPath 'bin/keytool.exe') -genkeypair -keystore $keyPath -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Android Debug,O=Android,C=US'
    if ($LASTEXITCODE -ne 0) { throw 'Cannot generate debug-only signing key.' }
}
# Self-contained editor settings: system Java/SDK/editor preferences are untouched.
$javaSetting = $javaPath.Replace('\', '/')
$sdkSetting = $sdkPath.Replace('\', '/')
$keySetting = $keyPath.Replace('\', '/')
$settingsText = @"
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "$javaSetting"
export/android/android_sdk_path = "$sdkSetting"
export/android/debug_keystore = "$keySetting"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
"@
[IO.File]::WriteAllText((Join-Path $editorData 'editor_settings-4.3.tres'), $settingsText)
New-Item -ItemType Directory -Path 'builds/android','builds/logs' -Force | Out-Null
$engine = Join-Path $engineDir 'Godot_v4.3-stable_win64_console.exe'
foreach ($preset in @('Android')) {
    $log = Join-Path $projectRoot ('builds/logs/' + $preset.Replace(' ', '_') + '.log')
    $stdout = Join-Path $projectRoot 'builds/logs/export_stdout.tmp'
    $stderr = Join-Path $projectRoot 'builds/logs/export_stderr.tmp'
    $process = Start-Process -FilePath $engine -ArgumentList @('--headless', '--path', ('"' + $projectRoot + '"'), '--export-debug', ('"' + $preset + '"')) -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $status = $process.ExitCode
    $output = @(Get-Content -LiteralPath $stdout) + @(Get-Content -LiteralPath $stderr)
    $output | Set-Content -LiteralPath $log -Encoding UTF8
    if ($status -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:|WARNING:')) {
        $output | Write-Output
        throw "Export failed: $preset. See $log"
    }
    Write-Output "Exported $preset"
}
$env:JAVA_HOME = $javaPath
& (Join-Path $sdkPath 'build-tools/34.0.0/apksigner.bat') verify --verbose 'builds/android/tapa-racing.apk'
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
$artifacts = foreach ($relative in @('builds/android/tapa-racing.apk', 'builds/android/tapa-racing.aab')) {
    $artifactPath = Join-Path $projectRoot $relative
    if (-not (Test-Path -LiteralPath $artifactPath)) { continue }
    [pscustomobject]@{
        file = $relative
        bytes = (Get-Item -LiteralPath $artifactPath).Length
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash.ToLowerInvariant()
    }
}
[IO.File]::WriteAllText((Join-Path $projectRoot 'builds/artifacts.json'), ($artifacts | ConvertTo-Json))
$artifacts | Format-Table
