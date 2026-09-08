param([switch]$Release)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$bundle = Join-Path $projectRoot 'builds/android/tapa-racing.aab'
$javaRoot = (Get-ChildItem -LiteralPath (Join-Path $projectRoot '.tools/jdk') -Directory | Select-Object -First 1).FullName
$signer = Join-Path $javaRoot 'bin/jarsigner.exe'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($bundle)
try { $signed = @($archive.Entries | Where-Object { $_.FullName -match '^META-INF/.+\.(RSA|DSA|EC)$' }).Count -gt 0 }
finally { $archive.Dispose() }
if (-not $signed) {
    if ($Release) {
        $key = $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH
        $alias = $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER
        $passwordVariable = 'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD'
        if (-not $key -or -not $alias -or -not $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD) { throw 'Release signing environment is incomplete.' }
    } else {
        $key = Join-Path $projectRoot '.tools/debug.keystore'
        $alias = 'androiddebugkey'
        $passwordVariable = 'TAPA_AAB_DEBUG_PASSWORD'
        $env:TAPA_AAB_DEBUG_PASSWORD = 'android'
    }
    try {
        & $signer -keystore $key -storepass:env $passwordVariable -keypass:env $passwordVariable -sigalg SHA256withRSA -digestalg SHA-256 $bundle $alias
        if ($LASTEXITCODE -ne 0) { throw 'AAB signing failed.' }
    } finally {
        if (-not $Release) { Remove-Item Env:TAPA_AAB_DEBUG_PASSWORD -ErrorAction SilentlyContinue }
    }
}
$verification = & $signer '-J-Duser.language=en' '-J-Duser.country=US' -verify $bundle
$status = $LASTEXITCODE
$verification | Set-Content -LiteralPath (Join-Path $projectRoot 'builds/logs/aab-signature.log') -Encoding UTF8
if ($status -ne 0 -or -not ($verification -match 'jar verified\.') -or ($verification -match 'jar is unsigned|unsigned entries')) {
    throw 'AAB signature verification failed; see builds/logs/aab-signature.log'
}
Write-Output 'AAB signature verified.'
