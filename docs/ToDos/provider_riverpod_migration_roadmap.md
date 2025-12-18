## Provider → Riverpod – Migrations‑Roadmap

Diese Roadmap konkretisiert `docs/Architecture/provider_riverpod_migration.md` in umsetzbare Phasen mit klaren Tasks und Checkbox‑Status.  
Ziel: mittelfristig eine saubere, vollständig Riverpod‑basierte Codebase ohne Legacy‑Provider, ohne den Launch zu gefährden.

Status‑Legende:

- [ ] nicht gestartet  
- [~] in Arbeit  
- [x] abgeschlossen  

---

## Phase 0: Status klar ziehen & Leitplanken setzen

Ziel: Gemeinsames Verständnis der aktuellen Lage und der Spielregeln für neue Features.

### 0.1 Architektur‑Entscheidungen festhalten

- [x] Riverpod als Single Source of Truth dokumentieren (`provider_riverpod_migration.md`).
- [x] Rolle von `LegacyProviderScope` als Adapter/Bridge beschrieben.
- [x] Regel festgelegt: **keine neuen Provider‑States** – neue Features nutzen direkt Riverpod.

### 0.2 Inventar erstellen

- [x] Alle Provider‑basierten Klassen und ihre Nutzung grob erfassen:
  - Kern‑Adapter aus `legacy_provider_scope.dart`:  
    `AuthProvider`, `GymScopedStateController`, `GymContextStateAdapter`, `BrandingProvider`,  
    `GymProvider`, `AppProvider`, `SettingsProvider`, `OverlayNumericKeypadController`,  
    `SessionTimerService`, `WorkoutSessionDurationService`, `WorkoutDayController`,  
    `ProfileProvider`, `PowerliftingProvider`, `CreatineProvider`, `MuscleGroupProvider`,  
    `ExerciseProvider`, `AllExercisesProvider`, `ChallengeProvider`, `XpProvider`,  
    sowie Feature‑Services wie `AvatarInventoryProvider`, `RestStatsService`, `StorySessionService` etc.,
    die alle aus Riverpod‑Providern gespeist werden.
- [x] Screens/Widgets identifizieren, die noch direkt Provider‑Widgets nutzen:
  - `TrainingDetailsScreen` verwendet `provider.ChangeNotifierProvider` + `provider.Consumer<TrainingDetailsProvider>`.
  - `ProfileStatsScreen._showFavoriteExercisesDialog` verwendet `legacy_provider.Consumer<ProfileProvider>`.
  - Einige Admin/Editor‑Screens verwenden weiterhin Provider‑Adapter aus `LegacyProviderScope`.
- [x] Erste grobe Einschätzung pro Screen/Modul:
  - **Low Risk:** kleinere Dialoge/Detail‑Views (z.B. Favorite‑Exercises‑Dialog, Teile von TrainingDetails), Admin‑/Editor‑Screens mit geringem Nutzer‑Traffic.
  - **Medium/High Risk:** zentrale Flows wie WorkoutDay, Profil‑Overview, Gym‑Wechsel – hier erfolgt die Migration erst nach Launch schrittweise gemäß den späteren Phasen.

---

## Phase 1: Guardrails für neue Features

Ziel: Verhindern, dass während der Migration neue Provider‑Schulden entstehen.

### 1.1 Coding‑Guidelines anwenden

- [x] Kurze interne Guideline ergänzen:
  - `docs/Contributing/state_management_guidelines.md` beschreibt, dass neue State‑Logik nur über Riverpod‑Provider umgesetzt wird und Widgets bevorzugt als `ConsumerWidget`/`ConsumerStatefulWidget` aufgebaut werden.
- [x] Linter/Code‑Review‑Check festlegen:
  - In den Guidelines ist dokumentiert, dass bei neuen Änderungen keine zusätzlichen `ChangeNotifierProvider` / `provider.Consumer` / `Provider.of` im produktiven Code eingeführt werden; Code‑Reviews orientieren sich daran.

### 1.2 Neue Features ausschließlich mit Riverpod bauen

- [x] Alle neuen Module (nach heutigem Stand) als Riverpod‑First markieren:
  - Neue Community‑Features, Friends‑/Chat‑Experimente, Admin‑Tools etc. werden nur noch mit Riverpod‑Providern geplant und in der Architektur‑Doku sowie den Guidelines entsprechend vermerkt.

---

## Phase 2: Low‑Risk‑Migration – read‑only Provider

Ziel: Zuerst die einfachen, lesenden Provider/Adapter auf Riverpod umstellen, ohne Business‑Logik anzufassen.

Beispiele: Theme/Branding, Settings, einfache Config/Flags, read‑only Profile‑Daten in Screens.

### 2.1 Kandidatenliste erstellen

