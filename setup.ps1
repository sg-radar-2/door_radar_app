# Door Radar app - first-time setup (Windows PowerShell)
# Run from this folder:
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1
#
# 1) generates android/ and ios/ with `flutter create` (existing files in lib/, test/, docs/ are kept)
# 2) adds packages with `flutter pub add` (latest compatible versions)
# 3) patches AndroidManifest.xml (cleartext http to the Pi, permissions)
# 4) runs analyze + test

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

function Run($cmd) {
    Write-Host "`n> $cmd" -ForegroundColor Cyan
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ne 0) { throw "failed: $cmd" }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'flutter is not on PATH. Install Flutter SDK first: https://docs.flutter.dev/get-started/install/windows'
}

Run 'flutter --version'
Run 'flutter create --org com.sgradar --project-name door_radar_app --platforms android,ios --no-pub .'

Run 'flutter pub add flutter_riverpod go_router dio web_socket_channel nsd flutter_secure_storage flutter_local_notifications cached_network_image sqflite path_provider gal intl freezed_annotation json_annotation'
Run 'flutter pub add dev:build_runner dev:freezed dev:json_serializable dev:flutter_lints'

# --- AndroidManifest: cleartext to Pi + permissions --------------------------
$manifest = Join-Path $PSScriptRoot 'android\app\src\main\AndroidManifest.xml'
$xml = [IO.File]::ReadAllText($manifest)
if ($xml -notmatch 'networkSecurityConfig') {
    $xml = $xml -replace '<application', '<application android:networkSecurityConfig="@xml/network_security_config"'
}
if ($xml -notmatch 'android.permission.INTERNET') {
    $perms = @(
        'android.permission.INTERNET',
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.ACCESS_WIFI_STATE',
        'android.permission.CHANGE_WIFI_MULTICAST_STATE',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.VIBRATE'
    ) | ForEach-Object { "    <uses-permission android:name=`"$_`" />" }
    $xml = $xml -replace '(<manifest[^>]*>)', ("`$1`n" + ($perms -join "`n"))
}
if ($xml -notmatch 'WRITE_EXTERNAL_STORAGE') {
    # gal(갤러리 저장): Android 9 이하만 필요
    $xml = $xml -replace '(<manifest[^>]*>)', ("`$1`n" + '    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />')
}
[IO.File]::WriteAllText($manifest, $xml)
Write-Host "patched $manifest" -ForegroundColor Green

# 파이는 같은 Wi-Fi 의 http://<IP>:8080 이라 IP 를 미리 알 수 없다 → 평문 http 전체 허용
$nscDir = Join-Path $PSScriptRoot 'android\app\src\main\res\xml'
New-Item -ItemType Directory -Force $nscDir | Out-Null
$nsc = Join-Path $nscDir 'network_security_config.xml'
if (-not (Test-Path $nsc)) {
    [IO.File]::WriteAllText($nsc, @'
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- 파이(같은 Wi-Fi, http://<IP>:8080)와 평문으로 통신한다 -->
    <base-config cleartextTrafficPermitted="true" />
</network-security-config>
'@)
    Write-Host "created $nsc" -ForegroundColor Green
}

# flutter_local_notifications 는 core library desugaring 을 요구한다
$gradle = Join-Path $PSScriptRoot 'android\app\build.gradle.kts'
if ((Test-Path $gradle) -and ([IO.File]::ReadAllText($gradle) -notmatch 'isCoreLibraryDesugaringEnabled')) {
    $g = [IO.File]::ReadAllText($gradle)
    $g = $g -replace '(compileOptions\s*\{)', "`$1`n        isCoreLibraryDesugaringEnabled = true"
    if ($g -match '(?m)^dependencies\s*\{') {
        $g = $g -replace '(?m)^(dependencies\s*\{)', "`$1`n    coreLibraryDesugaring(`"com.android.tools:desugar_jdk_libs:2.1.4`")"
    } else {
        $g += "`ndependencies {`n    coreLibraryDesugaring(`"com.android.tools:desugar_jdk_libs:2.1.4`")`n}`n"
    }
    [IO.File]::WriteAllText($gradle, $g)
    Write-Host "patched $gradle (core library desugaring)" -ForegroundColor Green
}

Run 'flutter analyze'
Run 'flutter test'

Write-Host "`nDone. Next: start the mock server (mock_server\README in README.md) and run 'flutter run'." -ForegroundColor Green
