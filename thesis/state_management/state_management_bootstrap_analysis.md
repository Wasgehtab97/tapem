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

## 2. Aktueller Bootstrap-Flow (Provider → Hybrid)
- **Neue Annahme A:** Alle initialen Infrastruktur-Abhängigkeiten (Firebase, Messaging, Report-UseCases, SharedPreferences) werden über
  `bootstrap/bootstrap.dart` erzeugt und als Riverpod-Overrides (`sharedPreferencesProvider`, `getDeviceUsageStatsProvider`,
  `getAllLogTimestampsProvider`) in den App-Baum injiziert, bevor irgendein Legacy-Provider erstellt wird.【F:lib/bootstrap/bootstrap.dart†L1-L77】
- `BootstrapResult.toOverrides()` liefert die Liste der ProviderScope-Overrides, die `runApp` an den obersten Scope übergibt. Damit sind
  SharedPreferences und Report-UseCases sowohl in Provider- als auch Riverpod-Zweigen konsistent verfügbar.【F:lib/bootstrap/bootstrap.dart†L21-L35】

## 3. LegacyProviderScope (Provider-Hierarchie)
- **Neue Annahme B:** `LegacyProviderScope` kapselt alle bestehenden `provider.MultiProvider`-Registrierungen und bildet den Übergabeort
  zwischen den Bootstrap-Overrides und dem restlichen Legacy-State. Der Scope liest Riverpod-Values (z. B. SharedPreferences,
  MembershipService) via `ref.watch(...)` und spiegelt sie als klassische Provider-Instanzen wider.【F:lib/bootstrap/legacy_provider_scope.dart†L1-L120】
- Reihenfolge innerhalb der `MultiProvider`-Liste: Reset-Controller (`GymScopedStateController`) entsteht vor `AuthProvider`, gefolgt von
  Proxy-Providern wie `BrandingProvider` oder `GymProvider`, die sich im `update`-Hook an Auth koppeln. Services, Repositories und
  Notifier (History, Reports, Devices etc.) folgen danach. Der Scope ist somit die zentrale Stelle, an der neue Legacy-States registriert
  werden.【F:lib/bootstrap/legacy_provider_scope.dart†L51-L200】【F:lib/bootstrap/legacy_provider_scope.dart†L300-L410】

## 4. _LegacyRiverpodBridge (Hybrid-Verzahnung)
- **Neue Annahme C:** `_LegacyRiverpodBridge` ist die einzige Klasse, die Legacy-Provider direkt in Riverpod einspeist. Sie liest
  `AuthProvider`, `BrandingProvider` und `GymProvider` aus dem `MultiProvider`-Kontext und erstellt daraus Riverpod-Overrides für
  `authControllerProvider`, `authViewStateProvider`, `brandingProvider` und `gymProvider`. Damit teilen sich Provider- und Riverpod-Welt
  exakt dieselben Instanzen.【F:lib/bootstrap/legacy_provider_scope.dart†L431-L489】
- Die Overrides werden einmalig in `didChangeDependencies` erstellt und anschließend in einem inneren `ProviderScope` angewendet.
  Riverpod-Consumer (z. B. Community-Feature) empfangen so stets dieselben ChangeNotifier-Signale wie Provider-Widgets. Ein fehlerhafter
  oder fehlender Override würde sofort zu divergierenden States führen.

## 5. End-to-End-Flow (vom Bootstrap bis zur UI)
1. `bootstrapApp()` initialisiert Firebase, Push, Avatar-Katalog und Report-Abhängigkeiten und liefert ein `BootstrapResult` zurück.
2. `runApp` erstellt einen äußeren `ProviderScope` mit den Overrides aus `BootstrapResult.toOverrides()` und ruft innerhalb davon den
   `LegacyProviderScope` auf.
3. `LegacyProviderScope` baut die komplette `provider.MultiProvider`-Kette (inkl. Auth, Branding, Gym, Feature-Services) auf und rendert
   `_LegacyRiverpodBridge` als Kind.
4. `_LegacyRiverpodBridge` öffnet einen inneren `ProviderScope`, der die Legacy-Instanzen als Riverpod-Overrides bereitstellt. Danach
   rendert er das eigentliche App-Widget (`child`).
