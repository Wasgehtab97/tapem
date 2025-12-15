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

- [x] Auth-Flow inventarisieren:
  - Welche Screens/Routen verwenden welchen Auth-Provider (FirebaseAuth, `AuthProvider`, `authViewStateProvider`)?
  - Wo wird `userId`, `gymCode`, `role`, `claims` gelesen/gesetzt?
- [x] „Single Source of Truth“ definieren:
  - Auth-Zustand zentral über Riverpod (`authViewStateProvider`) führen.
  - Provider-Bridge (`AuthProvider`) nur als UI-Adapter nutzen (kein eigener „Wahrheitszustand“).
- [x] Login/Logout Verhalten vereinheitlichen:
  - Nach `logout()`:
    - Alle gym-scoped Provider/Gym-States über `GymScopedResettable` zurücksetzen (WorkoutDay, Xp, Chat, Coaching, etc.).
    - Workout-Timer (`WorkoutSessionDurationService`) stoppen und persistierte Session-Meta schließen.
  - Nach erfolgreichem Login:
    - Gym-Daten nur einmal via `GymContextGuard`/`GymProvider` laden.
    - Klares Routing:
      - Kein „Doppelsprung“ mehr zwischen Splash → Auth → Home.
- [x] Claims & Rollen synchronisieren:
  - Sicherstellen, dass:
    - Admin/Coach/Mitglied-Rolle aus Custom Claims in `authViewState` gespiegelt wird.
    - Tab-Bar / Admin-Funktionen *ausschließlich* auf `authViewState.role` basieren, nicht auf Firestore-Feldern.
  - JWT-Refresh nach Claim-Änderungen sicherstellen (z.B. via `reload()`).

### 2. Gym-Wechsel & Membership

- [x] Gym-Wechsel-Flows kartieren:
  - Alle Stellen, an denen `gymCode` geändert wird (`SelectGymScreen`, QR/Code-Scan, Admin-Switch).
  - Auswirkungen auf:
    - `GymProvider` (Devices, Branding, Muscles),
    - WorkoutDayController (Sessions),
    - XpProvider / Leaderboard,
    - Coaching-Kontext (Relationen).
- [x] `ensureMembership` standardisieren:
  - Konsequent nur noch über einen Service/UseCase (aktuell `MembershipService.ensureMembership`).
  - Logging behalten, aber Debouncing/Retry einführen, um Doppel-Requests zu vermeiden.
- [x] State-Reset bei Gym-Wechsel:
  - Für alle `GymScopedResettable`-Implementierungen prüfen:
    - Wird bei Gym-Wechsel wirklich alles zurückgesetzt (WorkoutDay, Statistik-Provider, Caches)?
  - Sicherstellen, dass UI keine alten Geräte/Pläne aus vorherigem Gym zeigt.

---

## Phase 2: State-Management & Bootstrapping aufräumen (MUST-HAVE)

Ziel: Konsistente Nutzung von Provider vs. Riverpod, klarer App-Bootstrap und weniger Race Conditions.

### 3. Provider/Riverpod-Strategie konkretisieren

- [x] Entscheidung dokumentieren:
  - Kurzfristig: Riverpod = Logik/State, Provider = UI-Adapter (Legacy).
  - Langfristig (Kategorie D): komplette Migration auf Riverpod.
- [x] `legacy_provider_scope.dart` prüfen:
  - Welche Riverpod-Provider werden als Provider-Adapter exponiert (WorkoutDayController, OverlayNumericKeypad, etc.)?
  - Sicherstellen, dass dort:
    - Keine zusätzlichen Logiken implementiert werden (nur „through“).
    - Keine doppelte Instanziierung (pro App nur ein Riverpod-Container).
- [x] Bootstrapping in `main.dart`/`tapem_app.dart`:
  - `ProviderScope`, `OverlayNumericKeypadHost`, `LegacyProviderScope` sauber schachteln.
  - App-Bootstrapping in klare Schichten trennen:
    - Firebase-Init (Options, AppCheck),
    - Env-Konfiguration (DEV/PROD),
    - Riverpod-Provider,
    - UI (MaterialApp, Routing).

### 4. Race Conditions & Start-Up Bugs eliminieren

- [x] Typische Problemstellen analysieren:
  - Timer & WorkoutDayController beim App-Start.
  - Chat/Unread + Auth/Encryption-Key-Setup.
  - Coaching-Provider, die direkt auf Firestore zugreifen, bevor `gymCode` valid ist.
- [x] Startup-Guards:
  - `GymContextGuard` für alle gym-abhängigen Screens konsequent einsetzen (Report, Rank, Pläne, Admin etc.).
  - Fallbacks bei fehlendem Gym (z.B. „Gym auswählen“-Screen statt Crash).

---

## Phase 3: Offline-Verhalten & Sync (MUST-HAVE)

Ziel: Klar definiertes Offline-Verhalten – insbesondere für Workouts –, sodass Nutzer nie das Gefühl haben, Daten zu verlieren.

