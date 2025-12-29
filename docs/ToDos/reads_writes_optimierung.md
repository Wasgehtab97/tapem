## Reads/Writes-Optimierung – Roadmap (Firestore/Flutter)

## Migration zuerst (immer lesen)

Dieses Dokument beinhaltet tiefgreifende Aenderungen am Datenmodell und den Write-Pfaden. Die Migration muss zuerst geplant, getestet und abgesichert werden, bevor irgendein Hotspot umgestellt wird.

### Migrationskonzept (Kurzfassung)

Ziel: Neue Datenpfade einfuehren, ohne die bestehende App zu brechen. Am Ende wird nur noch der neue Pfad genutzt, der alte bleibt read-only.

1) Vorbereitung
- [ ] Datenmodell finalisieren (Sessions + Aggregates + Index-Collections).
- [ ] Neue Security Rules schreiben (parallel zu alten Regeln).
- [ ] Indizes definieren und in Firestore anlegen.
- [ ] Monitoring aktivieren: Reads/Writes/Errors pro Tag messen.

2) Dual-Write Phase (sicherster Weg)
- [ ] Client schreibt parallel in neue Session-Docs und legacy logs.
- [ ] Cloud Functions erzeugen Aggregates aus neuem Pfad.
- [ ] In der UI ein Feature-Flag nutzen (neu lesen nur fuer Test-User).

3) Backfill (Historische Daten)
- [ ] Backfill Script: legacy logs -> sessions + stats_daily + device_daily.
- [ ] Checksummen/Counts vergleichen: Sessions pro Tag, Volumen, Reps.
- [ ] Abweichungen fixen, bevor Cutover erfolgt.

4) Cutover (Switch)
- [ ] Feature-Flag auf "neu lesen" fuer alle Nutzer.
- [ ] Legacy Logs auf read-only setzen (Rules).
- [ ] Alte Funktionen langsam entfernen (nach 2-4 Wochen Stabilitaet).

5) Rollback-Plan
- [ ] Feature-Flag zurueck auf legacy reads.
- [ ] Dual-Write kurzfristig wieder aktivieren.
- [ ] Monitoring pruefen, Fehlerursache isolieren.

### Wichtige Vorsichtspunkte (vor der Umsetzung)

- Datenverlust verhindern: immer Dual-Write + Backfill + Verifikation.
- Sicherheit: neue Regeln zusaetzlich testen (Auth/Gym-Zugehoerigkeit).
- Performance: Query-Indices vor dem Go-Live.
- Kompatibilitaet: alte App-Versionen duerfen nicht brechen.
- Funktionen zuerst in Staging testen, dann schrittweise in Prod.

### Ist das "harmlos" umzusetzen?

Nein, nicht ohne Risiko. Es ist machbar und sicher, aber nur mit sauberer Migration. Ohne Dual-Write/Backfill und Feature-Flags besteht reales Risiko, dass:
- Historische Daten nicht mehr sichtbar sind,
- XP/Leaderboards falsch laufen,
- Reports leere/inkorrekte Werte zeigen,
- oder alte Clients gar nicht mehr funktionieren.

Empfehlung: Erst ein kleines Pilot-Gym migrieren, messen, dann schrittweise alle.

Ziel: Firestore-Reads/Writes drastisch reduzieren, ohne UX/Feature-Scope zu verschlechtern. Fokus auf Kostenkontrolle, Skalierung und Stabilitaet.

Status-Legende (bitte pflegen):

- [ ] nicht gestartet  
- [~] in Arbeit  
- [x] abgeschlossen  

---

## Phase 0: Ausgangslage und Messbarkeit (MUST-HAVE)

### 0.1. Firestore-Kosten-Transparenz aktivieren

- [ ] Firebase Console: Budget-Alert fuer Reads/Writes/Storage/Functions setzen.
- [ ] Firestore Usage Export aktivieren (BigQuery optional), um Read/Write-Hotspots zu sehen.
- [ ] Client-Side Metriken:
  - [ ] Pro Screen: Read/Write Zaehler (debug) loggen.
  - [ ] Firestore Debug-Logging im Dev-Modus gezielt aktivieren.
- [ ] Erfolgskriterien definieren:
  - [ ] <= X Reads pro Session Save
  - [ ] <= Y Reads beim App-Start
  - [ ] <= Z Reads pro Report-View

