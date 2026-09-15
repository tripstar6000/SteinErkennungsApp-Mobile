# ML Model

## Runtime
`tflite_flutter ^0.12.1`

## Reproduzierbarer Offline-MVP

Das Repository enthaelt `ml/train_offline_rock_model.py`.
Die Pipeline trainiert ein MobileNetV3Small-Transfer-Learning-Modell auf
`udayl/rocks` (MIT-Lizenz) und exportiert ein TFLite-Modell.

Die Trainingspipeline:
- entdeckt die Klassenliste aus dem Datensatz,
- erzeugt deterministische Train/Validation/Test-Splits,
- misst Test-Accuracy und Top-3,
- erzeugt eine Confusion Matrix,
- exportiert TFLite,
- schreibt Labels und SHA-256-Manifest.

Die Release-App laedt das Modell nur, wenn Modell + Labels exakt zum Manifest
passen. Andernfalls faellt sie auf die Online-Erkennung zurueck.

## Wichtige fachliche Grenze

Das oeffentliche MIT-Dataset liefert eine **grundlegende Offline-Gesteinsklassifikation**.
Es ersetzt nicht die viel feinere Online-Erkennung fuer alle Mineralvarietaeten.
Das entspricht dem Offline-MVP: grundlegende Erkennung funktioniert lokal,
die hochaufgeloeste Stein-/Mineralbestimmung kann online erweitert werden.

## Release-Gate fuer spaetere 76+ Klassen

Fuer ein feines Mineralmodell muessen zusaetzlich:
1. jede Klasse ausreichend viele lizenzierte, fachlich verifizierte Bilder besitzen,
2. Trainings/Validation/Test strikt getrennt sein,
3. externe Ground-Truth-Proben verwendet werden,
4. Top-1 / Top-3 / Precision / Recall / F1 / Confusion Matrix dokumentiert werden,
5. mehrere Kameras, Beleuchtungen, nasse/trockene und polierte/unpolierte Proben getestet werden.

Keine Genauigkeitszahl darf erfunden werden.
