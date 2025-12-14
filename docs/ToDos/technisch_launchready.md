## Technische Launch-Readiness – Roadmap

Diese Roadmap konsolidiert alle noch offenen technischen Punkte, damit tapem stabil, sicher und „launch-ready“ in App Store / Play Store gehen kann.  
Sie basiert auf `thesis/market_readiness/technisch.md` und ergänzt weitere Aspekte (Tests, Tooling, Rollout).

Ziele:

- Auth, Gym-Wechsel und State-Management sind stabil und vorhersagbar.
- Offline-Verhalten, Sync und Firestore-Regeln sind klar definiert und sicher.
- Firebase-Setup, Crashlytics und Analytics sind produktionsreif.
- Es gibt eine transparente Test- und Release-Pipeline für neue Builds.

Status-Legende (bitte pflegen):

- [ ] nicht gestartet  
- [~] in Arbeit  
- [x] abgeschlossen  

---

## Phase 1: Auth & Gym-Wechsel stabilisieren (MUST-HAVE)

Ziel: Login, Logout, Registrierungen und Gym-Wechsel funktionieren zuverlässig, ohne „halb-validen“ Zustand oder Datenleaks.

### 1. Auth-Flow & Session-Handling

- [ ] Auth-Flow inventarisieren:
  - Welche Screens/Routen verwenden welchen Auth-Provider (FirebaseAuth, `AuthProvider`, `authViewStateProvider`)?
  - Wo wird `userId`, `gymCode`, `role`, `claims` gelesen/gesetzt?
- [ ] „Single Source of Truth“ definieren:
  - Auth-Zustand zentral über Riverpod (`authViewStateProvider`) führen.
  - Provider-Bridge (`AuthProvider`) nur als UI-Adapter nutzen (kein eigener „Wahrheitszustand“).
- [ ] Login/Logout Verhalten vereinheitlichen:
  - Nach `logout()`:
    - Alle gym-scoped Provider/Gym-States über `GymScopedResettable` zurücksetzen (WorkoutDay, Xp, Chat, Coaching, etc.).
    - Workout-Timer (`WorkoutSessionDurationService`) stoppen und persistierte Session-Meta schließen.
  - Nach erfolgreichem Login:
    - Gym-Daten nur einmal via `GymContextGuard`/`GymProvider` laden.
    - Klares Routing:
      - Kein „Doppelsprung“ mehr zwischen Splash → Auth → Home.
- [ ] Claims & Rollen synchronisieren:
  - Sicherstellen, dass:
    - Admin/Coach/Mitglied-Rolle aus Custom Claims in `authViewState` gespiegelt wird.
    - Tab-Bar / Admin-Funktionen *ausschließlich* auf `authViewState.role` basieren, nicht auf Firestore-Feldern.
  - JWT-Refresh nach Claim-Änderungen sicherstellen (z.B. via `reload()`).

### 2. Gym-Wechsel & Membership

- [ ] Gym-Wechsel-Flows kartieren:
  - Alle Stellen, an denen `gymCode` geändert wird (`SelectGymScreen`, QR/Code-Scan, Admin-Switch).
  - Auswirkungen auf:
    - `GymProvider` (Devices, Branding, Muscles),
    - WorkoutDayController (Sessions),
    - XpProvider / Leaderboard,
    - Coaching-Kontext (Relationen).
- [ ] `ensureMembership` standardisieren:
  - Konsequent nur noch über einen Service/UseCase (aktuell `MembershipService.ensureMembership`).
  - Logging behalten, aber Debouncing/Retry einführen, um Doppel-Requests zu vermeiden.
- [ ] State-Reset bei Gym-Wechsel:
  - Für alle `GymScopedResettable`-Implementierungen prüfen:
    - Wird bei Gym-Wechsel wirklich alles zurückgesetzt (WorkoutDay, Statistik-Provider, Caches)?
  - Sicherstellen, dass UI keine alten Geräte/Pläne aus vorherigem Gym zeigt.

---

## Phase 2: State-Management & Bootstrapping aufräumen (MUST-HAVE)

Ziel: Konsistente Nutzung von Provider vs. Riverpod, klarer App-Bootstrap und weniger Race Conditions.

