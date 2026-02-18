# Offline Workout Flow Roadmap (Launch-kritisch)

Stand: 2026-02-14
Scope: App-Start, Trainingsstart, WorkoutDay UX/Performance, „Vorher“-Werte, Session-Speicherung, Trainingstage-Kalender, spätere Cloud-Synchronisierung.

## Zielbild (fachlich)

Ein User soll ein komplettes Training ohne Internet (kein WLAN, kein Mobilfunk) robust durchführen können:
- App startet ohne Blocker.
- Geräte + Übungen sind sofort lokal verfügbar.
- WorkoutDay ist flüssig und vollständig nutzbar.
- „Vorher“-Feld zeigt letzte Leistung lokal an.
- Training wird lokal zuverlässig gespeichert (inkl. Trainingstag im Kalender).
- Bei Netzrückkehr werden Daten deterministisch synchronisiert.

## Ist-Zustand (Code-Analyse)

### Bereits gut / teilweise erfüllt
- [x] Session-Logs werden lokal-first in Hive gespeichert und in die Sync-Queue gelegt (`lib/features/training_details/data/repositories/session_repository_impl.dart`).
- [x] „Vorher“-Werte werden aus lokaler Session-Historie geladen (`lib/features/training_details/data/repositories/session_repository_impl.dart`, `getLastSession`).
- [x] Draft-/Zwischenstand einer laufenden Einheit wird lokal persistiert (`SharedPreferences`) und kann wiederhergestellt werden (`lib/core/drafts/session_draft_repository_impl.dart`).
- [x] Sync-Service mit Retry + Dead-Letter existiert (`lib/core/sync/sync_service.dart`).

### Kritische Lücken (verursachen aktuelles Offline-Problem)
- [ ] Splash blockiert bei Auth-Fehlern statt auf einen offline-fähigen Startpfad zu wechseln (`lib/features/splash/application/splash_flow.dart`, `lib/features/splash/presentation/screens/splash_screen.dart`).
- [ ] Geräte/Übungen sind nicht als eigene lokale Source-of-Truth modelliert; aktuell Firestore-first mit Cache-Hoffnung (`lib/features/device/data/sources/firestore_device_source.dart`, `lib/features/device/data/sources/firestore_exercise_source.dart`).
- [ ] Trainingstage-Kalender basiert auf `users/{uid}/trainingDayXP` (remote), nicht auf lokalen Sessions (`lib/core/providers/profile_provider.dart`).
- [ ] XP/Challenges/Community/Meta sind überwiegend Cloud-abhängig; Offline-Verhalten ist uneinheitlich und teils fire-and-forget (`lib/core/providers/device_provider.dart`, `lib/features/xp/data/sources/firestore_xp_source.dart`).
- [ ] Lokale Session-Queries sind O(n)-Scans über Hive-Werte; das skaliert bei größerer History schlechter (`lib/features/training_details/data/repositories/session_repository_impl.dart`).
- [ ] Kleiner Cache-Bug: `ProfileCacheStore` nutzt aktuell den literal Key `'profileCache/$userId'` nicht korrekt als user-spezifischen Interpolationskey (`lib/core/storage/profile_cache_store.dart`).

## Architektur-Ziel (Best Practice, wartbar)

- [ ] Offline-first für alle workout-kritischen Daten: lokale DB ist führend.
- [ ] Klare Read-Strategie: UI liest primär lokal, Remote nur zur Anreicherung/Sync.
- [ ] Klare Write-Strategie: lokaler Commit atomar, Remote asynchron via Job-Queue.
- [ ] Explizite Sync-Grenzen: „kritisch für Training“ vs. „optional/Cloud-only“.
- [ ] Idempotente Sync-Protokolle (jobId/sessionId + version/timestamps).
- [ ] Offline-UX explizit: Statusbanner, nicht-blockierende Hinweise, keine Start-Blockade.

## Priorisierte Roadmap

## P0 (Blocker für „Training komplett offline möglich“)

### 1) Offline-Safe App-Start und Auth-Gating
- [x] Splash darf bei Netzwerkfehlern nicht hängen bleiben; Offline-Entry in die App erlauben, wenn lokale Session/Profilbasis vorhanden.
- [x] `resolveSplashDestination`/Auth-Fehlerbehandlung so umbauen, dass „kein Netz“ != Hard-Blocker ist.
- [x] Fallback-Policy definieren: Was darf ohne erfolgreiche Remote-Auth geladen werden (lokaler Workout-Modus)?

Abnahme:
- [x] Flugmodus + App-Kaltstart führt nicht zum Error-Screen, sondern in einen nutzbaren Offline-Modus.

### 2) Lokalen Geräte-/Übungs-Katalog einführen
- [x] Eigene lokale Persistenz (SharedPreferences-Cache) für Devices + Exercises als Read-Source im Workout.
- [x] Bei Online-Phase: Cache wird bei erfolgreichen Remote-Reads aktualisiert.
- [x] Bei Offline-Phase: Workout-Screens nutzen Firestore-Cache + lokalen Persistenz-Fallback.

Abnahme:
- [x] Flugmodus + App-Neustart: Geräte und Übungen laden ohne Hard-Blocker (lokale Fallbacks aktiv).