---

## Phase 1: Groesste Read-Explosionen eliminieren (MUST-HAVE)

### 1.1. Gym-Code-Validierung (sehr hoher Read-Impact)

Hotspot:
- `lib/features/gym/domain/services/gym_code_service.dart`
- Aktuell: alle Gyms laden, dann je Gym Codes suchen => O(#Gyms) Reads pro Validierung.

Aufwand/Impact:
- Aufwand: M (1-2 Tage)
- Impact: sehr hoch (skaliert von O(N) auf O(1))

Plan:
- [ ] Neue Index-Collection `gym_code_index/{code}` anlegen:
  - `{ code, gymId, codeId, isActive, expiresAt }`
- [ ] Beim Erstellen/Rotieren/Deaktivieren von Codes index updaten.
- [ ] Validierung ueber `gym_code_index/{code}` + 1 read auf `gyms/{gymId}`.

Cloud Function:
- [ ] onWrite Trigger fuer `gym_codes/{gymId}/codes/{codeId}` -> Index updaten.

Security Rules:
- [ ] Lesezugriff auf `gym_code_index` nur fuer authenticated.
- [ ] Schreibzugriff nur via Admin/Function.

---

### 1.2. Reports: Logs ohne Limit (hoher Read-Impact)

Hotspot:
- `lib/features/report/data/sources/firestore_report_source.dart`
- `lib/features/report/data/repositories/report_repository_impl.dart`

Aufwand/Impact:
- Aufwand: M-L (2-4 Tage)
- Impact: sehr hoch (vermeidet Voll-Scans von Logs)

Plan:
- [ ] Aggregierte Tagesstatistiken einfuehren (siehe Datenmodell unten).
- [ ] Reports lesen nur noch Aggregates (pro Device/Tag), keine Roh-Logs.
- [ ] Fallback: falls Aggregate fehlen, zeitlich begrenzt (z.B. 30 Tage) und paginiert lesen.

---

### 1.3. TrainingDayXP Count pro Member (N+1)

Hotspot:
- `lib/features/report/data/training_day_repository.dart`
- `lib/features/report/presentation/screens/report_members_screen.dart`
- `lib/features/report/presentation/screens/report_members_usage_screen.dart`

Aufwand/Impact:
- Aufwand: S-M (1-2 Tage)
- Impact: hoch (N+1 auf O(1) je Member)

Plan:
- [ ] In `gyms/{gymId}/users/{uid}` Feld `trainingDayCount` pflegen.
- [ ] TrainingDayCount mit Cloud Function updaten, wenn `users/{uid}/trainingDayXP/{dayKey}` created.
- [ ] UI liest nur `trainingDayCount` aus Gym-User-Docs.

---

### 1.4. TrainingDayXP Voll-Scan im Profile

Hotspot:
- `lib/core/providers/profile_provider.dart`
- Aktuell: komplette Collection `trainingDayXP` laden + streamen.

Aufwand/Impact:
- Aufwand: M (2-3 Tage)
- Impact: hoch (Reads wachsen mit Historie)

Plan:
- [ ] User-Doc erweitern: `trainingDays` (z.B. last 180 days) + `trainingDayCount`.
- [ ] Optional: nur Datumsliste im Monat-Index `users/{uid}/trainingDayIndex/{YYYY-MM}`.
- [ ] Profile nutzt indexierte Monats-Docs statt Voll-Scan.

---

### 1.5. XP-Engine: Voll-Scan pro Session

Hotspot:
- `lib/features/xp/data/sources/firestore_xp_source.dart`
- Aktuell: `trainingDayXP.get()` + `xpPenalties.get()` pro Session.

Aufwand/Impact:
- Aufwand: M-L (3-5 Tage)
- Impact: sehr hoch

Plan:
- [ ] Neues XP-Stats Doc `users/{uid}/xpState`:
  - `{ lastDayKey, totalXp, dailyXp, penaltyLedger, streakState, seasonId }`
- [ ] XP Update liest nur `xpState` + `trainingDayXP/{dayKey}`.
- [ ] Penalties als kompaktes Array oder Map im `xpState` halten (begrenzen).

---

### 1.6. Leaderboard N+1 Users

Hotspot:
- `lib/features/rank/data/sources/firestore_rank_source.dart`
- Aktuell: pro Eintrag `users/{id}` nachladen.

Aufwand/Impact:
- Aufwand: S (0.5-1 Tag)
- Impact: mittel-hoch (je nach Leaderboard Groesse)

Plan:
- [ ] `leaderboard`-Docs enthalten `username`, `avatarKey`, `photoUrl`.
- [ ] Cloud Function sync bei Username/Avatar-Change.

---

## Phase 2: Write-Amplification reduzieren (MUST-HAVE)

### 2.1. Logs pro Set (Write-Explosion)

Hotspot:
- `lib/core/sync/sync_service.dart` schreibt je Set 1 Doc
- `lib/core/providers/device_provider.dart` schreibt viele Neben-Dokumente

Aufwand/Impact:
- Aufwand: L (5-10 Tage)
- Impact: sehr hoch (Writes pro Session massiv reduziert)

Plan:
- [ ] Neues Session-Datenmodell (siehe unten): 1 Session Doc mit embedded Sets.
- [ ] Optional: `session_sets` nur wenn unbedingt notwendig (Analytics/Granularitaet).
- [ ] SyncService schreibt 1 Session Doc statt N Set-Docs.
- [ ] History/Details Screens lesen Session Docs (paginiert, Zeitbereich).

---

### 2.2. Neben-Write-Ketten pro Session

Hotspot:
- `lib/core/providers/device_provider.dart`
- Community Stats, Rest Stats, Leaderboard Attempts, Notes, Snapshots

Aufwand/Impact:
- Aufwand: M (2-4 Tage)
- Impact: hoch

Plan:
- [ ] Konsolidierung: Ein `sessions/{sessionId}` doc als Single Source of Truth.
- [ ] Cloud Function pro Session erstellt:
  - [ ] Aggregates (daily stats, device usage)
  - [ ] Leaderboard updates
  - [ ] Rest stats updates
  - [ ] Community feed events
- [ ] Client schreibt nur Session Doc (+ optional UserNote).

---

### 2.3. Avatar-Grant bei XP

Hotspot:
- `functions/avatars.js` grantXpAvatars mit collectionGroup + pro Avatar write

Aufwand/Impact:
- Aufwand: M (2-3 Tage)
- Impact: mittel

Plan:
- [ ] Cache der bereits geprueften XP-Thresholds im `users/{uid}/avatarState`.
- [ ] Nur neue Thresholds berechnen, keine Voll-Scans.

---

## Phase 3: Datenmodell-Neuaufbau (Core)

### 3.1. Neues Datenmodell (proposed)

Ziel: Sessions als Primärdaten, Logs als Derived/Aggregated.

Vorschlag:

- `gyms/{gymId}/devices/{deviceId}`
  - metadata

- `gyms/{gymId}/sessions/{sessionId}`
  - `{ userId, deviceId, exerciseId, timestamp, sets: [...], note, isMulti, durationMs, stats: { volume, reps, setCount } }`

- `gyms/{gymId}/users/{uid}`
  - `{ memberNumber, trainingDayCount, lastSessionAt, ... }`

- `gyms/{gymId}/stats_daily/{dayKey}`
  - `{ date, trainingSessions, setTotal, volumeTotal, repsTotal, activeUsers }`

- `gyms/{gymId}/device_daily/{deviceId}_{dayKey}`
  - `{ deviceId, dayKey, sessions, uniqueUsers, volumeTotal }`

- `users/{uid}/xpState`
  - `{ totalXp, dailyXp, lastDayKey, penalties, streakState, seasonId }`

- `gym_code_index/{code}`
  - `{ code, gymId, codeId, isActive, expiresAt }`

Optional (nur wenn notwendig):
- `gyms/{gymId}/sessions_by_user/{uid}/{sessionId}` als read-optimized index.

---

## Phase 4: Cloud Functions (Neu/Anpassen)

### 4.1. onSessionWrite

Trigger:
- `gyms/{gymId}/sessions/{sessionId}`

Aufgaben:
- [ ] daily stats inkrementieren (stats_daily)
- [ ] device stats inkrementieren (device_daily)
- [ ] leaderboard update
- [ ] community feed event
- [ ] trainingDayXP update (per user)
- [ ] trainingDayCount update (gyms/{gymId}/users/{uid})

### 4.2. onGymCodeWrite

Trigger:
- `gym_codes/{gymId}/codes/{codeId}`

Aufgaben:
- [ ] upsert in `gym_code_index/{code}`

### 4.3. onUserProfileUpdate

Trigger:
- `users/{uid}`

Aufgaben:
- [ ] propagate username/avatar to leaderboard docs

### 4.4. onAvatarCatalogUpdate (optional)

- [ ] sync cached avatar thresholds per user

---

## Phase 5: Security Rules (Update)

### 5.1. Neue Collections

- [ ] `gym_code_index/{code}`
  - read: authenticated
  - write: admin / function

- [ ] `gyms/{gymId}/sessions/{sessionId}`
  - create: member can write own session
  - read: gym member, plus owner
  - update/delete: owner only (optional)

- [ ] `gyms/{gymId}/stats_daily/{dayKey}`
  - read: gym admin
  - write: function only

- [ ] `gyms/{gymId}/device_daily/{deviceId_dayKey}`
  - read: gym admin
  - write: function only

- [ ] `users/{uid}/xpState`
  - read: owner
  - write: function only

### 5.2. Legacy Rules anpassen

- [ ] Zugriff auf `logs` Collection ggf. read-only oder deprecated.
- [ ] Sicherstellen, dass alte Clients nicht unendlich schreiben koennen.

---

## Phase 6: Migration (Safe Rollout)

### 6.1. Dual-Write Phase

- [ ] Client schreibt neue Session Doc + legacy logs parallel (kurzzeitig).
- [ ] Cloud Function erstellt Aggregates aus beiden Quellen.

### 6.2. Backfill

- [ ] Backfill Script: legacy logs -> sessions + stats_daily.
- [ ] Verifikation: Counts und Volumen pro Tag vergleichen.

### 6.3. Switch

- [ ] UI auf Session-Collection umstellen.
- [ ] Logs nur noch read-only / deprecated.

---

## Phase 7: UX/Performance Sicherstellung

- [ ] Caching/Offline: Hive weiterhin verwenden, aber sync auf Sessions.
- [ ] Pagination fuer History/Report Screens.
- [ ] Favoriten/Progress lokal cachen, Server nur diff laden.
- [ ] Cold-start: nur minimal notwendige Reads.

---

## Aufwand/Impact Zusammenfassung (Top Hotspots)

- Gym Code Validierung: Aufwand M, Impact sehr hoch
- Reports (logs scan): Aufwand M-L, Impact sehr hoch
- TrainingDayXP Count: Aufwand S-M, Impact hoch
- Profile TrainingDayXP Scan: Aufwand M, Impact hoch
- XP Engine Full Scan: Aufwand M-L, Impact sehr hoch
- Leaderboard N+1: Aufwand S, Impact mittel-hoch
- Logs pro Set: Aufwand L, Impact sehr hoch
- Neben-Write-Ketten: Aufwand M, Impact hoch

---

## Risiken und offene Fragen

- [ ] Legacy-Clients: Wie lange muessen sie unterstuetzt werden?
- [ ] Indexing: Neue zusammengesetzte Indizes fuer Sessions (userId + timestamp etc.).
- [ ] Datengroessen: Embedded Sets pro Session (max size beachten).
- [ ] Migration: Downtime vermeiden, dual-write sauber testen.

---

## Appendix: Query-Patterns (neu)

- History by user:
  - `gyms/{gymId}/sessions` where userId == uid orderBy timestamp desc limit N
- Device usage report:
  - `gyms/{gymId}/device_daily` where dayKey in [range]
- TrainingDay stats:
  - `gyms/{gymId}/stats_daily` where dayKey in [range]

---

## Zusatzmodul: Kalorientracker (Firestore Schema + Reads/Writes + Kosten)

Ziel: Tagesbasierte Logs mit minimalen Reads/Writes, plus Jahreskalender als 1 Read.

### Datenmodell (Vorschlag)

- `users/{uid}/nutrition_goal_templates/{templateId}`
  - `{ name, kcal, macros: { protein, carbs, fat }, weekdays: [1-7], isActive }`

- `users/{uid}/nutrition_goals/{yyyyMMdd}`
  - `{ kcal, macros: { protein, carbs, fat }, source: "template|manual", updatedAt }`

- `users/{uid}/nutrition_logs/{yyyyMMdd}`
  - `{ date, total: { kcal, protein, carbs, fat }, entries: [ ... ], status: "under|on|over", updatedAt }`
  - entries (optional, begrenzen): `{ name, kcal, protein, carbs, fat, barcode, qty }`

- `users/{uid}/nutrition_year_summary/{yyyy}`
  - `{ days: { "2025-02-14": "under", "2025-02-15": "over", ... } }`

- `nutrition_products/{barcode}`
  - `{ name, kcalPer100, proteinPer100, carbsPer100, fatPer100, updatedAt }`

Optional (wenn entries groesser werden):
- `users/{uid}/nutrition_entries/{yyyyMMdd}_{entryId}`
  - Nur falls du volle Historie brauchst (sonst vermeiden).

### Beispiel Reads/Writes (Client)

1) Tagesansicht laden (nutzer wählt Datum):
- Read: `users/{uid}/nutrition_logs/{yyyyMMdd}`
- Read: `users/{uid}/nutrition_goals/{yyyyMMdd}` (oder Template/Cache)