### 3. Provider/Riverpod-Strategie konkretisieren

- [ ] Entscheidung dokumentieren:
  - Kurzfristig: Riverpod = Logik/State, Provider = UI-Adapter (Legacy).
  - Langfristig (Kategorie D): komplette Migration auf Riverpod.
- [ ] `legacy_provider_scope.dart` prüfen:
  - Welche Riverpod-Provider werden als Provider-Adapter exponiert (WorkoutDayController, OverlayNumericKeypad, etc.)?
  - Sicherstellen, dass dort:
    - Keine zusätzlichen Logiken implementiert werden (nur „through“).
    - Keine doppelte Instanziierung (pro App nur ein Riverpod-Container).
- [ ] Bootstrapping in `main.dart`/`tapem_app.dart`:
  - `ProviderScope`, `OverlayNumericKeypadHost`, `LegacyProviderScope` sauber schachteln.
  - App-Bootstrapping in klare Schichten trennen:
    - Firebase-Init (Options, AppCheck),
    - Env-Konfiguration (DEV/PROD),
    - Riverpod-Provider,
    - UI (MaterialApp, Routing).

### 4. Race Conditions & Start-Up Bugs eliminieren

- [ ] Typische Problemstellen analysieren:
  - Timer & WorkoutDayController beim App-Start.
  - Chat/Unread + Auth/Encryption-Key-Setup.
  - Coaching-Provider, die direkt auf Firestore zugreifen, bevor `gymCode` valid ist.
- [ ] Startup-Guards:
  - `GymContextGuard` für alle gym-abhängigen Screens konsequent einsetzen (Report, Rank, Pläne, Admin etc.).
  - Fallbacks bei fehlendem Gym (z.B. „Gym auswählen“-Screen statt Crash).

---

## Phase 3: Offline-Verhalten & Sync (MUST-HAVE)

Ziel: Klar definiertes Offline-Verhalten – insbesondere für Workouts –, sodass Nutzer nie das Gefühl haben, Daten zu verlieren.

### 5. Offline-Konzept definieren

- [ ] Klar definieren:
  - Welche Features *offline* funktionieren müssen (Workouts, Pläne, Historie, Chat-Teile?).
  - Welche Features online-only sein dürfen (Leaderboards in Echtzeit, Community-Feed, Coaching-Einladungen).
- [ ] Workload identifizieren:
  - Aktuelle Draft-Lösungen (Hive, `SessionDraftRepository`) durchgehen:
    - Welche Fälle sind nicht abgedeckt (z.B. mehrere Sessions am selben Tag, Sync-Konflikte)?
  - Datenfluss-Dokumentation:
    - WorkoutDay → Session-Drafts → Firestore `sessions`/`session_meta` → Analytics.

### 6. Sync-Mechanismus für Workouts härten

- [ ] Drafts & Sync-Jobs:
  - `SessionDraftRepository` + `SyncService` prüfen:
    - Werden alle Completed-Sets/Stati persistiert, bevor Firestore-Write versucht wird?
    - Wie werden fehlerhafte Jobs behandelt (Retry-Strategie, Backoff)?
  - Offline-Speicher (Hive) auf Integrität und Migration testen.
- [ ] Konfliktstrategie dokumentieren:
  - Was passiert bei doppelten Sessions für den gleichen Tag?
  - Wie wird mit mehreren Geräten (z.B. Phone + Tablet) für denselben User umgegangen?
- [ ] UX bei Sync-Problemen:
  - Klare Statusanzeige:
    - „x Trainings warten auf Synchronisation“ (z.B. auf Profilseite oder in Settings).
  - Retry-Button / Auto-Retry bei wiederhergestellter Verbindung.

---

## Phase 4: Firebase-Setup & Security (MUST-HAVE)

Ziel: Firebase (Auth, Firestore, Functions, FCM, App Check) ist produktionsreif, sicher und konsistent zwischen DEV/PROD.

### 7. Firebase-Umgebungen & Secrets

