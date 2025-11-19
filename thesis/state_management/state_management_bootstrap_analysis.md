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

## 2. Reale Bootstrap-Kette (main.dart → ProviderScope → LegacyProviderScope)
- **App-Einstieg:** `main.dart` ruft synchron `bootstrapApp()` auf, wartet auf das `BootstrapResult` und spannt anschließend einen globalen
  `ProviderScope` mit den resultierenden Overrides um die gesamte App.【F:lib/main.dart†L9-L16】【F:lib/bootstrap/bootstrap.dart†L1-L77】
- **ProviderScope → TapemApp:** Der `ProviderScope` rendert `TapemApp`, welches sofort den `LegacyProviderScope` um die eigentliche
  Material-App legt. Es existiert keine `_LegacyRiverpodBridge`; der Legacy-Scope ist direktes Kind des äußeren Riverpod-Scopes und erhält
  alle Overrides via `WidgetRef`.【F:lib/core/app/tapem_app.dart†L18-L26】【F:lib/bootstrap/legacy_provider_scope.dart†L1-L120】
- **LegacyProviderScope:** `LegacyProviderScope` liest SharedPreferences, MembershipService und alle Riverpod-first ChangeNotifier aus
  `bootstrap/providers.dart`, spiegelt sie als klassische Provider-Values (`provider.MultiProvider`) wider und reicht das resultierende
  Widget (`TapemMaterialApp`) ohne zusätzliche Riverpod-Brücke weiter.【F:lib/bootstrap/legacy_provider_scope.dart†L23-L120】

## 3. TapemMaterialApp (Endpunkt des Bootstraps)
- `TapemMaterialApp` konsumiert bereits aufgebaute Provider-Zustände (`ThemeLoader`, `AppProvider`, `OverlayNumericKeypadController`) und
  liefert den finalen `MaterialApp`. Weitere Riverpod-Scopes treten hier nicht auf; alle Widgets konsumieren die zuvor aufgespannten
  Provider-Instanzen.【F:lib/core/app/tapem_app.dart†L29-L65】

## 4. LegacyProviderScope (Provider-Hierarchie)
- **Brückenknoten:** Der Scope konvertiert Riverpod-Abhängigkeiten (`sharedPreferencesProvider`, `membershipServiceProvider`,
  `gymScopedStateControllerProvider`, `authControllerProvider`, `brandingProvider`, `gymProvider`) in Provider-Pendants, bevor
  Feature-spezifische ChangeNotifier registriert werden.【F:lib/bootstrap/legacy_provider_scope.dart†L23-L120】
- **Registrierungs-Reihenfolge:** Gym-/Auth-kritische Provider werden zuerst erzeugt, danach folgen Feature-Domänen wie Geräte, Freunde,
  Reports, Powerlifting oder Trainingspläne. Diese Reihenfolge stellt sicher, dass Proxy-Provider (`ThemeLoader`, `WorkoutDayController`)
  ihre Abhängigkeiten vollständig injiziert bekommen.【F:lib/bootstrap/legacy_provider_scope.dart†L51-L380】

## 5. End-to-End-Flow (Bootstrap → UI)
1. `bootstrapApp()` initialisiert Firebase, Push, Avatar-Katalog sowie Report-UseCases und liefert die Overrides für SharedPreferences und
   Reporting an die App zurück.【F:lib/bootstrap/bootstrap.dart†L19-L74】
2. `main.dart` spannt mit diesen Overrides einen globalen `ProviderScope` und rendert `TapemApp`. Dadurch stehen SharedPreferences,
   DeviceUsageStats und LogTimestamps schon vor der Legacy-Provider-Initialisierung zur Verfügung.【F:lib/main.dart†L9-L16】
3. `TapemApp` legt `LegacyProviderScope` um `TapemMaterialApp`, sodass sämtliche Legacy-Provider (inklusive Auth/Gym) auf dieselben
   Riverpod-Instanzen zugreifen können.【F:lib/core/app/tapem_app.dart†L18-L65】
4. `TapemMaterialApp` nutzt die bereitgestellten Provider, um Theme, Locale und globale Listener zu konfigurieren. Weitere Scopes oder
   Brücken existieren nicht; Riverpod-Consumer außerhalb des Legacy-Scopes beziehen ihre Daten direkt aus dem äußeren ProviderScope.
   【F:lib/core/app/tapem_app.dart†L29-L65】

