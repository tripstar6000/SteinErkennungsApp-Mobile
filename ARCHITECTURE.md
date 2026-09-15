# Architektur

## Schichten

### presentation
`lib/features/*` und `lib/shared/*`

### domain
`lib/domain/*`

### data
`lib/data/local`, `lib/data/remote`, `lib/data/repositories`

### services
Standort, Bildvorbereitung, TFLite-Runtime, physischer Nachtest, Offline-Pakete

## State Management

Riverpod wurde gewaehlt, weil Abhaengigkeiten (DB, API, ML, Standort) testbar
injiziert werden koennen und Flutter-UI nicht direkt an Implementierungen gebunden wird.

## Erkennung

1. 2–3 Bilder aufnehmen/waehlen
2. EXIF-Ausrichtung korrigieren
3. auf max. 1400 px skalieren
4. lokales Modell versuchen
5. bei fehlendem Modell: Remote-API
6. Standortkontext getrennt halten
7. Top-3 darstellen
8. optional physischer Nachtest
9. Ergebnis lokal speichern
