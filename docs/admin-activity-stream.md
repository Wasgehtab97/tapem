# Admin Activity Stream

Dieses Dokument beschreibt das einheitliche Ereignismodell für den Admin-Monitoring-Bereich.

## Datenmodell

* Sammlung: `gyms/{gymId}/activity/{eventId}` (Collection Group `activity`)
* Pflichtfelder:
  * `gymId` (string)
  * `timestamp` (Firestore Timestamp)
  * `eventType` (string, z. B. `training.set_logged`)
  * `severity` (`info` | `warning` | `error`)
  * `source` (`device` | `app` | `backend` | `admin` | `system`)
* Optionale Felder:
  * `summary` (string)
  * `userId`, `deviceId`, `sessionId`
  * `actor` ({ `type`: `user` | `system` | `admin`, `id`?, `label`? })
  * `targets` (Array von Referenzen)
  * `data` (schlanker Payload ohne PII)
  * `updatedAt` (Timestamp)
  * `idempotencyKey` (string)

## Schreibpfade

* Gerätesätze (`gyms/{gymId}/devices/{deviceId}/logs/{logId}`) werden via Cloud Function `mirrorDeviceLogToActivity` gespiegelt.
* Trusted Backends schreiben direkt in `activity`. Clientseitige Schreibrechte sind in den Firestore-Regeln deaktiviert.

## Abfragen & Indizes

* Standard-Query: `collectionGroup('activity')` + Filter `gymId == :gymId`, optional Zeitraum (`timestamp`), Typen (`eventType`), Severity, `userId`, `deviceId`.
* Sortierung: `orderBy('timestamp', 'desc').orderBy(FieldPath.documentId(), 'desc')`.
* Paginierung: Cursor (Base64) über `timestamp` + Dokumentpfad.
* Firestore-Indizes:
  * `(gymId asc, timestamp desc)`
  * `(gymId asc, eventType asc, timestamp desc)`
  * `(gymId asc, severity asc, timestamp desc)`

## Admin API

* Endpoint: `GET /api/admin/gyms/:gymId/events`
* Query-Parameter: `from`, `to`, `types`, `severity`, `userId`, `deviceId`, `limit`, `cursor`
* Antwort: `items[]`, `nextCursor`, `stats { total, last24h, last7d, last30d }`, `warnings[]`, `requestId`
* Auth: nur Admin/Owner Sessions.
* Response-Caching: `Cache-Control: private, max-age=30`, ETag Support.

## UI

* Client-Komponente `GymActivityFeed` mit Filterformular, KPI-Badges, Tabelle (`AdminEventLogTable`) und Cursor-Ladefunktion.
* Debounced Fetch via `AbortController`, Zusammenführung von Warnungen (z. B. fehlende Indizes).
* Keine PII-Anzeige, IDs werden roh dargestellt (Monospace Chips).

## Migration / Backfill

1. Cloud Function deployen (`mirrorDeviceLogToActivity`).
2. Historische Logs iterativ lesen und mit `idempotencyKey` in `activity` schreiben.
3. Fehlende Firestore-Indizes erstellen (siehe oben).
4. Monitoring-UI nutzt nur noch den neuen Endpoint.

## Tests

* `functions/__tests__/activity.test.js` prüft Mapping `Log -> Activity`.
* API-Route wird über Next.js Routen-Handler getestet (manuell über `npm run dev` bzw. Integrationstest).
