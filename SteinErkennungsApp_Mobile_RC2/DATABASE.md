# Lokale Datenbank

SQLite v1:

## scans
- id
- timestamp
- top_candidate
- visual_fit
- image_paths (JSON)
- latitude / longitude (reduziert)
- raw_result (JSON)
- favorite
- note

## packages
- package_id
- version
- checksum
- payload
- installed_at

Naechste Migrationen:
- normalisierte ScanPrediction-Tabelle
- UserCorrection
- Stone-Cache
- ReferenceImage-Cache