5. Riverpod-spezifische Widgets (Community) lesen Gym- oder Auth-State ausschließlich über diese Overrides, während klassische Widgets
   weiterhin `context.watch` nutzen. Beide Welten reagieren damit synchron auf Gym-Wechsel oder Logout-Ereignisse.

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
- **Gegenwärtige Hybridstrategie:** Provider bildet weiterhin die tragende UI-Schicht, während Riverpod punktuell Features (Community, neue Experimente) antreibt. `_LegacyRiverpodBridge` bleibt explizit Teil des Bootstraps, um Auth/Gym/Branding als Overrides in die Riverpod-Welt zu spiegeln. Solange `LegacyProviderScope` existiert, werden zusätzliche Riverpod-Provider nur über Overrides integriert – direkte Provider→Riverpod-Zugriffe sind verboten.【F:lib/bootstrap/legacy_provider_scope.dart†L431-L489】
- **Geplante Migration:** Neue Domains sollen bevorzugt native Riverpod-Provider erhalten, die lediglich SharedPreferences, MembershipService oder andere Bootstrap-Abhängigkeiten über `BootstrapResult.toOverrides()` beziehen. Legacy-Provider werden sukzessive ersetzt, indem ihre ChangeNotifier-Logik in Riverpod-Portierungen landet. Sobald Auth/Gym selbst Riverpod-first sind, kann `_LegacyRiverpodBridge` entfallen und der äußere `ProviderScope` übernimmt sämtliche Zustände.【F:lib/bootstrap/bootstrap.dart†L21-L77】【F:lib/bootstrap/legacy_provider_scope.dart†L1-L200】
- **Rolle der Overrides:** Overrides sind der Mechanismus, der Konsistenz garantiert. Jede Hybrid-Erweiterung muss prüfen, ob der benötigte State bereits als Riverpod-Override existiert (z. B. `authControllerProvider`, `brandingProvider`, `gymProvider`). Fehlt ein Override, muss `_overrides` erweitert werden, damit Riverpod und Provider identische Instanzen teilen. Ohne diesen Schritt entstehen divergierende Auth-/Gym-Wahrheiten.
- **Auth-/Gym-Flows:** AuthProvider orchestriert weiterhin Gym-Wechsel, ruft `GymScopedStateController.resetGymScopedState()` auf und löst damit sowohl Provider- als auch Riverpod-Updates aus. Neue Strategiebausteine müssen respektieren, dass Logout/Gym-Wechsel erst abgeschlossen sind, wenn sowohl `LegacyProviderScope` als auch `_LegacyRiverpodBridge` den neuen Zustand propagiert haben.

## 8. Einbindung & Tests neuer States
1. **Provider-basiertes Onboarding:**
   - Neue `ChangeNotifier` müssen im `LegacyProviderScope.providers`-Array registriert werden und – falls gym-abhängig – `GymScopedResettableChangeNotifier` implementieren sowie den Controller via `context.read<GymScopedStateController>()` registrieren.【F:lib/bootstrap/legacy_provider_scope.dart†L51-L200】
   - Auth/Gym-sensitive Provider laden Daten ausschließlich über `authProvider.gymCode` oder `authProvider.userId` im `update`-Hook, damit der Reset-Mechanismus greift. Kommentare im Scope dokumentieren die notwendige Reihenfolge.
2. **Riverpod-Onboarding innerhalb des bestehenden Bootstraps:**
   - Benötigt der neue Riverpod-State direkten Zugriff auf Legacy-Instanzen (z. B. AuthProvider), muss `_LegacyRiverpodBridge` einen weiteren Override erhalten: `overrides += [myProvider.overrideWith((ref) => context.read<MyNotifier>())];`. Ohne diesen Schritt existieren zwei unterschiedliche Instanzen.【F:lib/bootstrap/legacy_provider_scope.dart†L431-L489】
   - Nutzt der State nur Bootstrap-Abhängigkeiten (SharedPreferences, Report-UseCases), reichen die vorhandenen Overrides aus `BootstrapResult.toOverrides()` – zusätzliche ProviderScope-Schichten sind nicht nötig.【F:lib/bootstrap/bootstrap.dart†L21-L77】
3. **Konkrete Tests für Auth/Gym-abhängige States:**
   - **Unit:** ChangeNotifier-Tests mit Fake `GymScopedStateController` und Mock MembershipService prüfen, dass `resetGymScopedState()` aufgerufen und `gymCode` korrekt neu geladen wird.
   - **Widget:** Ein Widget-Test, der `LegacyProviderScope` + `_LegacyRiverpodBridge` in einen Test-`ProviderScope` einbettet und AuthProvider via Fake MembershipService umschaltet, stellt sicher, dass der neue ProviderScope-Override aktualisiert wird.
   - **Integration/Golden:** Für Features mit Firestore-Abhängigkeit (z. B. Community) sollten Gyms via Fake AuthState gewechselt werden, während `ref.watch`-Consumer beobachtet werden; Assertions stellen sicher, dass alte Streams geschlossen werden.

## 9. Override-Governance (LegacyProviderScope)
- `_LegacyRiverpodBridge` definiert die verbindliche Liste aller Overrides. Neue Riverpod-States, die ein Legacy-Gegenstück teilen müssen, fügen dort einen Eintrag hinzu – idealerweise mit `overrideWithProvider`, wenn zusätzliche Transformation (z. B. `AuthViewState.fromAuth`) nötig ist.【F:lib/bootstrap/legacy_provider_scope.dart†L431-L489】
- Beispiel: Ein neuer Riverpod-Notifier `legacyHistoryProvider` sollte über `legacyHistoryProvider.overrideWith((ref) => provider.Provider.of<HistoryProvider>(context, listen: false))` angebunden werden. Tests müssen sicherstellen, dass der Override dieselbe Instanz wie `context.watch<HistoryProvider>()` liefert.
- Für Auth/Gym-abhängige Overrides sind gezielte Tests Pflicht: Ein Widget-Test setzt `ProviderScope(overrides: [...])` mit dem neuen Override auf, triggert `authProvider.switchGym()` und prüft, dass sowohl Provider- als auch Riverpod-Consumer denselben neuen Wert sehen (z. B. `expect(ref.read(legacyHistoryProvider).lastGym, equals('gym-b'))`). Ohne diesen Test besteht die Gefahr, dass Overrides veralten oder `didChangeDependencies` nicht erneut ausgeführt wird.