- [ ] Firebase-Projekte sauber trennen:
  - DEV vs. PROD (aktuell `tap-em-dev` vs. Prod-Projekt).
  - `firebase.dev.json` / `firebase.json` / `GoogleService-Info.plist` & `google-services.json` prüfen.
- [ ] Secret-Handling:
  - Alle Secrets (API Keys für externe Services, Functions-Konfiguration) aus dem Quellcode herausziehen (nur in Umgebungs-Configs/Secret-Manager).
  - Dokumentieren, wie ein neues DEV-Environment aufgesetzt wird.

### 8. Push Messaging & App Check

- [ ] Push (FCM):
  - `initializePushMessaging` & `_registerToken` stabil machen:
    - Fehler `[firebase_functions/not-found]` beseitigen (DEV-Funktion deployen oder Guard einbauen).
    - Token-Registrierung (pro Gym/User) definieren.
  - Notification-Flows testen:
    - Coaching-Einladungen, Chat, App-Announcements.
- [ ] App Check:
  - App Check in DEV/PROD aktivieren.
  - Sicherstellen, dass Web/Android/iOS jeweils gültige Provider haben.
  - Firestore/Functions nur für verifizierte Clients akzeptieren (wo sinnvoll).

### 9. Firestore-Regeln & Functions-Security-Review

- [ ] Regeln für alle Collections durchgehen:
  - `gyms/*/users/*/sessions`, `session_meta`, `training_plans`, `training_schedule`,
    `coaching_relations`, `friends`, `chats`, `community`, `nfc_devices`, etc.
  - Checkliste:
    - Multi-Tenant-Isolation (User sieht nur Daten seines Gyms).
    - Coach/Admin-Rechte korrekt (Clients vs. Coaches).
    - Kein XP-Cheating über manuelle Writes.
- [ ] Functions-Hardening:
  - Alle Cloud Functions (z.B. XP-Recalculation, Leaderboard, Invite-Codes) auf Input-Validation prüfen.
  - Logging & Error-Handling verbessern.

---

## Phase 5: Fehler-Monitoring, Analytics & Telemetrie (MUST-HAVE)

Ziel: Nach Launch gibt es keine „blinde“ Phase – wir sehen Crashes, Performance-Probleme und Kern-KPIs.

### 10. Crashlytics & Performance

- [ ] Crashlytics konfigurieren:
  - Für iOS & Android: dSYM-Prozess/ProGuard-Mapping testen, dass Stacktraces lesbar sind.
  - Globaler Error-Handler (Flutter + Zone + PlatformErrors) setzt Crashlytics-Logs, aber zeigt dem User dennoch sinnvolle Fehler-Screens.
- [ ] Performance-Monitoring:
  - Wichtige Flows markieren:
    - App-Startup,
    - Login/Gym-Wechsel,
    - Workout speichern,
    - Coaching-Seiten laden.

### 11. Produkt-KPIs & Analytics-Events

- [ ] Events definieren:
  - Session-basierte Events:
    - `workout_started`, `workout_completed`, `workout_discarded`.
  - Feature-Usage:
    - `nfc_scan_success`, `nfc_scan_fail`, `plan_started`, `plan_completed`.
  - Engagement:
    - `coaching_request_sent`, `coaching_request_accepted`, `coach_plan_assigned`.
- [ ] Consent/Privacy:
  - Sicherstellen, dass Tracking DSGVO-konform ist (Opt-In/Opt-Out, Privacy-Text).

---

## Phase 6: UX-Polish, Ladezustände & Branding (Nice-to-have für Launch)

Ziel: Die App fühlt sich durchgehend hochwertig, „fertig“ und konsistent gebrandet an.

### 12. Einheitliche Lade- und Fehlerzustände

- [ ] Reusable Widgets:
  - `AppLoadingIndicator` (z.B. für ganze Screens),
  - `AppErrorCard` / `RetrySection`.
- [ ] Skeleton-States:
  - Für zentrale Listen:
    - Pläne, Coaching-Clients, Leaderboard, Report-Karten.

### 13. Branding-Checks

