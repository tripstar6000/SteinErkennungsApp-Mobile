# Security

- Keine API-Schluessel im Mobile-Client.
- Ausschliesslich HTTPS fuer Backend.
- Standort wird vor Uebertragung reduziert.
- TFLite-Modellpakete werden nur nach SHA-256-Pruefung installiert.
- Keine Auth-Tokens, GPS-Rohdaten oder Fotos in Logs.
- SQL-Eingaben laufen ueber parametrisierte `sqflite`-APIs.
- Externe Bildreferenzen bleiben Quellen-/Lizenzdaten zugeordnet.
