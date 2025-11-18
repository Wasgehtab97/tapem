# State-Management Bootstrap Analyse

## 1. Kontext & Prompt-Ziel
- **Zielsetzung:** Dokumentation der aktuellen State-Management-Landschaft (Provider vs. Riverpod), Analyse der Bootstrapping-Flows
  sowie Risiken im Auth-/Gym-Kontext als Grundlage für Masterarbeit und Refaktorings.
- **Scope:** Fokus auf `lib/main.dart` (App-Bootstrap), `lib/core/providers/*.dart` (klassische Provider-Struktur) sowie den
  Riverpod-Einsatz in `lib/features/community/presentation/providers/community_providers.dart`.
- **Explizite Annahmen:**
  1. Provider (`package:provider`) bleibt derzeit das führende Dependency-/State-Verteil-System für Kernfeatures.
  2. Riverpod wird bislang nur punktuell für Community-Streams verwendet und zieht seinen Kontext ausschließlich über
     `currentGymIdProvider`.
  3. Auth- und Gym-Wechsel-Logik (`AuthProvider`, `GymScopedStateController`) definieren die Wahrheit über globale App- und Gym-States.

## 2. Provider-Landschaft (package:provider)
- `lib/main.dart` registriert über mehr als 30 `provider.Provider` bzw. `ChangeNotifierProvider`-Einträge sämtliche Services,
  UseCases und ViewModel-ähnliche Notifier (`AuthProvider`, `GymProvider`, `ThemeLoader`, etc.). Die Reihenfolge ist bewusst gewählt,
  z. B. wird `GymScopedStateController` vor `AuthProvider` erstellt, damit Auth seinen Reset-Controller injizieren kann.【F:lib/main.dart†L24-L189】【F:lib/main.dart†L560-L617】
- Kernabhängigkeiten:
  - **Auth & Gym:** `AuthProvider` lädt im Konstruktor den aktuellen User, registriert Gym-Resettable-Provider und orchestriert Login,
    Logout, Registrierung und Gym-Wechsel. `GymScopedStateController` verteilt Reset-Signale an Provider, die das Mix-in nutzen.
    【F:lib/core/providers/auth_provider.dart†L1-L154】【F:lib/core/providers/gym_scoped_resettable.dart†L1-L34】
  - **Scoped Provider:** `BrandingProvider`, `GymProvider`, `HistoryProvider`, etc. lesen `AuthProvider.gymCode` bzw. `userId` in ihren
    `update`-Hooks, wodurch Bootstrapping stark an Auth gekoppelt bleibt (Reihenfolge wichtig).
  - **Service Layer:** `MembershipService`, Repositories (Device, Exercise, Community) sowie helper wie `OverlayNumericKeypadController`
    werden via Provider injiziert, damit Widgets über `context.read`/`watch` zugreifen können.
- Vorteil: Provider-Hierarchie existiert seit Projektbeginn, viele Widgets nutzen `context.watch<T>()`, was Migrationen erschwert.

## 3. Riverpod-Landschaft
- Riverpod ist ausschließlich in der Community-Feature-Schicht aktiv (`community_screen.dart`, `community_providers.dart`).
- `_RiverpodApp` (in `main.dart`) kapselt `MyApp` mit einem `riverpod.ProviderScope`, der `currentGymIdProvider` pro Frame mit dem
  aktuellen Gym aus `AuthProvider` überschreibt. Damit können Riverpod-Widgets `ref.watch(currentGymIdProvider)` verwenden, obwohl
  der tatsächliche Wert aus dem Provider-Ökosystem stammt.【F:lib/main.dart†L600-L639】
- Riverpod-Provider:
  - `currentGymIdProvider`: abstrakte Quelle, muss beim Bootstrap überschrieben werden.
  - `communityStatsServiceProvider`: liefert `CommunityStatsService` mit Firestore-Source.
  - `communityStatsProvider` & `communityFeedProvider`: `StreamProvider.autoDispose` mit `currentGymIdProvider`-Abhängigkeit und
    dynamischem Zeitfenster (Perioden `today/week/month`). Wenn `gymId` leer, liefern sie fallback-Streams.【F:lib/features/community/presentation/providers/community_providers.dart†L1-L65】
- Consumer Widgets (`CommunityScreen`, `_CommunityTab`) verwenden `riverpod.ConsumerWidget` / `ConsumerStatefulWidget` zur Anzeige der
  AsyncValues (Stats & Feed).【F:lib/features/community/presentation/screens/community_screen.dart†L1-L140】