- [x] Alle Provider identifizieren, die nur lesen/weiterreichen:
  - u.a. `ProfileProvider` im Stats‑Screen, diverse Theme/Brand‑Adapter, einfache Settings‑Wrapper.

### 2.2 Migration pro Kandidat

Für jeden Kandidaten:

- [x] Riverpod‑Provider als Quelle der Wahrheit prüfen/erstellen (falls noch nicht vorhanden).
- [x] Ersten Screen/Widget auf Riverpod umstellen:
  - `ProfileStatsScreen` verwendet jetzt direkt `ref.read/watch(profileProvider)` statt `Provider.of`/`legacy_provider.Consumer`; der Favorite‑Exercises‑Dialog nutzt `flutter_riverpod.Consumer`.
- [x] Weitere low‑risk Screens prüfen:
  - Audit der verbleibenden `package:provider`‑Imports zeigt, dass die übrigen Verwendungen an komplexere Controller (WorkoutDay, Timer, Gym/Auth‑Kontext, Admin‑Tools etc.) gekoppelt sind und nicht als reine „read‑only“‑Adapter gelten.
  - Deren Migration wird in Phase 3 (Feature‑weise Migration der komplexen Controller) abgewickelt, um das Risiko für zentrale Flows gering zu halten.

---

## Phase 3: Komplexe Controller – Feature‑weise Migration

Ziel: Schrittweise die „großen“ Legacy‑Provider‑Verbraucher auf Riverpod‑UI umstellen.

Kandidaten (jeweils ein eigenes Mini‑Projekt):

- WorkoutDay / Geräte & Sessions  
- Coaching  
- Friends/Chat  
- Community / Avatare  
- XP / Leaderboard / Report  
- Auth/Gym‑Wechsel (UI‑Layer)

### 3.1 WorkoutDay & Training

- [x] Screens identifizieren, die noch `AuthProvider`, `GymProvider`, `WorkoutSessionDurationService` direkt nutzen.
- [x] Pro Screen (erster zentraler Flow: WorkoutDay & TrainingDetails):
  - `WorkoutDayScreen` konsumiert Auth‑, Settings‑, Keypad‑ und Workout‑State jetzt direkt über Riverpod‑Provider (`authControllerProvider`, `settingsProvider`, `overlayNumericKeypadControllerProvider`, `workoutDayControllerProvider`) statt über `provider`.
  - `TrainingDetailsScreen` nutzt den neuen Riverpod‑`trainingDetailsStateProvider` und `storySessionServiceProvider`, kein `ChangeNotifierProvider`/`Consumer` aus `provider` mehr.
- [x] Alte Provider‑Zugriffe aus diesen zentralen Screens entfernt (keine `context.read/watch` oder `provider.Consumer` mehr in `WorkoutDayScreen` und `TrainingDetailsScreen`).

#### 3.1.1 Timer & Keypad

- [x] `ActiveWorkoutTimer` auf Riverpod umstellen:
  - Nutzt jetzt ausschließlich `workoutSessionDurationServiceProvider`, `workoutDayControllerProvider` und `authControllerProvider`; keine `Selector`/`Provider.of`/`context.read` mehr.
- [x] Timer‑Leisten (`session_timer_bar.dart`) migrieren:
  - `SessionTimerBar` ist `ConsumerStatefulWidget` und bezieht `SessionTimerService` über `sessionTimerServiceProvider` statt über `provider`.
- [x] Numeric‑Keypad‑Widgets (`overlay_numeric_keypad.dart`) auf Riverpod umstellen:
  - Kein `package:provider`‑Import mehr; der Zugriff auf `WorkoutDayController` erfolgt über `ProviderScope.containerOf(...).read(workoutDayControllerProvider)` statt über `legacy_provider.Provider.of`.

#### 3.1.2 NFC‑Flows

- [x] `NfcScanButton`:
  - Nutzt jetzt `authControllerProvider`, `getDeviceByNfcCodeProvider`, `membershipServiceProvider`, `workoutSessionDurationServiceProvider` und `workoutDayControllerProvider` direkt über Riverpod; kein `context.read`/`package:provider` mehr.
- [x] `GlobalNfcListener`:
  - Ist `ConsumerStatefulWidget` und bezieht `ReadNfcCode`, `GetDeviceByNfcCode`, `AuthProvider`, `WorkoutDayController` und `WorkoutSessionDurationService` über Riverpod (`readNfcCodeProvider`, `getDeviceByNfcCodeProvider`, `authControllerProvider`, `workoutDayControllerProvider`, `workoutSessionDurationServiceProvider`), Navigation weiterhin über `navigatorKey`.

### 3.2 Coaching

