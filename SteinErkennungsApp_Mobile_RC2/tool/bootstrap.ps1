$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter wurde nicht gefunden. Bitte Flutter 3.47.x installieren und erneut starten."
}

flutter --version
flutter create --platforms=android,ios --org de.steinerkennungsapp --project-name steinerkennungsapp .

$manifest = "android/app/src/main/AndroidManifest.xml"
$xml = Get-Content $manifest -Raw
if ($xml -notmatch "android.permission.CAMERA") {
  $permissions = @"
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />
"@
  $xml = [regex]::Replace($xml, "(<manifest[^>]*>)", ('$1' + "`n" + $permissions), 1)
  Set-Content $manifest $xml -Encoding UTF8
}

$plist = "ios/Runner/Info.plist"
$p = Get-Content $plist -Raw
if ($p -notmatch "NSCameraUsageDescription") {
  $entries = @"
    <key>NSCameraUsageDescription</key>
    <string>Die Kamera wird nur fuer die von dir gestartete Steinaufnahme verwendet.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Du kannst vorhandene Steinbilder fuer eine Analyse auswaehlen.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Der ungefaehre Standort kann die regionale geologische Plausibilitaet verbessern.</string>
"@
  $p = $p -replace "</dict>", "$entries`n</dict>"
  Set-Content $plist $p -Encoding UTF8
}

flutter pub get
dart format lib test integration_test
flutter analyze
flutter test

Write-Host "Bootstrap abgeschlossen. Android/iOS-Plattformordner wurden erzeugt und konfiguriert."