### 5. Offline-Konzept definieren

- [x] Klar definieren:
  - Welche Features *offline* funktionieren müssen (Workouts, Pläne, Historie, Chat-Teile?).
  - Welche Features online-only sein dürfen (Leaderboards in Echtzeit, Community-Feed, Coaching-Einladungen).
- [x] Workload identifizieren:
  - Aktuelle Draft-Lösungen (Hive, `SessionDraftRepository`) durchgehen:
    - Welche Fälle sind nicht abgedeckt (z.B. mehrere Sessions am selben Tag, Sync-Konflikte)?
  - Datenfluss-Dokumentation:
    - WorkoutDay → Session-Drafts → Firestore `sessions`/`session_meta` → Analytics.

### 6. Sync-Mechanismus für Workouts härten

- [x] Drafts & Sync-Jobs:
  - `SessionDraftRepository` + `SyncService` prüfen:
    - Werden alle Completed-Sets/Stati persistiert, bevor Firestore-Write versucht wird?
    - Wie werden fehlerhafte Jobs behandelt (Retry-Strategie, Backoff)?
  - Offline-Speicher (Hive) auf Integrität und Migration testen.
- [x] Konfliktstrategie dokumentieren:
  - Was passiert bei doppelten Sessions für den gleichen Tag?
  - Wie wird mit mehreren Geräten (z.B. Phone + Tablet) für denselben User umgegangen?
- [x] UX bei Sync-Problemen:
  - Klare Statusanzeige:
    - „x Trainings warten auf Synchronisation“ (z.B. auf Profilseite oder in Settings).
  - Retry-Button / Auto-Retry bei wiederhergestellter Verbindung.

---

## Phase 4: Firebase-Setup & Security (MUST-HAVE)

Ziel: Firebase (Auth, Firestore, Functions, FCM, App Check) ist produktionsreif, sicher und konsistent zwischen DEV/PROD.

### 7. Firebase-Umgebungen & Secrets

- [x] Firebase-Projekte sauber trennen:
  - DEV vs. PROD (`tap-em-dev` vs. `tap-em` in `firebase.json` / `firebase.dev.json` + `firebase_options_dev.dart` / `firebase_options_prod.dart`).
  - Plattform-spezifische Configs (`GoogleService-Info.plist`, `google-services.json`) sind getrennt eingebunden.
- [x] Secret-Handling:
  - Alle relevanten Secrets (API Keys für externe Services, Functions-Konfiguration) liegen in Env-/Config-Dateien, nicht im App-Code.
  - Vorgehen für ein neues DEV-Environment ist in den Firebase-Configs abbildbar; Detail-Docs können bei Bedarf nachgezogen werden.

### 8. Push Messaging & App Check

- [x] Push (FCM) – Client & Basis:
  - `initializePushMessaging` & `_registerToken` sind implementiert (`firebase.dart`), Fehler `[firebase_functions/not-found]` wird sauber geloggt und blockiert den App-Start nicht.
  - Token-Registrierung auf Serverseite ist vorbereitet (`functions/push.js: registerPushToken`), Deployment erfordert jedoch Blaze-Plan (Cloud Build / Artifact Registry).
  - Globale/gezielte Pushes können bis zum Blaze-Upgrade über Firebase Console oder externe Tools erfolgen.
- [ ] Push (FCM) – Event-basiert (Blaze erforderlich):
  - Event-Pushes für Freundschaftsanfragen, Chat-Nachrichten, Coaching und „x Tage ohne Training“ sind in `functions/push.js` vorbereitet (Triggers + Helper).
  - Deployment und Aktivierung dieser Functions ist explizit auf „nach Blaze-Upgrade / Markt-Launch“ verschoben.
- [x] App Check:
  - App Check ist im Bootstrap verankert (`initializeAppCheck` in `firebase.dart`) und nutzt Debug-Provider in DEV sowie reale Provider in PROD.
  - Aktivierung/Feinjustierung erfolgt in der Firebase Console für Web/Android/iOS, ist aber unabhängig vom Spark/Blaze-Plan möglich.

### 9. Firestore-Regeln & Functions-Security-Review

- [x] Regeln für alle Collections durchgehen:
  - `gyms/*/users/*/sessions`, `session_meta`, `training_plans`, `training_schedule`,
    `coaching_relations`, `friends`, `chats`, `community`, `nfc_devices`, etc.
  - Checkliste:
    - Multi-Tenant-Isolation (User sieht nur Daten seines Gyms).
    - Coach/Admin-Rechte korrekt (Clients vs. Coaches).
    - Kein XP-Cheating über manuelle Writes.
- [x] Functions-Hardening:
  - Bestehende Cloud Functions (XP, Avatare, Activity, Powerlifting, GymCodes) arbeiten mit validierten Pfaden/IDs und sind defensiv geloggt.
  - Neue Push-Functions (`functions/push.js`) sind so entworfen, dass sie nur auf bestehende, bereits abgesicherte Collections zugreifen; ihr Deployment erfolgt erst nach Blaze-Upgrade.

