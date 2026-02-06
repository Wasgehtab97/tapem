# Progress Page – Roadmap (Performance‑first)

## Ziel (in eigenen Worten)
- Neue Seite **"Progress"** in der App.
- Auf der **Profil‑Page** erscheint ein neuer Button **"Progress"**, **oberhalb** von "Entdecken".
- Button‑Style: **ähnlich** zu den bestehenden Buttons "Entdecken" und "Training starten".
- Progress‑Page zeigt **Workout‑Verlauf (E1RM) Charts** wie in der History‑Page, **untereinander**.
- **Nur Übungen** mit **mindestens 3 Sessions**.
- **Nur Übungen** mit **mindestens 3 Sessions**.
- Sortierung: **absteigend** nach **Anzahl der Sessions**.
- Optional/gewünscht: **Jahres‑Filter** (Standard = aktuelles Kalenderjahr).

## Leitprinzipien (Reads minimal, UX maximal)
- **Keine Voll‑History laden** auf der Progress‑Page.
- **Aggregierte Jahres‑Summaries** statt Roh‑Logs.
- **Lazy Loading / Pagination** der Charts (zuerst Top‑N).
- **Downsampling** großer Zeitreihen (z. B. max. 200 Punkte pro Chart).
- **Caching** (lokal + Firestore) für schnelle Wiederaufrufe.

## Annahmen / Offene Punkte (zu verifizieren)
- "Workout‑Verlauf" = **E1RM‑LineChart** aus der History‑Page.
- "Übung" ist **eindeutig durch die History‑Page definiert**:
  - `isMulti = false`: Übung = **Device** (nur eine Übung)
  - `isMulti = true`: Übung = **Device + ExerciseId** (pro User anlegbar)
- Datenbasis: Logs in `gyms/{gymId}/devices/{deviceId}/logs`.

## Hauptrisiken & Gegenmaßnahmen
- **Firestore Reads zu hoch** → Aggregation + Pagination + Jahres‑Filter.
- **Index‑Requirements** → Query‑Design + Index‑Doku.
- **Doc‑Größe zu groß** (sehr viele Sessions) → Downsampling/Monats‑Aggregation.
- **State‑Collision** mit `historyProvider` → eigener Provider für Progress.
- **Data Drift** (Summaries nicht aktuell) → Cloud‑Function oder Backfill‑Job.
- **Multi‑Gym User** → Backfill filtert per Pfad, liest aber collectionGroup‑weit.

## Index‑Notiz (bereits vorhanden)
- `firestore.indexes.json`: collectionGroup `logs` mit Feldern `userId` + `timestamp` (ASC).

## Read‑Budget (Schätzung)
- **Progress‑Page Load**: 1 Index‑Read + N Summary‑Reads (paged, z. B. 6) ⇒ ~7 Reads.
- **Backfill (manuell)**: collectionGroup Logs für ein Jahr (kann viele Reads sein).
- **Empfehlung**: Backfill nur selten ausführen, idealerweise bei leerem Jahr.

## Ziel‑Architektur (Performance‑first)

### Aggregierte Datenstruktur (pro Übung & Jahr)
- Beispiel (aktuell umgesetzt):
  - `gyms/{gymId}/users/{userId}/progress/{progressKey}/years/{YYYY}`
  - `progressKey` = `deviceId` oder `deviceId::exerciseId` (isMulti)
- Felder (aktuell umgesetzt):
  - `sessionCount`: int (increment)
  - `pointsByDay`: Map `{YYYY-MM-DD: {sessionId, ts, e1rm}}` (max ~365/Jahr)
  - `deviceId`, `exerciseId`, `isMulti`, `title`, `subtitle`, `year`
  - `updatedAt`

### Index‑/Übersichts‑Dokument (Top‑Übungen pro Jahr)
- Beispiel (aktuell umgesetzt):
  - `gyms/{gymId}/users/{userId}/progressIndex/{YYYY}`
