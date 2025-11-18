# Titel
PR: State-Management & Bootstrap-Unification

# Kontext
Die Codebasis kombiniert klassisches Flutter-`ChangeNotifier`-State-Management (z. B. `AuthProvider`, `BrandingProvider`) mit Riverpod-Providern. Damit Gamification-Forschungsarbeiten sauber aufsetzen können, musste der App-Bootstrap vereinheitlicht werden: ein einziger Entry-Point (`bootstrapApp` → `ProviderScope`) liefert alle plattformspezifischen Abhängigkeiten (Firebase, SharedPreferences, Reporting-Usecases), während State-Controller über klar definierte Provider injiziert werden. Das Dokument fasst die virtuelle PR zusammen, die diesen Brückenschlag beschreibt.

# Kurzfassung des Prompts
Der Prompt verlangte eine geschlossene Dokumentation, die
- Titel, Kontext, Prompt-Zusammenfassung, Ziele, Dateiliste, Ergebnis-Bullets und Masterarbeit-Hinweise enthält,
- die Zusammenführung des Bootstrap-Prozesses mit dem Riverpod-State-Tree erläutert und
- die wichtigsten Architekturentscheidungen (ProviderScope-Overrides, Gym-Scoped-State, Membership-Synchronisierung) nachvollziehbar macht.

# Ziele
1. Flutter-Bootstrap zentralisieren (`lib/bootstrap/bootstrap.dart`), damit alle Plattform- und Service-Initialisierungen (Firebase, Dotenv, AvatarCatalog, SharedPreferences) an einem Ort laufen.
2. ProviderScope-Overrides erzeugen (`BootstrapResult.toOverrides`) und den App-Start (`lib/main.dart`) ausschließlich über Riverpod orchestrieren.
3. Die bereits bestehenden ChangeNotifier-Controller (Auth, Branding, Gym) konsistent über `lib/bootstrap/providers.dart` kapseln, inklusive Membership-Service und Gym-Scoped-Reset.
4. Architekturentscheidungen dokumentieren, damit Gamification-Analysen nachvollziehen, welche Datenflüsse (Auth ↔ Branding ↔ Gym) vorausgesetzt werden.

# Betroffene Dateien
- `lib/main.dart`: Startet die App ausschließlich über `ProviderScope` und injiziert die vom Bootstrap gelieferten Overrides.
- `lib/bootstrap/bootstrap.dart`: Stellt `bootstrapApp` bereit, initialisiert Firebase, Push-Messaging, Avatar-Katalog, Report-Usecases und SharedPreferences und fasst alles in `BootstrapResult` zusammen.
- `lib/bootstrap/providers.dart`: Definiert die Riverpod-Provider für SharedPreferences, Reporting-Usecases, Membership-Service, Auth-, Branding- und Gym-Controller inkl. Gym-Scoped-State-Verkettung.
- `lib/core/providers/auth_provider.dart`: Verkörpert den ChangeNotifier, der Login/Register/Gym-Wechsel orchestriert und Membership-Service sowie `GymScopedStateController` konsumiert.
- `lib/core/providers/gym_scoped_resettable.dart` (implizit genutzt): Liefert das Reset-Signal, das Branding- und Gym-Provider abhängige Zustände invalidieren lässt.

# Ergebnis-Bullets
- Ein einziger Bootstrap-Pfad (`bootstrapApp`) erledigt Environment-Loading, Firebase/AppCheck-Konfiguration, Avatar-Katalog-Warmup und Reporting-Abhängigkeitsaufbau, bevor `TapemApp` gerendert wird. (Siehe `lib/bootstrap/bootstrap.dart`)
- `BootstrapResult.toOverrides()` verankert SharedPreferences sowie Reporting-Usecases direkt als Riverpod-Overrides, wodurch `ProviderScope` in `lib/main.dart` keine weiteren manuellen Setups mehr benötigt. (Siehe `lib/main.dart`, `lib/bootstrap/bootstrap.dart`)
- `lib/bootstrap/providers.dart` kapselt die Übergänge zwischen Riverpod (`Provider`, `ChangeNotifierProvider`) und bestehenden Controllern. Auth-, Branding- und Gym-Provider lauschen aufeinander und reagieren auf Gym-Wechsel, wodurch Gamification-spezifische Zustände konsistent bleiben.
- `GymScopedStateController` fungiert als zentrales Reset-Event: AuthProvider löst beim `switchGym` ein Reset aus, Branding- und Gym-Provider registrieren sich und setzen eigene Caches zurück. (Siehe `lib/bootstrap/providers.dart`, `lib/core/providers/auth_provider.dart`)
- Membership-Handling wird über `membershipServiceProvider` vereinheitlicht, sodass AuthProvider und BrandingProvider dieselbe Datenquelle (FirestoreMembershipService) nutzen – essenziell für XP-/Leaderboard-Auswertungen pro Gym. (Siehe `lib/bootstrap/providers.dart`, `lib/core/providers/auth_provider.dart`)

# Architekturentscheidungen
- **ProviderScope als verpflichtender Einstieg**: `main.dart` ruft ausschließlich `bootstrapApp` auf und übergibt dessen Overrides an `ProviderScope`. Dadurch lässt sich jede weitere Plattform-Abhängigkeit zentral erweitern, ohne Widgets anpassen zu müssen.
- **Override-basierter Dependency-Injection-Layer**: Statt Singleton-Aufrufen exportiert `BootstrapResult.toOverrides()` konkrete Provider-Overrides für SharedPreferences und Reporting-Usecases. Tests oder alternative Laufzeitumgebungen können gezielt andere Instanzen einspeisen.
- **Gym-Scoped-State als Reset-PubSub**: Der `GymScopedStateController` wird als Provider erzeugt und an Auth-, Branding- und Gym-Controller übergeben. Architekturentscheidend ist, dass ein Gym-Wechsel sämtliche abhängigen ChangeNotifier-Zustände invalidiert, bevor neue Firestore-Abfragen starten.
- **Membership-Service als Single Source of Truth**: `membershipServiceProvider` liefert ein Firestore-basiertes Backend, das von Auth und Branding konsumiert wird. Damit hängen UI-Branding und Berechtigungsentscheidungen von denselben Membership-Daten ab.

# Hinweise für die Masterarbeit
- Beim Evaluieren von Gamification-Flows immer berücksichtigen, dass Auth-Zustände erst nach erfolgreichem `bootstrapApp` verfügbar sind; Experiment-Setups sollten daher ProviderScope-Overrides simulieren.
- Für State-Consistency-Analysen: Beobachte `GymScopedStateController` und `AuthProvider.switchGym`. Nur wenn dieses Zusammenspiel funktioniert, sind XP-/Leaderboard-Daten pro Gym valide.
- Masterarbeit-Kapitel zu Prompt-Driven Development kann diese PR-Dokumentation als Beispiel nutzen, wie Architekturentscheidungen (Overrides, Reset-Controller, Membership-Service) textuell festgehalten werden.
