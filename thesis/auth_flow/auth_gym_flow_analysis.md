# Auth & Gym Flow Analyse

## 1. Überblick
- **Scope:** Dokumentiert alle Abläufe rund um Anmeldung, Gym-Zuordnung und Kontextwechsel innerhalb der Flutter-App. Grundlage bilden `AuthProvider`, `AuthResult`, `switchGym` sowie der `GymScopedStateController` aus `lib/core/providers/auth_provider.dart` und `lib/core/providers/gym_scoped_resettable.dart`.
- **Ziel:** Einheitliches Referenzdokument für Produkt, Backend und Mobile zur Planung künftiger Änderungen an Authentifizierung, Mitgliedschaftsprüfung (`MembershipService`) und gym-spezifischen Zuständen.
- **Explizite Annahmen:**
  1. Firebase Authentication bleibt das führende Identitätssystem (UID = eindeutiger Nutzerbezug in Firestore).
  2. Die Gym-Liste eines Users (`UserData.gymCodes`) ist autoritativ und enthält nur Gyms, denen der Nutzer bereits beitreten darf.
  3. Persistenter Gym-Kontext (SharedPreferences-Key `selectedGymCode`) wird ausschließlich von `AuthProvider` gesetzt.

## 2. IST-Flow App-Start
### 2.1 `main.dart` Bootstrapping
1. `lib/main.dart` initialisiert Firebase, Messaging und App-weite Services bevor `runApp` ausgeführt wird.
2. SharedPreferences werden vor dem `runApp`-Call geladen (`final sharedPrefs = await SharedPreferences.getInstance();`).
3. `runApp` registriert alle Provider via `MultiProvider`; die ersten Einträge setzen Infrastruktur (`NfcService`, Device-/Exercise-Repositories), anschließend folgen Applikationszustände.

### 2.2 `SplashScreen`
1. `SplashScreen` (`lib/features/splash/presentation/screens/splash_screen.dart`) wird als Initialroute geladen.
2. `initState` ruft `_navigateNext`, wartet mindestens 800 ms und pollt `AuthProvider.isLoading`, bis `_loadCurrentUser()` abgeschlossen ist.
3. Routing-Entscheidung:
   - Logged-in & mehrere Gyms → `AppRouter.selectGym`.
   - Logged-in & genau ein Gym → `AppRouter.home` (argument 1).
   - Nicht eingeloggt → `AppRouter.auth`.

### 2.3 Provider-Lade-Reihenfolge
1. Zentrale Reihenfolge in `main.dart`:
   - `GymScopedStateController` wird vor `AuthProvider` erstellt.
   - `AuthProvider` erhält den Controller via `context.read<GymScopedStateController>()` und startet sofort `_loadCurrentUser()` im Konstruktor.
   - Nach Auth folgen abhängige ProxyProvider (z. B. `BrandingProvider`, `GymProvider`, `ThemePreferenceProvider`, `ThemeLoader`), die in `update` auf `auth.gymCode` und `auth.userId` zugreifen und sich beim `GymScopedStateController` registrieren.
2. Konsequenz: Bereits während des Splash-Screens sind Provider-Instanzen vorhanden und reagieren auf Auth-Änderungen.

### 2.4 Laden von `activeGymId` & Claims
1. `_loadCurrentUser()` (`lib/core/providers/auth_provider.dart`) ruft `FirebaseAuthManager.currentUser` und anschließend `getIdTokenClaims`, um Rollen-Claims einzulesen.
2. `GetCurrentUserUseCase` liefert `UserData`; Claims überschreiben das lokale `role`-Feld.
3. `SharedPreferences`-Key `selectedGymCode` wird geprüft:
   - Wenn vorhanden und in `gymCodes`, setzt `_selectedGymCode` → aktives Gym ist damit synchron zur Persistenz (`activeGymId`).
   - Fallback: erstes Element aus `gymCodes`, inklusive Persistierung.
4. Diese Auswahl bestimmt, welchen Gym-Kontext abhängige Provider in ihren `update`-Hooks laden.

## 3. IST-Flow Login (`AuthProvider.login`)
1. UI triggert `login(email, password)`; `AuthProvider` setzt `_isLoading=true`.
2. `LoginUseCase` meldet bei Firebase Auth an und ruft `_loadCurrentUser()`.
3. `_loadCurrentUser()` lädt Claims (für Rolle), anschließend `GetCurrentUserUseCase` für `UserData`.
4. Gym-Auswahl:
   - Wenn `selectedGymCode` in SharedPreferences gespeichert und in `gymCodes` enthalten → Wiederherstellung.
   - Andernfalls erster Code aus `gymCodes`.
