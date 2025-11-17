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

## 8. SOLL-Zustand
### 8.1 Prinzipien
- `AuthProvider` fungiert als klarer Orchestrator für Authentifizierung **und** aktiven Gym-Kontext und veröffentlicht Ereignisse (`AuthState`, `GymContextChanged`), die von `GymScopedStateController`, `MembershipService` und UI-Router konsumiert werden.
- `MembershipService` bleibt die einzige Stelle, an der Mitgliedschaftsprüfungen und `setActiveGym`-Persistierung passieren; alle Flows rufen ihn explizit auf, bevor sie `GymScopedStateController.resetGymScopedState()` auslösen.
- `GymScopedStateController` erhält verpflichtende Registrierungen aller gym-sensitiven Provider (Compile-Time Assertion). Dadurch wird jede Kontextänderung automatisch propagiert.
- App-Router-Schichten setzen konsequent Guard-Komponenten ein (z. B. `GymContextGuard`), die `AuthProvider`-Signale auswerten und Navigation nur bei konsistentem Kontext erlauben.
- Annahme: `AuthResult` wird um strukturierte Statusfelder erweitert (`authStatus`, `gymContextStatus`), damit UI-Logik keine Provider-Interna lesen muss.

### 8.2 Auth-Flow (App-Start, Login, Registrierung, Logout)
#### App-Start
| Schritt | Beschreibung |
| --- | --- |
| Initialisierung | `main.dart` lädt SharedPreferences, initialisiert Firebase und erstellt `AuthProvider` + `GymScopedStateController`. `AuthProvider` liest synchron `selectedGymCode` und startet `_loadCurrentUser()`.
| Datenladen | `_loadCurrentUser()` ruft `FirebaseAuthManager.currentUser`, Claims sowie `GetCurrentUserUseCase`. Parallel registriert `GymScopedStateController` alle `GymScopedResettable` Provider, damit spätere Resets möglich sind.
| Konsistenz-Checks | `AuthProvider` vergleicht gespeicherten Gym-Code mit `UserData.gymCodes`. Bei Abweichungen fordert er `MembershipService.ensureMembership` für den gespeicherten Code an; bei Fehler → markiert Kontext als „invalid“.
| Fallbacks | Falls kein gültiger Code vorhanden ist, erzwingt der Provider `GymContextStatus.pendingSelection` und navigiert via Router auf den Gym-Auswahl-Screen.

#### Login
| Schritt | Beschreibung |
| --- | --- |
| Initialisierung | UI ruft `AuthProvider.login`. Provider setzt `_isLoading` und erstellt ein Login-Event, sodass UI Spinners zeigen kann.
| Datenladen | Nach `LoginUseCase` wird `_loadCurrentUser()` erneut ausgeführt (Claims + `UserData`). `MembershipService` validiert den zuletzt persistierten Gym-Code.
| Konsistenz-Checks | `AuthProvider` prüft, ob `gymCodes` ≥ 1. Bei Mehrfachzugehörigkeit wird `requiresGymSelection` gesetzt, ansonsten wird automatisch `switchGym` für den einzigen Code angestoßen.
| Fallbacks | Auth-Fehler landen in `AuthResult.failure`. Annahme: UI besitzt Retry-Logik und zeigt `GymContextGuard`, bis `GymContextStatus.ready` ist.

#### Registrierung
| Schritt | Beschreibung |
| --- | --- |
| Initialisierung | `AuthProvider.register` ruft `RegisterUseCase` und übergibt den ausgewählten Start-Gym-Code.
| Datenladen | Nach erfolgreichem Backend-Call wird der aus dem UseCase zurückgegebene `UserData` sofort in `_user` gesetzt; `MembershipService.ensureMembership` bestätigt den initialen Gym.
| Konsistenz-Checks | `AuthProvider` legt `selectedGymCode` in SharedPreferences ab und prüft, ob Claims bereits den erwarteten `role`-Wert enthalten; ansonsten markiert er `AuthState` als „limited“ und fordert späteren Claim-Refresh an.
| Fallbacks | Sollte das Backend keinen Gym-Code zurückgeben, wird `AuthProvider` den Flow abbrechen (`AuthResult.failure`) und die UI auffordern, erneut zu starten. Annahme: Registrierung kann clientseitig nicht ohne Gym abgeschlossen werden.

