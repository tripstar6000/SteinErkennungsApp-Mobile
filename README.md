# SteinErkennungsApp Mobile RC1

Produktives Flutter-Repositorium fuer Android/iOS, abgeleitet aus dem funktionsfaehigen Web-Prototyp.

## Zielarchitektur

- Flutter 3.47 / Dart >= 3.12
- Clean-Architecture-orientierte Modultrennung
- Riverpod fuer Dependency Injection / State
- SQLite (`sqflite`) fuer lokale Historie und Offline-Pakete
- TFLite-Runtime (`tflite_flutter`) fuer ein spaeter einzuspielendes, fachlich validiertes On-Device-Modell
- Remote-Fallback auf das bestehende SteinErkennungsApp-Backend
- 2–3 Perspektiven inkl. gefuehrter 180°-Sequenz
- Standort nur nach Zustimmung; reduzierte Koordinaten
- Physischer Nachtest offline
- Kartenansicht ohne sensible Fundstellen

## Start unter Windows

1. Flutter 3.47.x installieren.
2. PowerShell im Projektordner:
   `powershell -ExecutionPolicy Bypass -File .\tool\bootstrap.ps1`
3. Danach:
   `flutter run`

## Aktueller harter Blocker

Ein fachlich validiertes TFLite-Steinmodell ist **nicht** in diesem Repository enthalten.
Es wird absichtlich kein Fake-Modell ausgeliefert. Die App faellt online auf die
bestehende Server-Erkennung zurueck. Ohne Internet bleiben Katalog, Sammlung,
physischer Nachtest und installierte Offline-Pakete verfuegbar.

Siehe `docs/RELEASE_READINESS.md`.


## Automatischer Offline-Modell- und APK-Build

Sobald das Repository auf GitHub liegt:
1. Workflow `train-offline-model-and-build` starten.
2. Er trainiert aus dem MIT-Dataset `udayl/rocks`.
3. Er prueft das Flutter-Projekt.
4. Er erzeugt ein APK-Artefakt mit eingebettetem, SHA-256-geprueftem Offline-Modell.

Damit benoetigt das grundlegende Offline-MVP kein proprietaeres Fremdmodell.