- [ ] Jede Gym-Brand mit Key-Screens durchgehen:
  - Profil, WorkoutDay, Gym-Liste, Report, Coaching.
  - Sicherstellen, dass:
    - Outline/Accent-Farben konsistent genutzt werden,
    - Icons & Gradients nicht gegen Gym-Farben „beißen“.

---

## Phase 7: Tests, QA & Release-Pipeline

Ziel: Stabiler Weg von „Feature fertig“ zu „Build im Store“, inklusive manueller QA-Checkliste.

### 14. Automatisierte Tests & Checks

- [ ] Unit-/Widget-Tests für Kernlogik:
  - WorkoutTimer (`WorkoutSessionDurationService`),
  - WorkoutDayController (Sessions, Plan-Kontext),
  - TrainingScheduleRepository,
  - Firestore-Repositories (mithilfe Emulator).
- [ ] Static Analysis:
  - `dart analyze` & `flutter test` in CI einbinden.
  - Evtl. zusätzlich `flutter format`/`lint` vor PRs.

### 15. Manuelle QA-Checkliste für jeden Release

- [ ] Geräte/OS-Matrix definieren:
  - Mindestens:
    - iOS: aktuelles + Vorgängerversion,
    - Android: 2–3 große Versionen (API-Level).
- [ ] Szenarien:
  - Neuer User (kein Gym) → Onboarding → Gym beitreten → erstes Workout.
  - Gym-Wechsel mit bestehenden Sessions.
  - Coaching: Request senden, annehmen, Plan erstellen, Plan absolvieren.
  - Offline-Workout: Flugmodus, Workout starten, speichern, später Sync.

### 16. Release-Pipeline

- [ ] CI/CD einrichten (GitHub Actions oder ähnliches):
  - DEV-Builds (Internal Test / TestFlight).
  - Signierte Release-Builds:
    - iOS: Fastlane/CLI-Skripte für Upload zu TestFlight/App Store Connect.
    - Android: Signierte APK/AAB mit Upload zu Google Play Console.

---

## Phase 8: Technische Schulden & Risiko-Reduktion (Kategorie D)

Ziel: Mittel-/langfristige Schulden so adressieren, dass die Codebase wartbar bleibt.

### 17. Provider vs. Riverpod-Migration planen

- [ ] Roadmap erstellen:
  - Schrittweise Migration von Legacy-Providern auf Riverpod:
    - Zuerst reine Read-Only Provider (z.B. Settings),
    - dann komplexe Controller (WorkoutDay, Coaching, Chat).
- [ ] „Brücken“-Layer dokumentieren:
  - Wie lange `LegacyProviderScope` bestehen bleibt und wie neue Module *nur* Riverpod verwenden.

### 18. Firestore-Abfragen zentralisieren

- [ ] Repositories als einziger Zugriffspunkt:
  - Neue Features greifen *nicht* mehr direkt über `FirebaseFirestore.instance.collection` in Screens zu.
  - Alte Stellen schrittweise auf Repos migrieren:
    - Workout-Sessions, Training-Pläne, Coaching-Relationen, Community-Feed.
- [ ] Vorteile nutzen:
  - Bessere Testbarkeit,
  - klare Trennung von Domain-Logik und Persistence,
  - einfachere Offline-Strategien.

### 19. Test-Mocks für NFC & Geräte

- [ ] Abstraktionslayer für Hardware:
  - Interface für Nfc-Reader (`ReadNfcCode`), Device-Repository etc. bereits vorhanden → gezielt mit Fake-Implementierungen in Tests nutzen.
  - Möglichkeit, im DEV-Build „Fake-Geräte“ zu simulieren (z.B. ohne echtes NFC).
- [ ] QA-Tools:
  - Kleines In-App-Debug-Menü (nur in DEV), um:
    - NFC-Events zu simulieren,
    - Workouts zu erzeugen,
    - Coaching-Situationen nachzustellen.

---

> Hinweis: Diese Roadmap ist bewusst technisch fokussiert.  
> Feature-spezifische Roadmaps (z.B. `coaching_roadmap.md`, `training_planen.md`) laufen parallel und sollten mit dieser technischen Roadmap abgestimmt werden, damit keine Konflikte (z.B. bei Offline-Änderungen oder Security-Regeln) entstehen.