## 6. Heutiger State-Katalog (Riverpod-first vs. Provider-only)
### 6.1 Riverpod-first Zustände
- **Auth-Kern:** `gymScopedStateControllerProvider`, `authControllerProvider` und `authViewStateProvider` entstehen direkt in `bootstrap/providers.dart` und werden lebenszyklusgerecht via `ref.onDispose` verwaltet.【F:lib/bootstrap/providers.dart†L34-L90】
- **Branding & Gym:** `brandingProvider` und `gymProvider` sind native Riverpod-`ChangeNotifierProvider` und reagieren auf `AuthViewState`, wodurch Branding- und Gym-Daten zuerst in Riverpod landen und anschließend im LegacyScope gespiegelt werden.【F:lib/bootstrap/providers.dart†L91-L143】
- **Bootstrap-Abhängigkeiten:** `sharedPreferencesProvider`, `membershipServiceProvider`, `getDeviceUsageStatsProvider` und `getAllLogTimestampsProvider` werden durch `BootstrapResult.toOverrides()` gesetzt und bilden die Brücke zu Infrastruktur-Ressourcen.【F:lib/bootstrap/providers.dart†L18-L33】【F:lib/bootstrap/bootstrap.dart†L19-L41】

### 6.2 Provider-only Zustände
- **Geräte & Übungen:** NFC-Service, Device-/Exercise-Repositories sowie sämtliche Device-UseCases existieren ausschließlich als Provider-Registrierungen innerhalb des Legacy-Scopes.【F:lib/bootstrap/legacy_provider_scope.dart†L122-L170】
- **Freunde & Kommunikation:** Friend-APIs, Chat-Sources, Alerts und Präsenzmanager leben komplett im Provider-Ökosystem und hängen transitive auf Firestore/Provider-Kontext.【F:lib/bootstrap/legacy_provider_scope.dart†L179-L217】
- **Workout-/Session-Services:** Keypad, Timer, StorySessionService, ThemeLoader, WorkoutSessionDurationService und WorkoutDayController bleiben Provider-only und beziehen Auth-/Branding-Daten via `ChangeNotifierProxyProvider`-Ketten.【F:lib/bootstrap/legacy_provider_scope.dart†L218-L307】
- **Analytics & Training:** TrainingPlan-, RestStats-, History-, Profile-, Powerlifting-, Exercise- und ReportProvider sowie Survey/Feedback leben ausschließlich im LegacyScope.【F:lib/bootstrap/legacy_provider_scope.dart†L309-L383】

## 7. SOLL: Migration zu nativen Riverpod-Providern (Prioritäten)
1. **Priorität A – Reporting & Analytics:**
   - `ReportProvider`, `SurveyProvider`, `FeedbackProvider` und `RankProvider` hängen nur von SharedPreferences, Report-UseCases bzw. Firestore ab und lassen sich deshalb zuerst in Riverpod-`Notifier`- oder `ChangeNotifierProvider`-Instanzen verschieben. Diese Provider können dieselben Bootstrap-Overrides (`sharedPreferencesProvider`, `getDeviceUsageStatsProvider`, `getAllLogTimestampsProvider`) verwenden, sodass nur Konsumenten angepasst werden müssen.【F:lib/bootstrap/legacy_provider_scope.dart†L374-L383】【F:lib/bootstrap/providers.dart†L18-L41】
   - Schritte: (a) neuen Riverpod-Provider im jeweiligen Feature-Ordner anlegen, (b) Abhängigkeiten via `ref.watch(...)` injizieren, (c) Legacy-Provider-Registrierung entfernen und Widgets auf `ref.watch` umstellen.
2. **Priorität B – Geräte & Übungen:**
   - NFC-, Device- und Exercise-Stacks sind stark vernetzt (`DeviceRepository`, diverse UseCases, `ExerciseProvider`, `AllExercisesProvider`). Die Migration startet mit Repository-/UseCase-Providern, die Firestore-Instanzen direkt aus Riverpod beziehen. Anschließend werden `ExerciseProvider` und `AllExercisesProvider` als `ChangeNotifierProvider` in Riverpod neu erstellt, bevor UI-Controller wie `WorkoutDayController` umgestellt werden.【F:lib/bootstrap/legacy_provider_scope.dart†L122-L370】
   - Schritte: (a) neue Riverpod-Provider für Repositories/UseCases im Geräte-Feature definieren, (b) `WorkoutDayController` in Riverpod heben und Abhängigkeiten über `ref.watch` beziehen, (c) zuletzt UI-spezifische Provider wie `OverlayNumericKeypadController` migrieren.
3. **Priorität C – Freunde & Kommunikation:**
   - Friend- und Chat-Provider können nach Stabilisierung der Geräte-Domäne migriert werden, indem Firestore-Sources als Riverpod-Provider gekapselt werden und `FriendsProvider`/`FriendPresenceProvider` ihre Streams via `ref.listen` aktualisieren.【F:lib/bootstrap/legacy_provider_scope.dart†L179-L217】
   - Schritte: (a) Firestore-Sources als `Provider`/`StreamProvider` neu aufsetzen, (b) Business-Notifiers nach Riverpod portieren, (c) Consumer-Widgets im Friends-Feature schrittweise auf `ref.watch` umstellen.
