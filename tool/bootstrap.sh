#!/usr/bin/env bash
set -euo pipefail

command -v flutter >/dev/null || {
  echo "Flutter wurde nicht gefunden. Flutter 3.47.x installieren."
  exit 1
}

flutter --version
flutter create --platforms=android,ios --org de.steinerkennungsapp --project-name steinerkennungsapp .

python3 - <<'PY'
from pathlib import Path
manifest = Path("android/app/src/main/AndroidManifest.xml")
text = manifest.read_text()
if "android.permission.CAMERA" not in text:
    i = text.index(">")
    perms = '''
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />'''
    text = text[:i+1] + perms + text[i+1:]
    manifest.write_text(text)

plist = Path("ios/Runner/Info.plist")
p = plist.read_text()
if "NSCameraUsageDescription" not in p:
    entries = '''
    <key>NSCameraUsageDescription</key>
    <string>Die Kamera wird nur fuer die von dir gestartete Steinaufnahme verwendet.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Du kannst vorhandene Steinbilder fuer eine Analyse auswaehlen.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Der ungefaehre Standort kann die regionale geologische Plausibilitaet verbessern.</string>
'''
    p = p.replace("</dict>", entries + "\n</dict>")
    plist.write_text(p)
PY

flutter pub get
dart format lib test integration_test
flutter analyze
flutter test
echo "Bootstrap abgeschlossen."