#### Logout
| Schritt | Beschreibung |
| --- | --- |
| Initialisierung | UI ruft `AuthProvider.logout`, Provider emittiert `AuthState.loading` und sperrt weitere Auth-Operationen.
| Datenladen | `LogoutUseCase` meldet Firebase ab; `MembershipService` räumt etwaige lokale Membership-Caches (z. B. `_ensured`) auf.
| Konsistenz-Checks | `GymScopedStateController.resetGymScopedState()` wird ausgeführt, `SessionDraftRepository.deleteAll()` löscht Drafts, und SharedPreferences wird von `selectedGymCode` befreit.
| Fallbacks | Scheitert der Logout-Call, bleibt der vorherige Zustand bestehen, und der Provider liefert `AuthResult.failure` mit retryable Flag. Annahme: UI zeigt einen Dialog, bis Logout bestätigt ist.

### 8.3 Gym-Wechsel
| Phase | Beschreibung |
| --- | --- |
| Vorbereitung | `AuthProvider.switchGym(gymId)` prüft synchron, ob `_user` gesetzt ist und `gymId` zu `UserData.gymCodes` gehört. Danach wird `MembershipService.ensureMembership(gymId, uid)` aufgerufen.
| MembershipSync | `MembershipService` führt Transaction, aktualisiert `UserProfileService.setActiveGym` und ruft `FirebaseAuthManager.forceRefreshIdToken`. Erst nach erfolgreichem Abschluss werden `SharedPreferences` aktualisiert.
| State-Reset | `GymScopedStateController.resetGymScopedState()` invalidiert registrierte Provider (`BrandingProvider`, `GymProvider`, Trainings-Feature-Stores). Jeder Provider lädt Gym-Daten neu.
| Abschluss | `AuthProvider` emittiert `GymContextChanged`-Event. UI prüft `GymContextStatus.ready` und entsperrt gym-spezifische Screens. Bei Fehlern wird ein detaillierter `GymContextChangeFailed`-Typ mitgeliefert, damit UI fallbacken kann.
- Annahme: `MembershipService` erhält Persistenz für `_ensured`, damit App-Restarts nicht erneut Transactions pro Gym auslösen.

### 8.4 Fehler- und Edge-Cases
- **Fehlende Claims beim App-Start:** `AuthProvider` kennzeichnet den Zustand mit `AuthState.degraded` und fordert `FirebaseAuthManager.forceRefreshIdToken`. `GymScopedStateController` verhindert in diesem Zustand das Laden sensibler Provider.
- **Ungültiger persistierter Gym-Code:** `MembershipService.ensureMembership` liefert `membership_missing`. `AuthProvider` entfernt den Code aus SharedPreferences und setzt `GymContextStatus.pendingSelection`, während UI den Auswahl-Screen öffnet.
- **Timeout bei `switchGym`:** Bei Netzwerk-Timeout sendet der Provider ein Recoverable-Event. UI kann Retry oder `AuthProvider.logout` anbieten, falls keine stabile Verbindung besteht.
- **Logout während laufendem Gym-Wechsel:** `AuthProvider.logout` überprüft, ob `switchGym` aktiv ist. Erst nach Abbruch/Abschluss wird `GymScopedStateController.reset` ausgeführt, um partielle Zustände zu vermeiden.
- **Mehrere Gyms ohne Mitgliedschaft:** Falls `gymCodes` leer, aber `selectedGymCode` gesetzt ist, behandelt der Provider den Zustand als Sicherheitsverletzung, löscht lokale Daten und zwingt einen vollständigen Re-Login. Annahme: Backend liefert niemals `gymCodes` leer für aktive Accounts, außer Membership wurde entzogen.

## 9. Referenzen
- `lib/main.dart` – Initialisierung von Firebase, Provider-Hierarchie, `runApp`.
- `lib/features/splash/presentation/screens/splash_screen.dart` – Splash-Flow & Routing-Entscheidungen.
- `lib/core/providers/auth_provider.dart` – Implementiert `AuthResult`, Login/Register/Logout/SwitchGym-Logik.
- `lib/services/membership_service.dart` – Firestore-Transaction zur Mitgliedschaftssicherung.
- `lib/core/providers/gym_scoped_resettable.dart` – Definition von `GymScopedStateController` und Reset-Interface.
- `lib/features/gym/presentation/screens/select_gym_screen.dart` – Aktueller UI-Entry-Point für Gym-Auswahl.