5. `AuthResult.success` wird mit Flags gesetzt: `requiresGymSelection` wenn mehr als ein Gym oder kein gespeicherter Code, `missingMembership` wenn `gymCodes` leer.
6. Fehler (z. B. FirebaseAuthException) resultieren in `AuthResult.failure` mit `_error`.

**Annahmen:** Nutzer besitzt mindestens eine Rolle oder Claim, der dem UI signalisieren kann, ob zusätzliche Berechtigungen bestehen (impliziert durch `role`-Feld).

## 4. IST-Flow Registrierung (`AuthProvider.register`)
1. `RegisterUseCase` erstellt Konto (inkl. initialem Gym-Code) und ruft `_loadCurrentUser()`.
2. Falls Backend noch kein `UserData` liefert, nutzt der Provider das vom UseCase zurückgegebene Objekt.
3. Persistenter Gym-Code wird auf das erste Element von `registeredUser.gymCodes` gesetzt.
4. Rückgabe erfolgt wieder über `_resolveAuthResult()`.

**Annahmen:** `RegisterUseCase` stellt sicher, dass der initiale Gym-Code gültig ist und `gymCodes` mindestens einen Eintrag besitzt.

## 5. IST-Flow Gym-Wechsel (`AuthProvider.switchGym`)
1. Preconditions: `_user` muss gesetzt sein, `gymId` muss in `user.gymCodes` enthalten sein; sonst Fehler `invalid_gym_code`.
2. Firebase User (`_authManager.currentUser`) muss existieren, andernfalls `StateError`.
3. Bei identischem Gym-Code erfolgt ein früher Exit (kein Netzwerkcall).
4. Ablauf:
   - `_membershipService.ensureMembership(gymId, uid)` prüft/erstellt Mitgliedschaft (Firestore Transaction).
   - `GymScopedStateController.resetGymScopedState()` benachrichtigt registrierte Resettable-Instanzen (z. B. `GymProvider`, Branding-Provider).
   - `_setActiveGym(gymId)` aktualisiert Benutzerprofil (Persistenz via `UserProfileService.setActiveGym`).
   - `FirebaseAuthManager.forceRefreshIdToken` stellt sicher, dass Claims für gym-spezifische Regeln aktualisiert sind.
   - SharedPreferences werden aktualisiert, `_selectedGymCode` wird gesetzt.
5. Bei Exceptions wird `_error` gesetzt (`membership_sync_failed` als generischer Fallback) und die Exception weitergereicht.

**Annahmen:**
- `ensureMembership` ist idempotent (Zwischenspeicher `_ensured` verhindert Mehrfach-Transactions pro Session).
- Alle gym-gebundenen Provider registrieren sich über `GymScopedStateController`, sodass `resetGymScopedState()` genügt.

## 6. IST-Flow Logout
1. `LogoutUseCase` meldet bei Firebase ab.
2. `GymScopedStateController.resetGymScopedState()` läuft, `_user` sowie `_selectedGymCode` werden geleert, SharedPreferences-Eintrag gelöscht.
3. `SessionDraftRepository.deleteAll()` entfernt gymspezifische Entwürfe.

**Annahmen:** Nach Logout dürfen keine Restdaten (Drafts, gym code) im Speicher verbleiben.

## 7. Identifizierte Probleme & Risiken
1. **Fehlende Gym-Zuordnung bei Mehrfach-Mitgliedschaft:** `requiresGymSelection` flaggt nur das UI, jedoch gibt es keinen dedizierten Flow, der Nutzer zwingt, vor Nutzung eines gym-spezifischen Features eine Auswahl zu treffen. Gefahr inkonsistenter Zustände bei Feature-Aufrufen ohne Kontext.
2. **Fehlerpropagation bei `switchGym`:** `_error` wird gesetzt, Exception rethrown; UI muss sowohl auf Exception als auch auf Provider-Error lauschen → potenziell doppelte Fehlerpfade.
3. **Persistenter Cache `_ensured`:** `FirestoreMembershipService` hält `_ensured` nur in-memory. App-Restarts verlieren die Information → unnötige Transactions bleiben möglich.
4. **GymScopedStateController-Kopplung:** Alle gym-abhängigen Provider müssen manuell registriert werden. Fehlende Registrierung führt zu stale data nach `switchGym` oder Logout.
5. **Token-Refresh ohne UI-Signal:** Nach `forceRefreshIdToken` gibt es kein Event, das UI informiert, dass Claims aktualisiert wurden. Abhängige Module müssen Polling betreiben oder rely on Firebase intern.
6. **App-Start ohne verbindlichen Gym-Check:** `SplashScreen` prüft nur Anzahl der `gymCodes`, aber nicht, ob `_selectedGymCode` leer ist oder `MembershipService.ensureMembership` für das gespeicherte Gym lief. Fehlkonfigurierte `SharedPreferences` können dazu führen, dass Provider mit einem ungültigen Kontext booten.
7. **Unklare Fehleroberfläche beim Claims-Laden:** Scheitert `getIdTokenClaims`, beendet `_loadCurrentUser` frühzeitig mit `_error`, während `SplashScreen` weiterpollt und schließlich `AppRouter.auth` wählt. Nutzer sehen keinen Hinweis, dass Claims fehlten; Risiko für Softlocks bei Netzwerkproblemen direkt zum App-Start.