- [x] Coaching‑Screens auf Riverpod‑Provider (`coaching_providers.dart`) umstellen:
  - Coaching‑Home, Client‑Detail und Invite‑Screens verwenden ausschließlich Riverpod‑Provider (`coachRelationsProvider`, `clientCoachingAnalyticsProvider`, `coachInvite`‑Provider etc.); es gibt keine `package:provider`‑Abhängigkeiten im Coaching‑Feature.
- [x] Direkte Provider‑Zugriffe in globalen Coaching/Story‑Flows durch Riverpod ersetzt:
  - `StorySessionHighlightsListener` nutzt `workoutSessionDurationServiceProvider`, `authViewStateProvider` und `storySessionServiceProvider` anstelle von `context.read<AuthProvider>()` und `provider`‑Lookups.

### 3.3 Friends/Chat

- [x] Friends‑/Chat‑Widgets auf Riverpod‑Provider migrieren:
  - `FriendListTile` verwendet nun `authViewStateProvider` statt `Provider<AuthProvider>`; in den Friends‑Features gibt es keine `package:provider`‑Verwendung mehr.
- [x] Adapter‑Status festhalten:
  - Die verbleibenden Friends/Chat‑Adapter in `LegacyProviderScope` sind als **Phase‑4‑Cleanup** markiert (siehe Abschnitt 4) und werden dort gemeinsam mit den übrigen Legacy‑Providern entfernt.

### 3.4 Community & XP/Leaderboard

- [x] Community‑Views (Feed, Stats, Badges) auf Riverpod‑State umstellen.
  - Challenge‑Tab + Widgets (`ChallengeTab`, `ActiveChallengesWidget`, `CompletedChallengesWidget`) beziehen ihren State jetzt über `challengeProvider` und `authViewStateProvider`/`gymProvider` aus Riverpod; alle `package:provider`‑Imports wurden entfernt.
- [x] XP‑ und Leaderboard‑Screens auf die bestehenden Riverpod‑Provider/Repos aufsetzen:
  - `DeviceXpScreen`, `DayXpScreen`, `DeviceXpLeaderboardScreen`, `LeaderboardScreen` verwenden jetzt `authViewStateProvider`/`authControllerProvider`, `gymProvider` und `xpProvider` direkt über Riverpod; alle `package:provider`‑Imports wurden aus diesen Screens entfernt.

### 3.5 Auth & Gym im UI‑Layer

- [x] Screens, die `AuthProvider`/`GymProvider` nur als UI‑Quelle nutzen, direkt an `authViewStateProvider` und Gym‑Riverpod‑Provider hängen:
  - [x] Settings‑Screen: verwendet jetzt `ConsumerStatefulWidget` und bezieht Auth‑, App‑, Settings‑ und Theme‑State über `authControllerProvider`, `appProvider`, `settingsProvider` und `themePreferenceProvider`; alle `package:provider`‑Zugriffe wurden entfernt.
  - [x] Auth‑Forms/Dialogs (Login/Registration/Username/Password‑Reset) auf Riverpod umgestellt (`AuthScreen`, `LoginForm`, `RegistrationForm`, `showPasswordResetDialog`, `showUsernameDialog` nutzen `authControllerProvider` bzw. `ProviderScope.containerOf(...).read`).
  - [x] Gym‑Select/Gym‑Screen (inkl. `GymContextGuard` und Home‑Tabs) auf Riverpod‑State aufgesetzt:
    - `GymContextGuard` ist jetzt `ConsumerStatefulWidget` und nutzt `gymContextStateAdapterProvider`.
    - `SelectGymScreen` bezieht Auth‑State über `authControllerProvider` und ruft `switchGym` via Riverpod auf.
    - `HomeScreen` ist `ConsumerStatefulWidget` und verwendet `authControllerProvider`, `gymProvider`, `workoutSessionDurationServiceProvider` und `workoutDayControllerProvider` statt `provider`.
    - `GymScreen` liest Auth‑/Gym‑/Muskel‑State über `authControllerProvider`, `gymProvider`, `muscleGroupProvider` sowie Timer/Workout‑Controller über Riverpod‑Provider.
  - [x] Admin‑Screens und verbleibende Profil‑/Device‑Widgets von `provider` auf Riverpod migrieren:
    - [x] Profil‑Cluster (`ProfileScreen`, `PowerliftingScreen`, Username‑Dialog, Creatine‑Screen) konsumiert Auth/XP/Settings/Workout‑State jetzt über Riverpod‑Provider (`authControllerProvider`, `profileProvider`, `xpProvider`, `settingsProvider`, `workoutDayControllerProvider`, `creatineProvider`); alle direkten `provider`‑Imports wurden dort entfernt.
    - [x] Geräte‑/Muskel‑Admin‑Screens (z.B. Muscle‑Group‑Admin, Device‑Leaderboards inkl. Machine‑Leaderboard‑Sheet, Admin‑Devices) und generische UI‑Bausteine (Search & Filter‑Widgets, Muscle‑Selector) sind auf Riverpod umgestellt und enthalten keine `package:provider`‑Imports mehr; verbleibende Core‑Adapter werden in Phase 4 bereinigt.