### 3) Lokaler Trainingstag-Index (Kalender) als Source-of-Truth
- [x] Beim lokalen Session-Save wird `trainingDaysLocal/{user}` sofort aktualisiert.
- [x] Profil-Kalender liest local-first; Remote-`trainingDayXP` wird gemerged.
- [x] Konfliktregel umgesetzt: Union aus lokal + remote (dedupliziert nach Tag).

Abnahme:
- [x] Offline gespeichertes Training erscheint sofort im Trainingstage-Kalender.

### 4) Save-Transaktion für Workout-kritische Daten atomar machen
- [x] Einheitliche lokale Save-Reihenfolge: Session + TrainingDay-Index + Sync-Intent.
- [x] Wenn Cloud-Writes fehlschlagen: lokale Konsistenz bleibt vollständig erhalten.

Abnahme:
- [x] Nach Force-Close direkt nach Save bleiben lokale Session + Kalenderstatus konsistent.

## P1 (Qualität, Performance, Robustheit)

### 5) WorkoutDay Performance-Paket
- [x] Projections/Materialized Views für „last session per (device, exercise)“ statt Vollscans.
- [x] Indizes oder key-basierte Lookups für Tagesabfragen/„Vorher“.
- [x] Warmup beim App-Start: häufige Geräte/Übungen + letzte Sessiondaten vorladen.

Abnahme:
- [x] Spürbar konstante Ladezeit und flüssige Interaktion bei großer Historie.

### 6) Einheitliche Offline-Sync-Jobs für Nebenpfade
- [x] Auch derzeit fire-and-forget Pfade (XP, Challenges, Community, SessionSnapshot/Meta) in eine konsistente Queue-Strategie überführen.
- [x] Job-Typen trennen: kritisch vs optional, mit klarer Retry/Dead-Letter Policy.

Abnahme:
- [x] Keine stillen Datenverluste bei längerem Offline-Betrieb; klare Reconciliation bei Netzrückkehr.

### 7) Offline UX
- [x] Globaler Connectivity-Status im UI (nicht-blockierend).
- [x] Klare Labels: „Lokal gespeichert“, „Wird synchronisiert“, „Sync fehlgeschlagen – bleibt lokal erhalten“.
- [x] Retry/Diagnose in einem Dev-/Support-Panel (Queue, Dead-Letter, letzte Fehlercodes).

Abnahme:
- [x] User versteht jederzeit den Zustand, ohne dass Trainingsfluss unterbrochen wird.

## P2 (Hardening, Wartbarkeit, Migration)

### 8) Data-Model-Konsolidierung
- [x] Für workout-kritische Daten ein einheitliches Domain-Repository mit Local/Remote-Adaptern etablieren.
- [x] Alte direkte Firestore-Reads in UI-nahen Providern schrittweise abbauen.

### 9) Migration + Backfill
- [x] Einmalige Migration: vorhandene lokale/remote Sessions in neuen lokalen Index überführen.
- [x] Backfill-Jobs für fehlende Kalender-/Projection-Daten bereitstellen.

### 10) Observability
- [x] Metriken: Offline-Starts, lokale Save-Erfolge, Queue-Latenz, Dead-Letter-Rate, Reconcile-Dauer.
- [x] Alerting für Sync-Stau und ungewöhnliche Dead-Letter-Spitzen.

## Testmatrix (verbindlich)

### Manuelle E2E-Cases
- [ ] Flugmodus vor App-Start: Start bis WorkoutDay ohne Fehler.
- [ ] Offline Training starten, Sätze erfassen, speichern, App killen, neu öffnen: Daten vollständig da.
- [ ] Offline-Training erscheint sofort im Kalender.
- [ ] Nach Netzrückkehr: Sync läuft durch, keine Duplikate/Verluste.

### Automatisierte Tests
- [x] Unit: Offline-first Repositories (Read local, Write local+enqueue).
- [x] Unit: TrainingDay-LocalIndex und Reconcile-Logik.
- [x] Integration: Splash/Auth Offline-Gating.
- [x] Integration: WorkoutDay mit lokalem Device/Exercise-Katalog.
- [x] Integration: Save -> Queue -> Replay -> Remote idempotent.

## Konkrete erste Umsetzungsschritte (empfohlen)

1. [x] P0.1 umsetzen: Splash/Auth Offline-Gating (kein Hard-Block bei Netzfehler).
2. [x] P0.2 starten: lokales Device/Exercise-Caching als eigene Datenquelle.
3. [x] P0.3 umsetzen: lokaler Trainingstag-Index + Kalender auf local-first umstellen.
4. [x] P0.4 nachziehen: atomare lokale Save-Transaktion + klare Queue-Grenzen.

## DoD „Offline workout-ready"
- [ ] App ist ohne Internet startbar und nutzbar.
- [ ] Workout kann komplett offline durchgeführt und gespeichert werden.
- [ ] Geräte/Übungen/„Vorher“-Werte sind offline sofort verfügbar.
- [ ] Trainingstage-Kalender markiert offline gespeicherte Einheiten sofort.
- [ ] Re-Sync nach Netzrückkehr ist idempotent, nachvollziehbar und stabil.
