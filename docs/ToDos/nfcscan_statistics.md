# NFC-Scan Statistik – Roadmap (Entdecken → Statistiken)

Status-Legende:
- [ ] nicht gestartet
- [~] in Arbeit
- [x] abgeschlossen

---

## Zielbild (kurz)
- [ ] Auf der Profil/Entdecken-Statistikseite erscheint eine neue Karte **„NFC scans“** mit der Anzahl erfolgreicher NFC-Scans, die eine Übung auf den Workout-Day-Screen gebracht haben.
- [ ] Zählung ist offline-fest, dedupliziert (kein Doppel-Count beim bloßen Fokussieren einer bestehenden Session) und gym-/user-spezifisch speicherbar.
- [ ] Datenerfassung nutzt bestehende Architektur (Riverpod + Firestore + Firebase Analytics) und folgt denselben Caching/Rule-Standards wie Trainings- und Rest-Stats.

---

## Ist-Stand (relevant)
- [ ] NFC-Flow: `NfcScanButton` (z.B. in `core/widgets/base_screen.dart`) startet Session, löst über `getDeviceByNfcCode` den Device-Fetch aus und führt bei Single-Device direkt `workoutDayController.addOrFocusSession` aus; bei Multi-Device geht es erst in `ExerciseListScreen` und dann wieder `addOrFocusSession`.
- [ ] Es gibt **keine** Telemetrie oder persistente Zählung für Workout-relevante NFC-Scans. Firebase Analytics hat nur `gym_nfc_scan` für Onboarding/Join.
- [ ] Stats-UI: `ProfileStatsScreen` zeigt Trainings-Tage/Ø-Woche (Quelle `ProfileProvider` → `users/{uid}/trainingDayXP`) sowie Rest-Zeiten (Quelle `RestStatsProvider` → `gyms/{gymId}/users/{uid}/rest_stats`). Keine NFC-bezogene Kennzahl.
- [ ] Firestore-Rules enthalten noch keinen Pfad für NFC-Scan-Statistiken; kein Cache/Provider dafür.

---

## Soll-Definition (was zählen wir?)
- [ ] **Event:** „Erfolgreicher NFC-Scan, der zu einer neuen Session im Workout Day führt.“ (nicht: Fehl-Scan, Membership-Error, bloßes Re-Fokussieren einer bestehenden Session).
- [ ] **Scope:** User-basiert, optional gym-spezifisch (mehrere Gyms pro User). MVP: total per User+Gym; optional: per Tag (`YYYY-MM-DD`) + letztes Gerät.
- [ ] **Signal-Quelle:** Nur dann inkrementieren, wenn `addOrFocusSession` **einen neuen Kontext** anlegt (d.h. vorher kein Entry für `contextKey(gym,device,exercise,user)` existierte) und der Aufruf aus einem NFC-Flow stammt.
- [ ] **Anzeige:** Ganzzahl (z.B. „24“), optional Untertitel „gesamt“ / später sparkline, falls wir Tages-Buckets pflegen.

---

## Roadmap / ToDo-Listen

### 1) Datenmodell & Security
- [ ] Firestore-Pfad entscheiden: `gyms/{gymId}/users/{uid}/nfc_scan_stats/summary` (MVP) + optional `daily/{dayKey}` Subcollection für Trend.
- [ ] Felder definieren: `totalScans` (int), `lastScanAt` (timestamp), `lastDeviceId`, `lastExerciseId`, `lastGymId` (redundant), `daily.{dayKey}` (map<int>) falls ohne Subcollection.
- [ ] Regeln ergänzen: Nur authentifizierter `request.auth.uid == uid`, Schreiblimit auf Inkremente (`allow update: if request.resource.data.keys().hasOnly([...]) && <range-checks>`), ggf. Write-Rate begrenzen (Firestore `request.time` diff).
- [ ] Index-Bedarf prüfen (voraussichtlich keiner, da einfache `get()`).