- Konsequenz: App nutzt aktuell ein **Hybrid-System**, bei dem Riverpod-Scopes auf Provider-States zugreifen. Das erfordert
  disziplinierte Bootstrap-Overrides (wie `currentGymIdProvider`) und Awareness für Lebenszyklen.

## 4. Bootstrapping-Flows
### 4.1 App-Start (`lib/main.dart`)
1. Firebase/AppCheck/Messaging werden initialisiert, SharedPreferences geladen.
2. `runApp` erhält eine `MultiProvider`-Liste; zuerst Infrastruktur (Firestore-Services, MembershipService, Device/Exercise-Repos),
   danach `GymScopedStateController`, `AuthProvider`, UI-Notifier. Reihenfolge kritischer Provider ist dokumentiert im Code.
3. `_RiverpodApp` liest `AuthProvider.gymCode` aus dem Provider-Kontext, erstellt pro Frame einen `ProviderScope` mit Override.
4. `MyApp` konsumiert Provider-States (Theme, Locale, Keypad) und richtet Router sowie globale Listener ein.【F:lib/main.dart†L1-L120】【F:lib/main.dart†L560-L724】

### 4.2 Gym-Wechsel / Auth-Refresh
1. `AuthProvider.switchGym` prüft Membership, aktualisiert Firestore (`setActiveGym`), ruft `GymScopedStateController.resetGymScopedState()`
   und persistiert den Code (SharedPreferences).【F:lib/core/providers/auth_provider.dart†L1-L154】
2. Registrierte Provider laden ihre Daten neu. Riverpod erhält automatisch den neuen `currentGymIdProvider`-Wert, sobald `_RiverpodApp`
   den Build mit aktualisiertem `context.watch<AuthProvider>()` ausführt.

### 4.3 Community-Screens
1. Beim Navigieren zu `CommunityScreen` erstellt Flutter eine Riverpod-Consumer-Stateful-Widget-Hierarchie.
2. Die Widgets lesen `communityStatsProvider` / `communityFeedProvider`; Abhängigkeit zu `currentGymIdProvider` sorgt für automatische
   Neusubscription, sobald der Gym-Code wechselt (ProviderScope override ändert sich).【F:lib/features/community/presentation/screens/community_screen.dart†L60-L180】

## 5. Risiken & Schwachstellen
1. **Bootstrap-Divergenz:** Provider-Hierarchie ist stark sequentiell. Ein versehentlich verschobener Eintrag in `MultiProvider`
   kann dazu führen, dass `AuthProvider` keinen `GymScopedStateController` erhält oder abhängige Provider (z. B. `BrandingProvider`)
   ohne valides `gymCode`-Signal initialisieren.【F:lib/main.dart†L560-L617】
2. **Hybrid-Kopplung:** Riverpod kennt keine eigene Quelle für `currentGymId`; es verlässt sich darauf, dass `_RiverpodApp` den
   Override korrekt setzt. Fehlerhafte oder verzögerte Builds führen zu Stale-Streams, besonders wenn AuthProvider `gymCode == null`
   liefert (z. B. beim Logout).【F:lib/main.dart†L600-L639】
3. **Fehlende zentrale Registry:** `GymScopedStateController` registriert nur manuell eingebundene Provider. Vergisst ein Team-Mitglied
   das Mix-in oder die Registrierung, bleibt alter Gym-Content aktiv → Inkonsistenz beim Gym-Wechsel.
4. **State-Vererbung über UI-Hierarchien:** Provider (`context.watch`) und Riverpod (`ProviderScope`) folgen unterschiedlichen
   Lebenszyklen. Komplexe Features (z. B. Auth + Community) benötigen klare Garantien, wann `currentGymId` aktualisiert ist.
5. **Testing-Gap:** Es existieren keine dokumentierten Tests, die den ProviderScope-Override oder den Reset-Mechanismus beim
   Gym-Wechsel absichern. Unit-Tests für `AuthProvider` existieren im Repo nicht (laut Scan), wodurch Regressionen unentdeckt bleiben.

## 6. Roadmap für neue States
- **Registrierung:** Jeder neue `ChangeNotifier` mit Gym-Abhängigkeit muss `GymScopedResettableChangeNotifier` verwenden und sich im
  Konstruktor beim `GymScopedStateController` registrieren.