4. **Priorität D – Restliche Legacy-Services:**
   - Nach Abschluss der Kernmigration werden verbleibende Helper (`ThemeLoader`, `WorkoutSessionDurationService`, `TrainingPlanProvider`, `HistoryProvider` etc.) in Riverpod überführt. Fokus liegt auf Services mit geringen externen Abhängigkeiten, um `LegacyProviderScope` langfristig auf UI-nahe Controller zu reduzieren.【F:lib/bootstrap/legacy_provider_scope.dart†L218-L383】

## 8. Einbindung & Tests neuer States
1. **Provider-basiertes Onboarding:**
   - Solange ein State im LegacyScope verbleibt, muss er weiterhin im `providers`-Array registriert und – falls gym-abhängig – beim `GymScopedStateController` angemeldet werden.【F:lib/bootstrap/legacy_provider_scope.dart†L51-L305】
2. **Riverpod-Onboarding:**
   - Neue Riverpod-States ziehen Infrastruktur ausschließlich aus `bootstrap/providers.dart`. Ein zusätzlicher Scope ist nicht nötig; der bestehende globale `ProviderScope` liefert SharedPreferences, MembershipService, Auth-, Branding- und Gym-Instanzen bereits aus.【F:lib/bootstrap/providers.dart†L18-L143】【F:lib/main.dart†L9-L16】
   - Legacy-Widgets, die noch `context.watch` nutzen, greifen über `LegacyProviderScope` auf dieselben Instanzen zu. Während der Migration sollten Adapter-Widgets (z. B. `ProviderListener`) Tests abdecken, damit Provider- und Riverpod-Zweig identische Daten erhalten.
3. **Tests:**
   - **Unit:** Gym-sensitive Riverpod-Provider mocken `authViewStateProvider` und `gymScopedStateControllerProvider`, um Reset-Szenarien abzudecken.【F:lib/bootstrap/providers.dart†L34-L143】
   - **Widget:** Integrationstests rendern `ProviderScope(overrides: bootstrapResult.toOverrides())` + `LegacyProviderScope`, triggern Gym-Wechsel über `authControllerProvider` und prüfen, dass sowohl `context.watch`- als auch `ref.watch`-Consumer aktualisiert werden.【F:lib/main.dart†L9-L16】【F:lib/bootstrap/legacy_provider_scope.dart†L23-L383】
   - **Golden/Feature:** Firestore-intensive Domains (Community, Friends) benötigen Tests, die Stream-Abos bei Gym-Wechsel schließen. Hierfür Riverpod-`ProviderContainer` einsetzen und Mock-Sources injizieren.

## 9. Override-Governance (ohne zusätzliche Bridge)
- Die einzigen Overrides entstehen aktuell in `BootstrapResult.toOverrides()`; sie werden beim App-Start in den äußeren `ProviderScope` injiziert und stehen Riverpod wie Provider gleichermaßen zur Verfügung.【F:lib/bootstrap/bootstrap.dart†L19-L41】【F:lib/main.dart†L9-L16】
- `LegacyProviderScope` darf ausschließlich auf diese Overrides zugreifen und konvertiert sie in Provider-Instanzen. Neue Overrides müssen deshalb zentral im Bootstrap ergänzt werden, damit sowohl Riverpod- als auch Provider-Welt konsistent bleiben.【F:lib/bootstrap/legacy_provider_scope.dart†L23-L120】
- Sobald ein Legacy-Service nach Riverpod migriert wurde, wird seine Registrierung aus dem `providers`-Array entfernt und (falls nötig) durch einen Adapter ersetzt. Jede Entfernung sollte von Tests begleitet werden, die Auth-/Gym-Wechsel simulieren, damit kein State aus dem Override-Verbund herausfällt.

## 10. Fortschritt (Rest- & History-Stats 2024-04)
- `RestStatsProvider` und `HistoryProvider` leben jetzt vollständig als Riverpod-`ChangeNotifierProvider` in ihren Feature-Ordnern (`lib/features/rest_stats/providers/rest_stats_provider.dart`, `lib/features/history/providers/history_provider.dart`). Beide registrieren sich direkt beim `gymScopedStateControllerProvider` und hören via `ref.listen(authViewStateProvider, …)` auf Gym- und User-Wechsel, wodurch ihre Streams beim Logout sauber geschlossen werden.【F:lib/features/rest_stats/providers/rest_stats_provider.dart†L9-L214】【F:lib/features/history/providers/history_provider.dart†L1-L148】
- `LegacyProviderScope` spiegelt die beiden Provider nicht länger in die Provider-Welt, sodass neue Screens (`RestStatsScreen`, `ProfileStatsScreen`, `HistoryScreen`) direkt als `ConsumerWidget`/`ConsumerStatefulWidget` umgesetzt wurden und ausschließlich `ref.watch`/`ref.read` verwenden.【F:lib/bootstrap/legacy_provider_scope.dart†L200-L234】【F:lib/features/rest_stats/presentation/screens/rest_stats_screen.dart†L1-L196】【F:lib/features/profile/presentation/screens/profile_stats_screen.dart†L1-L116】【F:lib/features/history/presentation/screens/history_screen.dart†L1-L214】
- Unit-Tests (`test/features/rest_stats/providers/rest_stats_provider_test.dart`, `test/features/history/providers/history_provider_test.dart`) nutzen `ProviderContainer` mit Auth-/Gym-Overrides, simulieren Wechsel und stellen sicher, dass keine „used after dispose“-Fehler mehr auftreten, sobald der Kontext resettet wird.【F:test/features/rest_stats/providers/rest_stats_provider_test.dart†L1-L69】【F:test/features/history/providers/history_provider_test.dart†L1-L69】