## 8. SOLL-Architektur & Sequenzen
### 4.1 Zielbild
- Zentraler **Auth-&-Gym-Orchestrator** (`AuthProvider` bleibt, erhält aber klar definierte Ausgabesignale):
  - Liefert strukturierte Events (`AuthState`, `GymContextChanged`) statt impliziter Flags.
  - Bindet `GymScopedStateController` als Pflicht-Abhängigkeit ein, sodass Registrierungen typisiert geprüft werden können.
- **GymContextGuard** im UI-Router stellt sicher, dass vor Eintritt in gym-gebundene Screens ein gültiger Kontext vorhanden ist (Nutzen von `AuthResult.requiresGymSelection`).
- **MembershipSyncService** kapselt `ensureMembership`, `setActiveGym`, Token-Refresh in eigene Sequenz, erlaubt Retry/Telemetry.

### 4.2 Sequenz: Login mit Mehrfach-Gym
1. UI → `AuthProvider.login`.
2. Nach `_loadCurrentUser` emittiert Provider `AuthState.authenticated` + `GymContextStatus.pendingSelection`.
3. Router blockiert gym-spezifische Navigation, öffnet `SelectGymScreen` (`features/gym/presentation/screens/select_gym_screen.dart`).
4. Nutzer wählt Gym → `switchGym` → `MembershipSyncService` → Erfolg → `GymContextStatus.ready`.
5. `GymScopedStateController` broadcastet Reset; abhängige Provider laden Daten für neues Gym.

### 4.3 Sequenz: Fehler beim Gym-Wechsel
1. Nutzer löst `switchGym('gymX')` aus.
2. `MembershipSyncService` ruft `ensureMembership` → Firestore-Fehler.
3. Service mappt Fehler auf strukturierten Typ (`MembershipSyncError`), kein Side-Effect auf `_selectedGymCode`.
4. UI erhält `GymContextChangeFailed` Event (inkl. Ursache), zeigt Retry-Option; `_error` wird nicht für UI-Logik recycelt.

### 4.4 Sequenz: Logout
1. UI → `AuthProvider.logout`.
2. Provider emittiert `AuthState.loading`, ruft `LogoutUseCase`.
3. Nach Erfolg: `GymScopedStateController.reset`, `SessionDraftRepository.deleteAll`, SharedPreferences purge.
4. UI erhält `AuthState.loggedOut`, Router entfernt geschützte Routen.

### 4.5 Maßnahmen zur Problembehebung
- **Validierung vor Feature-Zugriff:** `GymContextGuard` zwingt Auswahl sobald `requiresGymSelection=true`.
- **Einheitliches Error-Handling:** Einführung eigener Error-Typen statt `_error` String; UI konsumiert Streams/ChangeNotifiers.
- **Registrierungs-Check:** Dev-Tooling/Test, das sicherstellt, dass jeder Provider mit Gym-Bezug `GymScopedResettable` implementiert.
- **Persistentes Membership-Caching:** Erweiterung von `MembershipService` um lokale Persistenz (z. B. SharedPreferences Flag pro `gymId|uid`).

## 9. Referenzen
- `lib/main.dart` – Initialisierung von Firebase, Provider-Hierarchie, `runApp`.
- `lib/features/splash/presentation/screens/splash_screen.dart` – Splash-Flow & Routing-Entscheidungen.
- `lib/core/providers/auth_provider.dart` – Implementiert `AuthResult`, Login/Register/Logout/SwitchGym-Logik.
- `lib/services/membership_service.dart` – Firestore-Transaction zur Mitgliedschaftssicherung.
- `lib/core/providers/gym_scoped_resettable.dart` – Definition von `GymScopedStateController` und Reset-Interface.
- `lib/features/gym/presentation/screens/select_gym_screen.dart` – Aktueller UI-Entry-Point für Gym-Auswahl.