---

## Phase 4: LegacyProviderScope abbauen

Ziel: Sobald ein Modul komplett über Riverpod läuft, die entsprechenden Adapter loswerden.

### 4.1 Unbenutzte Adapter aufräumen

- [x] In `legacy_provider_scope.dart` alle Provider‑Adapter markieren, deren Ziel‑Widgets bereits migriert sind.
- [x] Adapter entfernen, wenn:
  - keine produktiven Screens mehr darauf zugreifen,
  - Tests entsprechend angepasst sind (LegacyProviderScope ist nur noch ein dünner Wrapper ohne eigene Provider‑Hierarchie).

### 4.2 Provider‑basierte Klassen entfernen oder einfrieren

- [x] Ehemalige `ChangeNotifier`/Provider‑Klassen entweder:
  - als Riverpod‑erste ChangeNotifier eingefroren (`DeviceProvider`, `MuscleGroupProvider`, `ProfileProvider` werden nur noch über Riverpod‑Provider erzeugt und greifen intern nicht mehr auf `package:provider` zu),
  - komplette Entfernung der Klassen ist ein **expliziter Post‑Launch‑Refactor** und kein Blocker für Launch‑Readiness.

---

## Phase 5: Cleanup, Tests & Dokumentation

Ziel: Sicherstellen, dass die Migration stabil ist und die Architektur verstanden bleibt.

### 5.1 Tests & CI

- [x] Relevante Unit-/Widget‑Tests für migrierte Module aktualisieren/ergänzen.
  - Zentrale Riverpod‑basierte Provider (u.a. `gymProvider`, `brandingProvider`, `historyProvider`, `restStatsProvider`, Community‑ und Friends‑Provider) sind über dedizierte Unit‑Tests abgesichert.
  - Integrationsnahe Widget‑Tests wie `tapem_app_bootstrap_test.dart`, `workout_day_screen_test.dart`, `set_card_test.dart`, `note_button_widget_test.dart` und `machine_leaderboard_sheet_test.dart` wurden auf die neue Riverpod‑Architektur angepasst und stellen sicher, dass die migrierten Flows (Workout‑Day, Timer, Gym‑Kontext, Training‑Details) ohne `package:provider` laufen.
- [x] Prüfen, ob es sinnvolle `ProviderContainer`‑basierte Tests für zentrale Riverpod‑Provider gibt.
  - Für neue und migrierte Provider existieren Container‑basierte Tests (z.B. Community‑Stats, Rest‑Stats, Report‑ und Friends‑Provider), die ihre Streams/UseCases gegen Fakes verifizieren.
  - Bootstrap‑Tests (`TapemApp + LegacyProviderScope`) nutzen `ProviderContainer` mit Overrides, um Auth/Gym/Branding‑Flows zu simulieren und Theme‑Updates sowie Gym‑Wechsel zu prüfen.

### 5.2 Dokumentation aktualisieren

- [x] `provider_riverpod_migration.md` nach Abschluss der großen Schritte aktualisieren:
  - Dokumentiert, dass `package:provider` im Produktions‑Code nicht mehr verwendet wird und `LegacyProviderScope` nur noch ein dünner Wrapper ohne eigene Provider‑Hierarchie ist.
  - Der Status‑Quo‑Abschnitt wurde auf den Stand „nach Migration 2025“ gehoben und die Abschlusskriterien (Riverpod als einziges State‑Management) festgehalten.
- [x] Hinweise in `technisch_launchready.md` und dieser Roadmap anpassen:
  - Diese Roadmap spiegelt den abgeschlossenen Zustand der Phasen 0–4 wider; Phase 5 ist mit Tests & Dokumentations‑Update ebenfalls als abgeschlossen markiert.
  - `technisch_launchready.md` verweist weiterhin auf diese Architektur‑Doku und betrachtet die Provider→Riverpod‑Migration als adressierte technische Schuld (Kategorie D).

---

Diese Roadmap ist bewusst **nicht** zeitlich getaktet, sondern nach Risiko/Komplexität sortiert.  
Wichtig für dich:  
- Der Launch ist nicht von der vollständigen Migration abhängig.  
- Wir verhindern neue Schulden (Phase 1) und bauen bestehende Schulden kontrolliert ab (Phasen 2–4), ohne zentrale Flows zu gefährden.  
- Du kannst die Phasen nacheinander abhaken und siehst jederzeit, wo ihr im Migrationsprozess steht.