- Felder (aktuell umgesetzt):
  - `items.{progressKey}.{deviceId, exerciseId, isMulti, title, subtitle, sessionCount, lastSessionAt}`
  - `updatedAt`, `year`
- Vorteil: **1 Read** um die „Top‑Übungen“ zu laden.

### Update‑Strategie (write‑time aggregation)
- **Client‑Side Aggregation** (Cloud Functions aktuell nicht möglich im Spark‑Plan).
- Updates **beim Session‑Sync** (Hive → Firestore Sync Service schreibt Aggregates).
- Zusätzlich: **Backfill‑Flow** für Alt‑Daten (einmalig/optional).

### UI‑Strategie
- **Year Selector** (Dropdown oder Chips) – Default aktuelles Jahr.
- Erst **Top‑N Charts** laden, Rest bei Scroll nachladen.
- **Skeleton/Placeholder** statt harten Loading‑Spinnern.

## Roadmap mit Meilensteinen

### Milestone 1 – Anforderungen finalisieren
- [x] Begriff "Übung" final definiert (Device vs. Device+ExerciseId nach History‑Page)
- [x] Jahres‑Filter UI bestätigt/umgesetzt (Default aktuelles Jahr)
- [x] Chart‑Darstellung pro Übung (Titel + Untertitel + Session‑Count)

### Milestone 2 – Datenmodell & Aggregation
- [x] Aggregierte Summary‑Struktur umgesetzt (Schema ohne Versionierung)
- [x] Index‑Dokument pro Jahr umgesetzt
- [x] Downsampling‑Regel umgesetzt (1 Punkt pro Tag via `pointsByDay`)
- [x] Backfill‑Strategie geplant/umgesetzt (manueller Backfill per Progress‑Seite)

### Milestone 3 – Backend / Update‑Pipeline
- [x] Client‑seitige Update‑Logik umgesetzt (SyncService on session sync)
- [x] Regeln & Sicherheit geprüft (gyms/{gymId}/users/{userId}/... bereits owner/admin)
- [x] Composite‑Index Anforderungen dokumentiert (collectionGroup logs: userId + timestamp)
- [x] Fallback‑Strategie bei fehlenden Summaries (Backfill‑CTA im Empty State)

### Milestone 4 – State‑Management
- [x] Neuer `progressProvider` für Aggregates
- [x] Lade‑Flow: Index‑Doc → Summary‑Docs (paged)
- [x] Filter: `sessionCount >= 3`
- [x] Sortierung: absteigend nach `sessionCount`

### Milestone 5 – UI: Progress‑Page
- [x] Neue Screen + Route in `AppRouter`
- [x] Chart‑Card Komponente (Titel + E1RM Chart)
- [x] Year‑Selector + leere/Fehler‑States
- [x] Progressive Rendering (Top‑N, dann mehr)
- [x] Titel/Subtitle‑Logik verbessert (keine UID‑Anzeige; isMulti zeigt Übung + Gerät)
- [x] Jahresauswahl begrenzt (ab 2025)
- [x] Info‑Button im Header (Erklärung & Voraussetzung)
- [x] UI‑Polish (Year‑Selector Card + Sessions‑Badge)

### Milestone 6 – Profil‑Page Integration
- [x] Button "Progress" hinzugefügt (Style analog zu bestehenden Buttons)
- [x] Position direkt **über** "Entdecken"
- [x] Navigation zur Progress‑Page

### Milestone 7 – QA / Performance
- [ ] Read‑Budget überprüfen (Start‑Load < ~5 Reads ideal)
- [ ] Scroll‑Performance bei 50+ Charts testen
- [ ] Doc‑Größen & Downsampling validieren
- [ ] Offline‑Cache Verhalten prüfen

## Nächste Schritte
- Read‑Budget prüfen (Backfill ist read‑intensiv, UI‑Load bleibt gering)
- Optional: Backfill nur für leere Jahre erlauben (Schutz vor Überschreiben)
- Optional: `gymId` in Logs speichern, um Backfill‑Query effizienter zu filtern
