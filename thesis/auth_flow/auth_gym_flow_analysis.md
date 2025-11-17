# Auth & Gym Flow Analyse

## 1. Überblick
- **Scope:** Dokumentiert alle Abläufe rund um Anmeldung, Gym-Zuordnung und Kontextwechsel innerhalb der Flutter-App. Grundlage bilden `AuthProvider`, `AuthResult`, `switchGym` sowie der `GymScopedStateController` aus `lib/core/providers/auth_provider.dart` und `lib/core/providers/gym_scoped_resettable.dart`.
- **Ziel:** Einheitliches Referenzdokument für Produkt, Backend und Mobile zur Planung künftiger Änderungen an Authentifizierung, Mitgliedschaftsprüfung (`MembershipService`) und gym-spezifischen Zuständen.
- **Explizite Annahmen:**
  1. Firebase Authentication bleibt das führende Identitätssystem (UID = eindeutiger Nutzerbezug in Firestore).
  2. Die Gym-Liste eines Users (`UserData.gymCodes`) ist autoritativ und enthält nur Gyms, denen der Nutzer bereits beitreten darf.
  3. Persistenter Gym-Kontext (SharedPreferences-Key `selectedGymCode`) wird ausschließlich von `AuthProvider` gesetzt.

## 2. IST-Flows
### 2.1 Login (`AuthProvider.login`)
1. UI triggert `login(email, password)`; `AuthProvider` setzt `_isLoading=true`.
2. `LoginUseCase` meldet bei Firebase Auth an und ruft `_loadCurrentUser()`.
3. `_loadCurrentUser()` lädt Claims (für Rolle), anschließend `GetCurrentUserUseCase` für `UserData`.
4. Gym-Auswahl:
   - Wenn `selectedGymCode` in SharedPreferences gespeichert und in `gymCodes` enthalten → Wiederherstellung.
   - Andernfalls erster Code aus `gymCodes`.
5. `AuthResult.success` wird mit Flags gesetzt: `requiresGymSelection` wenn mehr als ein Gym oder kein gespeicherter Code, `missingMembership` wenn `gymCodes` leer.
6. Fehler (z. B. FirebaseAuthException) resultieren in `AuthResult.failure` mit `_error`.

**Annahmen:** Nutzer besitzt mindestens eine Rolle oder Claim, der dem UI signalisieren kann, ob zusätzliche Berechtigungen bestehen (impliziert durch `role`-Feld).

### 2.2 Registrierung (`AuthProvider.register`)
1. `RegisterUseCase` erstellt Konto (inkl. initialem Gym-Code) und ruft `_loadCurrentUser()`.
2. Falls Backend noch kein `UserData` liefert, nutzt der Provider das vom UseCase zurückgegebene Objekt.
3. Persistenter Gym-Code wird auf das erste Element von `registeredUser.gymCodes` gesetzt.
4. Rückgabe erfolgt wieder über `_resolveAuthResult()`.

**Annahmen:** `RegisterUseCase` stellt sicher, dass der initiale Gym-Code gültig ist und `gymCodes` mindestens einen Eintrag besitzt.

### 2.3 Gym-Wechsel (`AuthProvider.switchGym`)
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

### 2.4 Logout
1. `LogoutUseCase` meldet bei Firebase ab.
2. `GymScopedStateController.resetGymScopedState()` läuft, `_user` sowie `_selectedGymCode` werden geleert, SharedPreferences-Eintrag gelöscht.
3. `SessionDraftRepository.deleteAll()` entfernt gymspezifische Entwürfe.

**Annahmen:** Nach Logout dürfen keine Restdaten (Drafts, gym code) im Speicher verbleiben.