### 2) Schreibpfad (Instrumentation)
- [ ] Neuen Service `NfcScanStatsWriter` (ähnlich `RestStatsService`) bauen: Methode `recordScan({gymId,userId,deviceId,exerciseId,dayKey,scanId})` mit `FieldValue.increment(1)`, `lastScanAt`, optional `scanId` für Idempotenz.
- [ ] `WorkoutDayController.addOrFocusSession` um optionalen Parameter `source` erweitern (enum/string), Rückgabe um Flag `wasCreated` oder `createdNew` ergänzen.
- [ ] In `NfcScanButton` Single-Device-Flow: nach erfolgreichem `addOrFocusSession(..., source: SessionSource.nfc)` und `wasCreated == true` → `NfcScanStatsWriter.recordScan(...)`; Analytics-Event `workout_nfc_scan {gym_id,user_id,device_id,exercise_id,status:success}` loggen.
- [ ] Multi-Device-Flow: `ExerciseListScreen` erhält (optional) `origin: SessionSource` und gibt ihn beim `onSelect`/`addOrFocusSession` weiter, damit nur echte „neue“ Sessions gezählt werden; Abbruch/Cancellation darf nichts loggen.
- [ ] Fehlerpfad/Abbrüche: bei `deviceNotFound`, `nfcNoGymSelected`, `membership.ensureMembership`-Failure → optional Analytics `status:failed` ohne Counter.

### 3) Lese-/Cache-Pfad
- [ ] `NfcScanStatsService.fetchStats(gymId,userId)` implementieren (einfache `get()` auf summary-Doc; fallback 0).
- [ ] Riverpod-Provider `nfcScanStatsProvider(gymId,userId)` mit `AsyncValue<NfcScanStats>`; optional lokaler Cache (Hive oder in-memory per `profile_cache_store`-Schema) mit TTL analog `ProfileProvider` (24h).
- [ ] Fehler-Handling/Fallback in UI: bei Load-Error „—“ anzeigen + Retry.

### 4) UI-Integration (Entdecken → Statistiken)
- [ ] L10n hinzufügen (`nfcScanStatLabel`, `nfcScanStatDescription` de/en); Einträge in `app_en.arb` / `app_de.arb` + regen.
- [ ] `ProfileStatsScreen`: neue `_StatCard` einfügen (z.B. Farbe teal), Position unter Rest-Timer oder neben Lieblingsübung; Wert = `stats.totalScans.toString()`; optional Subtitle „gesamt“.
- [ ] Loading/Empty-State: bei `null` → `—`; bei `0` klar „0“ anzeigen.
- [ ] Accessibility: Icon (NFC) + Semantics-Label.

### 5) Tests & QA
- [ ] Unit-Test `NfcScanStatsWriter` mit Firebase Emulator: Inkrement, idempotente `scanId`, daily-Bucket.
- [ ] Widget-Test: `ProfileStatsScreen` rendert NFC-Karte mit Wert aus Provider (Mock).
- [ ] Integration-Test (Emulator): NFC-Scan-Flow simulieren → `addOrFocusSession` → Stats-Dokument erhöht.
- [ ] Manual QA Checkliste: Single/Multi-Device, Abbruch vor Auswahl, Offline-Scan (Cache → Sync), erneuter Scan derselben Übung am selben Tag (erwartetes Verhalten klären).

### 6) Rollout & Backfill
- [ ] Feature-Flag? (z.B. `FF.nfcScanStats`) um UI schrittweise zu aktivieren.
- [ ] Backfill-Option prüfen: Falls `devices/{id}/logs` bisher `source` enthalten (derzeit nicht) → kein automatischer Backfill möglich; sonst 0 starten.
- [ ] Monitoring: Dashboard/Analytics-Event `workout_nfc_scan` beobachten; Crash/ANR Watch.

---

## Offene Fragen / Entscheidungen
- Zählt jeder NFC-Scan oder nur „neue“ Sessions? (empfohlen: nur neue, sonst Fokus-Scans blähen den Wert)
- Soll die Zahl global (user-weit) oder pro Gym angezeigt werden? (MVP pro aktuelles Gym, Default 0 ohne Gym)
- Brauchen wir Tagestrend für spätere Charts? Wenn ja → Daily-Bucket jetzt mitschreiben.
- Erwartetes Verhalten bei Multi-Gym-Usern ohne aktives Gym im Kontext des Buttons (derzeit Snackbar) – soll dann trotzdem global zählen?

---

## Risiken / TODOs für später
- Doppelzählung bei gleichzeitigen Geräten (zwei schnelle Scans bevor Provider-Map aktualisiert wird) → ggf. `scanId` oder debounce im Writer.
- Offline-Konflikte: Firestore-Increment + `scanId`-Check vermeiden race; Emulator-Test mit `setNetworkEnabled(false/true)` einplanen.
- Kosten: Ein Increment pro „echtem“ Scan ist günstig; Daily-Buckets erhöhen Write-Anzahl minimal.