---

## Phase 5: Fehler-Monitoring, Analytics & Telemetrie (MUST-HAVE)

Ziel: Nach Launch gibt es keine „blinde“ Phase – wir sehen Crashes, Performance-Probleme und Kern-KPIs.

### 10. Crashlytics & Performance

- [x] Crashlytics konfigurieren:
  - Für iOS & Android ist Crashlytics eingebunden (`firebase_crashlytics` in `pubspec.yaml`), globaler Error-Handler ist in `main.dart` konfiguriert (FlutterError + runZonedGuarded).
  - Stacktraces sind über Firebase Crashlytics in den Projekten `tap-em-dev` und `tap-em` einsehbar; dSYM/Mapping-Konfiguration kann bei Bedarf noch verfeinert werden.
- [x] Performance-Monitoring (Basis):
  - Zentrale Flows (Workout-Start, Workout-Abschluss, verworfene Workouts) sind über Firebase Analytics-Events (`workout_started`, `workout_completed`, `workout_discarded`) messbar.
  - Weitere Detail-Performance (z.B. via Firebase Performance Monitoring) kann optional nachgerüstet werden.

### 11. Produkt-KPIs & Analytics-Events

- [x] Events definieren:
  - Session-basierte Kern-Events (`workout_started`, `workout_completed`, `workout_discarded`) sind in `AnalyticsService` implementiert und an Workout-Start/Ende/Discard angebunden.
  - Weitere Feature-Usage-/Engagement-Events (NFC, Pläne, Coaching) können nach Launch iterativ ergänzt werden.
- [ ] Consent/Privacy:
  - Sicherstellen, dass Tracking DSGVO-konform ist (Opt-In/Opt-Out, Privacy-Text) – TODO: rechtliche Texte & In-App-Opt-In finalisieren.

---

## Phase 6: UX-Polish, Ladezustände & Branding (Nice-to-have für Launch)

Ziel: Die App fühlt sich durchgehend hochwertig, „fertig“ und konsistent gebrandet an.

### 12. Einheitliche Lade- und Fehlerzustände

- [x] Reusable Widgets:
  - `AppLoadingIndicator` (z.B. für ganze Screens) und `AppErrorCard` mit optionalem Retry-Callback sind vorhanden und werden u.a. in der Plan-Übersicht genutzt.
- [x] Skeleton-States:
  - Mindestens für Community-Feed und weitere zentrale Listen vorhanden; weitere Skeletons können bei Bedarf nachgerüstet werden, sind aber kein Blocker für Launch.

### 13. Branding-Checks

- [x] Jede Gym-Brand mit Key-Screens durchgehen:
  - Profil, WorkoutDay, Gym-Liste, Report, Coaching wurden visuell mit den hinterlegten `AppBrandTheme`-Presets geprüft.
  - Outline/Accent-Farben werden konsistent über `AppBrandTheme.outline` und zugehörige Brand-Widgets (z.B. `BrandGradientText`, `BrandInteractiveCard`) genutzt; Icons & Gradients harmonieren mit den Gym-Farben.

---

## Phase 7: Tests, QA & Release-Pipeline

Ziel: Stabiler Weg von „Feature fertig“ zu „Build im Store“, inklusive manueller QA-Checkliste.

### 14. Automatisierte Tests & Checks

- [x] Unit-/Widget-Tests für Kernlogik:
  - Es existieren umfangreiche Tests für zentrale Komponenten (`WorkoutSessionDurationService`, Auth, Device-/Exercise-Repositories, XP-Logik, Community, GymProvider etc.) im `test/`-Ordner.
  - Weitere Detailtests (z.B. für zukünftige Repos) können iterativ ergänzt werden, sind aber kein Blocker für den Launch.
- [x] Static Analysis:
  - `dart format`, `flutter analyze` und `flutter test` sind in der CI-Pipeline (`.github/workflows/ci.yml`) integriert und laufen automatisch auf PRs/Branches.

### 15. Manuelle QA-Checkliste für jeden Release

- [x] Geräte/OS-Matrix definieren:
  - Mindestens:
    - iOS: aktuelles + Vorgängerversion,
    - Android: 2–3 große Versionen (API-Level).
- [x] Szenarien (als verbindliche QA-Checkliste definiert):
  - Neuer User (kein Gym) → Onboarding → Gym beitreten → erstes Workout.
  - Gym-Wechsel mit bestehenden Sessions.
  - Coaching: Request senden, annehmen, Plan erstellen, Plan absolvieren.
  - Offline-Workout: Flugmodus, Workout starten, speichern, später Sync.

### 16. Release-Pipeline

- [x] CI/CD einrichten (GitHub Actions):
  - CI-Workflow (`.github/workflows/ci.yml`) läuft Tests, Linting, Rules-Tests und baut Debug-APKs.
  - iOS-TestFlight-Upload ist über einen separaten Workflow vorbereitet (`.github/workflows/ios_testflight.yml`) und kann nach Konfiguration der Secrets genutzt werden.

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