## 3. Identifizierte Probleme & Risiken
1. **Fehlende Gym-Zuordnung bei Mehrfach-Mitgliedschaft:** `requiresGymSelection` flaggt nur das UI, jedoch gibt es keinen dedizierten Flow, der Nutzer zwingt, vor Nutzung eines gym-spezifischen Features eine Auswahl zu treffen. Gefahr inkonsistenter Zustände bei Feature-Aufrufen ohne Kontext.
2. **Fehlerpropagation bei `switchGym`:** `_error` wird gesetzt, Exception rethrown; UI muss sowohl auf Exception als auch auf Provider-Error lauschen → potenziell doppelte Fehlerpfade.
3. **Persistenter Cache `_ensured`:** `FirestoreMembershipService` hält `_ensured` nur in-memory. App-Restarts verlieren die Information → unnötige Transactions bleiben möglich.
4. **GymScopedStateController-Kopplung:** Alle gym-abhängigen Provider müssen manuell registriert werden. Fehlende Registrierung führt zu stale data nach `switchGym` oder Logout.
5. **Token-Refresh ohne UI-Signal:** Nach `forceRefreshIdToken` gibt es kein Event, das UI informiert, dass Claims aktualisiert wurden. Abhängige Module müssen Polling betreiben oder rely on Firebase intern.

## 4. SOLL-Architektur & Sequenzen
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

## 5. Referenzen
- `lib/core/providers/auth_provider.dart` – Implementiert `AuthResult`, Login/Register/Logout/SwitchGym-Logik.
- `lib/services/membership_service.dart` – Firestore-Transaction zur Mitgliedschaftssicherung.
- `lib/core/providers/gym_scoped_resettable.dart` – Definition von `GymScopedStateController` und Reset-Interface.
- `lib/features/gym/presentation/screens/select_gym_screen.dart` – Aktueller UI-Entry-Point für Gym-Auswahl.

## 8. SOLL-Zustand
### 8.1 Prinzipien
- `AuthProvider` fungiert als einziger Orchestrator und veröffentlicht klare Statusobjekte (`AuthState`, `GymContextChanged`), sodass UI und Services deterministisch reagieren können.
- `MembershipService` kapselt jede serverseitige Validierung und persistiert den letzten erfolgreichen Sync pro `uid|gymCode`, bevor `AuthProvider` den Kontext freigibt.
- `GymScopedStateController` ist für alle gym-abhängigen Provider verpflichtend und stellt ein konsistentes Reset-Protokoll bereit (Registrierung während App-Init, Reset bei Wechsel/Logout).
- Annahme: Alle Netzwerkzugriffe werden über UseCases geführt, die Retries/Timeouts kapseln und damit `AuthProvider` von Low-Level-Fehlern entlasten.

### 8.2 Auth-Flow (App-Start, Login, Registrierung, Logout)
**App-Start (Cold Start / Resume)**

| Schritt | Verantwortlich | Beschreibung |
| --- | --- | --- |
| 1 | `AuthProvider.init()` | Liest persistierten Token + `selectedGymCode`, setzt temporären Status `AuthState.initializing`. |
| 2 | `MembershipService.preloadMemberships(uid)` | Lädt bekannte Membership-Daten; fehlende Einträge werden als „unsynchronisiert“ markiert. |
| 3 | `AuthProvider._loadCurrentUser()` | Synchronisiert Claims, lädt `UserData` samt `gymCodes`. |
| 4 | `GymScopedStateController.prepare()` | Registrierte Resettables prüfen, ob der gespeicherte Gym-Code gültig bleibt; bei Inkonsistenz wird `requiresGymSelection` emittiert. |
| 5 | Fallback | Wenn kein gültiger Gym-Code gefunden wird, erzwingt der Router den `SelectGymScreen`. |

**Login**

| Schritt | Verantwortlich | Beschreibung |
| --- | --- | --- |
| 1 | `AuthProvider.login` | Startet Auth-Request, setzt `_isLoading=true`, signalisiert UI `AuthState.loading`. |
| 2 | `LoginUseCase` + `AuthProvider._loadCurrentUser()` | Laden Nutzerprofil + Claims; validieren, ob gespeicherter Gym-Code innerhalb `user.gymCodes` liegt. |
| 3 | Konsistenz-Check | Wenn mehrere Gyms → UI erhält `requiresGymSelection`. Ein einzelner Gym wird sofort via `_setActiveGym` gesetzt. |
| 4 | `GymScopedStateController.resetGymScopedState()` | Nur falls Gym gewechselt wurde oder keine vorherige Session bestand. |
| 5 | Abschluss | `AuthResult.success` enthält Flags für `missingMembership` oder `requiresGymSelection`; UI navigiert entsprechend. |

**Registrierung**

