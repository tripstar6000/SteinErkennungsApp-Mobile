# Release Readiness – 9 Bloecke / 4 Phasen

## Phase A – Mobile Core
1. Flutter-Grundlage: **IMPLEMENTIERT**
2. Kamera/Galerie/2–3 Perspektiven/gefuehrte 180°-Sequenz: **IMPLEMENTIERT**
3. SQLite-Historie/Offline-Pakete: **IMPLEMENTIERT**
4. Standortberechtigung und reduzierte Koordinaten: **IMPLEMENTIERT**
5. Suche/Sammlung/Karte/Einstellungen: **IMPLEMENTIERT**

## Phase B – Intelligence
6. TFLite-Runtime + Integritaetspruefung: **IMPLEMENTIERT**
7. Grundlegendes Offline-Modell: **TRAININGSPIPELINE IMPLEMENTIERT**
   - Quelle: udayl/rocks, MIT
   - Modell: MobileNetV3Small Transfer Learning
   - CI erzeugt TFLite, Labels, Manifest und Metriken
   - reales Training muss im verbundenen CI einmal ausgefuehrt werden
8. Server-Fallback / Top-3 / Vergleichsbilder: **IMPLEMENTIERT**
9. Physischer Nachtest offline: **IMPLEMENTIERT**
10. Deutschlandweite Geologie: **ONLINE ueber bestehendes Backend; kuratierte Offline-Profile vorhanden**

## Phase C – Validation
11. Modell-Testsplit-Metriken: **AUTOMATISCH DURCH TRAININGSPIPELINE**
12. Unabhaengige reale Ground-Truth-Faelle: **OFFEN**
13. Kalibrierte Gewichtung: **GESPERRT bis echte Ground Truth vorhanden ist**
14. Zielgeraete-Benchmarks Android/iPhone: **OFFEN nach erstem APK/TestFlight-Build**

## Phase D – Production
15. CI Analyze/Test/Android/iOS unsigned: **IMPLEMENTIERT**
16. Datenschutz/Security-Dokumentation: **IMPLEMENTIERT**
17. Android Debug/Release-APK als CI-Artefakt: **IMPLEMENTIERT im Workflow**
18. Android Store-Signing: **BENUTZER-KONTO/KEYSTORE ERFORDERLICH**
19. iOS Signing/TestFlight: **APPLE DEVELOPER KONTO ERFORDERLICH**

## Was fuer eine testbare App noch konkret fehlt
- Repository muss in einer CI-Umgebung liegen, damit Flutter tatsaechlich ausgefuehrt werden kann.
- Danach Workflowfehler automatisch beheben, bis Analyze/Test/Build gruen sind.
- Offline-Modelltraining einmal ausfuehren und seine realen Metriken pruefen.
- APK auf realem Android-Geraet testen.