2) Barcode-Scan (Lookup):
- Read lokal (Cache/SQLite/Hive) -> wenn hit: keine Firestore Reads
- Miss: Read `nutrition_products/{barcode}`
- Miss + manuelle Eingabe: Write `nutrition_products/{barcode}`

3) Eintrag hinzufuegen:
- Update (merge) `users/{uid}/nutrition_logs/{yyyyMMdd}`
  - `total.*` inkrementieren
  - `entries` append (optional, max begrenzen)
  - `status` neu berechnen (unter/on/ueber)
- Wenn Status aendert:
  - Update `users/{uid}/nutrition_year_summary/{yyyy}` (Map-Feld fuer den Tag)

4) Jahreskalender:
- Read: `users/{uid}/nutrition_year_summary/{yyyy}` (1 Read fuer 365 Tage)

### Queries (Beispiele)

- Tageslog:
  - `users/{uid}/nutrition_logs/{yyyyMMdd}` (doc read)
- Jahreskalender:
  - `users/{uid}/nutrition_year_summary/{yyyy}` (doc read)
- Produkt lookup:
  - `nutrition_products/{barcode}` (doc read)

### Reads/Writes Schaetzung pro 1000 aktive Nutzer (grob)

Annahme: 1000 DAU, 1x Tagesansicht, 5 Eintraege/Tag, 1 neuer Barcode/Tag/Nutzer (sonst Cache).