- **Riverpod-Integration:** Neue Riverpod-Provider erhalten ihre Daten ausschließlich über klar definierte Overrides (z. B.
  `ProviderScope(overrides: [...])`) statt direkter Provider-zu-Riverpod-Brücken. Langfristig sollte `currentGymIdProvider` seine
  Quelle direkt aus einem Riverpod-State beziehen, sobald eine Migration startet.
- **Testing:** Für neue States sind zwei Schichten vorgesehen:
  1. **Unit-Tests** für ChangeNotifier/Riverpod-Provider, die den Umgang mit `gymCode`-Änderungen simulieren (Mock `GymScopedStateController`).
  2. **Widget- bzw. Integrationstests** für kritische Screens, die sicherstellen, dass ProviderScope-Overrides funktionieren und
     UI bei Gym-Wechseln refreshen.

## 7. Designprinzipien & Strategieentscheidung
- **Designprinzipien:**
  1. Ein einzelner „Source of Truth“ für globale User- und Gym-Zustände (heute `AuthProvider`), ergänzt um einen deklarativen
     Gym-Kontext, der synchron in Provider- und Riverpod-Welten gespiegelt wird.
  2. Bootstrapping erfolgt deterministisch: Infrastruktur → Reset-Controller → Auth → Gym-scoped Provider → UI. Jeder Schritt muss
     testbar sein (Unit + Smoke).
  3. Gym-Scoped Reset ist obligatorisch: Alle gym-sensitiven States implementieren ein Reset-Interface oder stellen `Future<void>
     reload(String gymId)` bereit, damit `switchGym` deterministisch wirkt.
- **Strategie Provider vs. Riverpod:** Kurzfristig bleibt ein **Hybrid** erhalten, weil Großteile des UI `provider` nutzen und die
  Community-Module bereits Riverpod einsetzen. Entscheidung: Stabilisierung des Bridges-Patterns (`ProviderScope`-Override) und
  sukzessive Migration weiterer Features zu Riverpod, sobald Tests existieren. Vollständiger Sofortumstieg wäre riskant und nicht
  durch Ressourcen gedeckt.
- **Ziel-Bootstrapping:** Auth-Bootstrap (Firebase init → SharedPreferences → AuthProvider `_loadCurrentUser`) bleibt unverändert,
  wird aber künftig von Smoke-Tests begleitet. `currentGymIdProvider` soll mittelfristig direkt aus einem Riverpod-State gespeist
  werden (z. B. `authStateProvider`), sodass `_RiverpodApp` perspektivisch entfällt.
- **Bezug zum Auth-/Gym-Wechsel-Flow:** AuthProvider bleibt Orchestrator. Gym-Wechsel löst weiterhin `resetGymScopedState()` aus
  und aktualisiert SharedPreferences + Firestore. Riverpod-Community-Streams hängen am selben Gym-Signal, weshalb jede Strategie-
  Änderung zuerst sicherstellen muss, dass `currentGymId` atomar aktualisiert wird, bevor UI navigiert.

## 8. Einbindung & Tests neuer States
1. **Onboarding neuer Provider:**
   - Evaluieren, ob State `gym`-abhängig ist → `GymScopedResettableChangeNotifier` einsetzen.
   - Konstruktor-Parameter für `GymScopedStateController` hinzufügen und Registrierung in `init` sicherstellen.
   - Bootstrapping-Order dokumentieren (Kommentar in `main.dart`).
2. **Onboarding neuer Riverpod-Provider:**
   - Explizite Dependencies deklarieren (`dependencies: [...]`), `ref.listen(currentGymIdProvider, ...)` nutzen, um side-effects zu
     koordinieren.
   - Fallback-Verhalten definieren, wenn `gymId` leer oder `AuthState` nicht `ready` ist.
3. **Teststrategie:**
   - Unit-Tests für `AuthProvider`-ähnliche Controller (Mock MembershipService, SharedPreferences) sichern Bootstrapping.
   - Widget-Tests für `_RiverpodApp` prüfen, dass `currentGymIdProvider` den Watch-Wert korrekt übergibt.
   - Integrationstests für Auth/Gym-Flows (z. B. Fake Firebase/Auth) stellen sicher, dass UI bei Gym-Wechseln neu lädt und keine
     alten Streams aktiv bleiben.