| Schritt | Verantwortlich | Beschreibung |
| --- | --- | --- |
| 1 | `RegisterUseCase` | Erstellt Nutzer + initiales Gym; liefert `UserData`. |
| 2 | `AuthProvider.register` | Persistiert ersten Gym-Code, führt `_loadCurrentUser` aus, setzt Status `AuthState.authenticated`. |
| 3 | `MembershipService.ensureMembership(initialGym)` | Validiert, dass Mitgliedschaft sofort aktiv ist; Failure führt zu Rollback des Gym-Codes. |
| 4 | `GymScopedStateController.resetGymScopedState()` | Informiert abhängige Provider, damit Branding/Inventare für neues Gym geladen werden. |
| 5 | Fallback | Annahme: Falls `MembershipService` keine Bestätigung liefert, zwingt der Flow den Nutzer zurück in `SelectGymScreen` bevor Features freigeschaltet werden. |

**Logout**

| Schritt | Verantwortlich | Beschreibung |
| --- | --- | --- |
| 1 | `AuthProvider.logout` | Signalisiert `AuthState.loading`, ruft `LogoutUseCase`. |
| 2 | `GymScopedStateController.resetGymScopedState()` | Löscht alle gym-abhängigen Stores, inklusive `SessionDraftRepository`. |
| 3 | Persistenz-Cleanup | SharedPreferences (`selectedGymCode`, Tokens) und lokale Membership-Caches werden entfernt. |
| 4 | Abschluss | `AuthState.loggedOut` + Navigation zur Public Shell; UI bestätigt, dass keine geschützten Provider mehr aktiv sind. |

### 8.3 Gym-Wechsel
1. Nutzer wählt neuen Gym in UI → `AuthProvider.switchGym(newGymCode)` validiert, ob `newGymCode` in `user.gymCodes` enthalten ist.
2. `MembershipService.ensureMembership(newGymCode, uid)` führt Transaction aus; erst nach Erfolg wird `_setActiveGym` aufgerufen.
3. `AuthProvider` aktualisiert SharedPreferences, setzt `_selectedGymCode` und triggert `GymScopedStateController.resetGymScopedState()`.
4. `GymScopedStateController` broadcastet Reset; abhängige Provider starten Reload-Sequenzen (z. B. Inventare, Branding, SessionDrafts).
5. `FirebaseAuthManager.forceRefreshIdToken()` läuft asynchron; erst nach erfolgreichem Refresh sendet `AuthProvider` ein `GymContextChanged` Event mit Ready-Status.
6. Annahme: Falls `ensureMembership` bereits für denselben `uid|gymCode` erfolgreich war und dies im lokalen Cache markiert ist, darf der Schritt erneut übersprungen werden, um Latenz zu sparen.

### 8.4 Fehler- und Edge-Cases
- **Verlorene Gym-Auswahl beim App-Start:** `AuthProvider` prüft beim Initialisieren, ob der persistierte Code noch in `UserData.gymCodes` existiert. Falls nicht, setzt er `requiresGymSelection` und löscht den Wert, bevor `GymScopedStateController` neue Daten lädt.
- **Membership-Service nicht erreichbar:** `MembershipService.ensureMembership` liefert strukturierten Fehler `MembershipSyncError`. `AuthProvider` behält bisherigen Gym-Code, emittiert `GymContextChangeFailed`, UI bietet Retry und belässt alte Daten aktiv.
- **Logout während laufendem Gym-Wechsel:** `AuthProvider.logout` setzt ein internes Flag, das `switchGym`-Promises verwirft. `GymScopedStateController` führt Reset nur einmal aus, um halb geladene Provider zu vermeiden.
- **Mehrfachstart der App (Parallelprozesse):** Annahme: Nur ein `AuthProvider` existiert; sollte das OS die App duplizieren, synchronisiert `AuthProvider.init()` erneut SharedPreferences, bevor UI Interaktionen erlaubt.
- **Fehlende Registrierung eines Providers beim Controller:** Build-Tests erzwingen, dass jeder `ChangeNotifier` mit Gym-Bezug `GymScopedResettable` implementiert und vom `GymScopedStateController` referenziert wird; andernfalls schlägt der Test fehl und blockiert Deployment.