- Tagesansicht:
  - Reads: 2 * 1000 = 2.000 / Tag
- Eintraege (5 pro Nutzer):
  - Writes: 5 * 1000 = 5.000 / Tag (nutrition_logs updates)
- Jahresstatus-Update:
  - Writes: 1 * 1000 = 1.000 / Tag (nur wenn Status aendert)
- Barcode Lookups:
  - Reads: 1 * 1000 = 1.000 / Tag (bei Miss, sonst 0)
  - Writes: 0-1 * 1000 / Tag (nur wenn neuer Barcode manuell erfasst)

Summe grob:
- Reads: ca. 3.000 / Tag (mit Barcode Misses)
- Writes: ca. 6.000 / Tag

Monatlich (x30):
- Reads: ca. 90.000 / Monat
- Writes: ca. 180.000 / Monat

Kosten grob (Firebase Spark/Blaze variieren):
- Firestore Preise: Reads/Writes sind pro 100k/1M Abfragen. Diese Groesse ist im niedrigen Bereich.
- Der groesste Treiber sind viele Eintraege pro Tag pro Nutzer. Deshalb: Tagesdoc mit Summen bevorzugen.

### Kosten-Treiber und Optimierungen

- Viele Eintrags-Docs vermeiden (1 Tagesdoc statt viele entry docs).
- Jahreskalender nie aus Tagesdocs zusammensetzen (sonst 365 Reads).
- Barcode-Cache lokal halten; Produkte nur bei Miss readen/schreiben.
- UI Changes debouncen: keine Writes bei jeder Slider-Aenderung.
