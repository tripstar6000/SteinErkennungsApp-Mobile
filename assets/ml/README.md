# ML-Artefakt

Die Runtime erwartet ein fachlich validiertes TFLite-Modell als herunterladbares Modellpaket.
Der Dateiname ist standardmaessig `stone_classifier.tflite`.

**Absichtlich nicht enthalten:** Ein erfundenes oder fachlich ungeprueftes Modell.

Bis ein freigegebenes Modell vorhanden ist:
- Online: serverseitige Bildanalyse ueber die bestehende API.
- Offline: Katalog, Sammlung, physischer Eigenschaftsabgleich und gecachte Daten funktionieren.
- Offline-Foto-Klassifikation meldet `MODEL_UNAVAILABLE`, statt Fake-Treffer zu erzeugen.