## 11. Helper-Service Migration Checklist
- [x] **ThemeLoader** – konsumiert Branding- und Theme-Overrides direkt via `ref.watch`; der Legacy-Adapter wurde entfernt, sodass ausschließlich Riverpod-Consumer den Loader beziehen.【F:lib/core/theme/theme_loader.dart†L288-L305】【F:lib/bootstrap/legacy_provider_scope.dart†L137-L197】
- [ ] **ThemePreferenceProvider** – `LegacyProviderScope` markiert die verbleibende Brücke mit `TODO(legacy-state)` bis `SettingsScreen` auf Riverpod wechselt.【F:lib/bootstrap/legacy_provider_scope.dart†L149-L154】
- [ ] **SessionTimerService** – Timer-Bar nutzt weiterhin `provider`, entsprechend bleibt der Adapter mit `TODO(legacy-state)` bestehen.【F:lib/bootstrap/legacy_provider_scope.dart†L140-L147】
- [ ] **WorkoutSessionDurationService** – Riverpod-Provider existiert, aber Geräte-UI liest den Service noch über `provider`, daher `TODO(legacy-state)` im Legacy-Scope.【F:lib/bootstrap/legacy_provider_scope.dart†L161-L170】
- [ ] **WorkoutDayController** – Trainingsgeräte konsumieren den Controller weiterhin über `context.watch`, Migration wird nach Abschluss der Device-Refactors erledigt.【F:lib/bootstrap/legacy_provider_scope.dart†L165-L170】
- [ ] **TrainingPlanProvider** – Trainingsplan-Screens bleiben Provider-basiert, weshalb der Adapter mit `TODO(legacy-state)` markiert ist.【F:lib/bootstrap/legacy_provider_scope.dart†L167-L170】
- [ ] **ProfileProvider** – Profil-Widgets greifen noch über den Legacy-Scope zu; Dokumentation verweist auf die ausstehende Migration.【F:lib/bootstrap/legacy_provider_scope.dart†L168-L172】

## 12. Update (Mai 2024) – Riverpod-Ausrichtung & Legacy-Adapter
- **History- und Profile-Dienste:** `HistoryProvider` verfügt wieder über vollständige Private-Felder, Reset-/Dispose-Pfade und registriert sich weiterhin beim `gymScopedStateControllerProvider`. Gleichzeitig greifen `MuscleGroupProvider` und `ProfileProvider` via `legacy_provider.Provider.of` auf den Legacy-Scope zu, wodurch `flutter_riverpod`-Imports nicht länger mit `provider` kollidieren.【F:lib/features/history/providers/history_provider.dart†L1-L159】【F:lib/core/providers/muscle_group_provider.dart†L1-L375】【F:lib/core/providers/profile_provider.dart†L1-L160】
- **Feedback & Stats:** `FeedbackOverviewScreen` nutzt Riverpod für Lade- und Schreiboperationen, typisiert Geräte-Lookups und bindet das `gymProvider` explizit ein. `ProfileStatsScreen` liest dieselben Provider weiterhin über den LegacyScope, ist nun jedoch klar als Adapter dokumentiert und konsumiert Riverpod-Daten ausschließlich über `WidgetRef`.【F:lib/features/feedback/presentation/screens/feedback_overview_screen.dart†L1-L90】【F:lib/features/profile/presentation/screens/profile_stats_screen.dart†L1-L120】
- **Keypad-Adapter:** `overlay_numeric_keypad.dart` stellt das Controller-Objekt via Riverpod bereit, bindet jedoch `WorkoutDayController` über einen `legacy_provider`-Adapter ein und kennzeichnet diesen Zustand mit `TODO(legacy-state)`, bis die Geräte-Controller vollständig migriert wurden.【F:lib/ui/numeric_keypad/overlay_numeric_keypad.dart†L1-L460】

