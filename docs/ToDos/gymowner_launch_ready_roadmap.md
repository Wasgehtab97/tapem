# GymOwner Launch-Ready Roadmap (Soll-Zustand)

Stand: 2026-02-15

## Zielbild

Die App hat nur noch drei Rollen:
- `member`: Studiomitglied
- `gymowner`: Studiopersonal
- `admin`: App-Owner (du)

Der `gymowner` nutzt die Owner-Fläche als primären Arbeitsbereich für Studio-Operations (Mitglieder, Geräte, Nutzung, Feedback, Umfragen, Challenges, Deals/Branding sofern freigegeben).

## Architekturprinzipien (für sauber, nachhaltig, wartbar)

- Ein Rollen-Contract für Client, Backend, Rules, Claims und Tests.
- Fail-closed Security: Client-Guards sind UX, Firestore Rules sind Autorität.
- Thin UI, klare UseCases/Repos, keine Firestore-Logik in Screens.
- Aggregierte Reporting-Daten statt Rohlog-Vollscans.
- Einheitliche Zustände pro Screen: `loading`, `error`, `empty`, `ready`, `no-access`.
- Owner-first Informationsarchitektur: tägliche Studio-Tasks in einem klaren Arbeitsfluss.

## Relevanter Ist-Abgleich (aus Code)

- Rollen-Drift vorhanden (`gym_admin`, `global_admin` in Rules, aber nicht im Client-Modell):
  - `lib/core/auth/role_utils.dart`
  - `lib/core/providers/auth_provider.dart`
  - `firestore.rules`
- Owner ist aktuell ein zusätzlicher Tab, nicht klarer primärer Workspace:
  - `lib/features/home/presentation/screens/home_screen.dart`
  - `lib/features/home/presentation/widgets/owner_tab_navigator.dart`
  - `lib/features/home/presentation/screens/owner_screen.dart`
- Admin/Report sind funktional vorhanden, aber teilweise inkonsistent in Guarding/UX/Architektur:
  - `lib/features/admin/presentation/screens/*.dart`
  - `lib/features/report/presentation/screens/*.dart`
- Performance-Risiko im Reporting (N+1, Vollscan):
  - `lib/features/report/data/repositories/report_repository_impl.dart`
  - `lib/features/report/data/sources/firestore_report_source.dart`

## Soll-Architektur für GymOwner

### Rollen & Rechte

- `member`:
  - nur Member-Flows
  - kein Zugriff auf Owner/Admin-Flows
- `gymowner`:
  - gym-spezifische Studioverwaltung
  - volle Owner-Operations im aktiven Gym
  - keine globalen App-Owner-Rechte
- `admin`:
  - globale App-Administration
  - kann optional zusätzlich gymowner-ähnliche Sichten nutzen, aber als separater Kontext

### Navigationsmodell

- Für `gymowner` ist Owner-Workspace die erste und zentrale Startfläche.
- Report/Admin-Teilfunktionen werden als Owner-Module geführt (nicht als verstreute Entry-Points).
- Klare Modulnavigation im Owner:
  - Studio Cockpit
  - Mitglieder
  - Geräte
  - Feedback
  - Umfragen
  - Challenges
  - Deals/Branding (falls im Produkt-Scope)

### Datenmodell

- Operative Kennzahlen als Aggregates/Read-Modelle (daily/weekly), nicht live aus Rohlogs zusammengesetzt.
- Kritische Admin-Aktionen im No-Functions-Modus als Rules-gesicherte Client-Flows mit Audit-Trace (serverseitige Commands bewusst später).
- Gym-scoped Datenhoheit für gymowner; globale Collections nur dort global, wo fachlich zwingend.

## Roadmap-Checkliste

## Phase 0: Rollen-Fundament und Sicherheitsklarheit

### Tasks
- [x] Rollen-Contract festlegen: nur `member`, `gymowner`, `admin` (Doku + technische Konvention).
- [x] Client-Rollenauflösung auf den Contract vereinheitlichen (`role_utils`, `auth_provider`, route/tabs policy).
- [x] Firestore Rules auf denselben Contract bereinigen (inkl. Entfernung/Mapping von `gym_admin`, `global_admin`).
- [x] Claims- und Datenmigration planen: bestehende Nutzerrollen deterministisch migrieren.
- [x] Alle Owner/Admin-Screens mit konsistentem Guard-Wrapper absichern (No-Access-UI standardisieren).
- [x] Kritische Actions (z. B. Mitglied entfernen, sensible Bulk-Operationen) im No-Functions-Modus Rules-sicher clientseitig umsetzen.

### Akzeptanzkriterien
- [x] Es existiert nur noch ein aktives Rollenmodell ohne Alias-Wildwuchs.
- [x] Keine Divergenz zwischen Client-Verhalten und Rules-Autorisierung.
- [x] Unautorisierte Zugriffe sind UI- und Rules-seitig konsistent blockiert.

### Risiken
- [x] Migrationsfehler bei Bestandsnutzern (falsche Rolle nach Rollout) mitigiert durch `functions/scripts/migrate_roles_phase0.js` + Dry-Run/Apply-Runbook.
- [x] Übergangsphase mit Legacy-Tokens mitigiert durch Claims-Refresh-Runbook (`docs/ToDos/phase0_roles_migration.md`).

### Abschlussstand (2026-02-16)
- Rollen-/Guard-Implementierung, Rules-Hardening und clientseitiger Remove-Flow sind produktiv vorbereitet.
- Remove-Flow `GymUserRemovalService` ist Rules-gesichert und auditiert (ohne Callable-Abhängigkeit).
- Firestore-Rollenmatrix ist als eigener Emulator-Test abgesichert (`tests/rules/phase0_roles.test.js`, Script: `npm run test:rules:phase0`).
- Bei der Abnahme wurde eine echte Cross-Gym-Eskalation in Rules gefunden und geschlossen (gymowner durfte vorher in fremdem Gym schreiben, sobald Membership existierte).

## Phase 1: Owner als Main Workspace (IA + UX)

### Tasks
- [x] Owner für `gymowner` als Default-Startpunkt definieren (nicht nur zusätzlicher Tab).
- [ ] Owner-Cockpit mit klarer Tagesstruktur aufbauen:
- [x] KPI-Topline (Mitglieder aktiv/inaktiv, Geräteauslastung, offene Feedbacks, offene Umfragen, aktive Challenges).
- [x] Aufgabenliste „Heute“ (z. B. offene Feedbacks, auslaufende Deals, fehlende Gerätedaten).
- [x] Schnellaktionen mit klaren Resultaten (Gerät anlegen, Umfrage starten, Challenge anlegen).
- [x] Navigationsduplikate reduzieren: gleiche Funktionen nur über einen klaren Pfad erreichbar machen.
- [x] Einheitliche Zustandskomponenten einführen: loading/error/empty/no-access.
- [x] Einheitliche Interaktionsmuster für destructive actions (Confirm, Undo wo sinnvoll, Audit-Hinweis).

### Akzeptanzkriterien
- [ ] GymOwner kann alle Studio-Kernaufgaben ohne Kontextwechsel-Chaos aus dem Owner-Workspace erledigen.
- [ ] Kein redundantes/inkonsistentes Routing zwischen Owner/Admin/Report-Flächen.
- [ ] UX ist mobil stabil nutzbar (keine rein desktopartigen Tabellen-Engpässe).

### Risiken
- [ ] IA-Umbau kann Gewohnheitsbruch für bestehende GymOwner verursachen.

### Zwischenstand (2026-02-16)
- Owner-Workspace startet für `gymowner` jetzt als Default-Home-Einstieg.
- Neues Owner-Cockpit liefert KPI-Topline, „Heute priorisieren“-Taskliste und modulare Schnellaktionen.
- Loading/Error/Empty/No-Access-Zustände sind im Owner-Workspace vereinheitlicht.
- GymOwner-Tab-Policy wurde auf Owner-zentrierte Navigation reduziert (Owner statt parallele Rank/Deals-Tab-Navigation).
- Destructive Actions sind über zentrale Patterns vereinheitlicht:
  - Confirm + Audit-Hinweis bei irreversiblen Aktionen (z. B. Remove User, Device Delete).
  - Undo bei reversiblen Aktionen (z. B. Deal löschen, Hersteller entfernen, Feedback erledigen, Umfrage schließen).

## Phase 2: Funktionshärtung pro Owner-Modul

### Mitglieder
- [x] Remove/Manage-Flows fachlich korrekt und dauerhaft machen (inkl. `users/{uid}.gymCodes` Konsistenz).
- [x] Segmentierung und Bulk-Aktionen mit sicheren Guardrails.
- [x] Klare Auditbarkeit bei administrativen Änderungen.

### Geräte
- [x] Create/Edit/Delete via robuste UseCases (kein race-prone `max+1` ID-Pattern).
- [x] Geräte-Formulare validieren und vereinheitlichen.
- [x] Herstellerverwaltung klar gym-scoped, globales Seeding nur serverseitig.

### Reports & Insights
- [x] Aggregationspipeline einführen (kein N+1/Vollscan als Standardpfad).
- [x] KPI-Definitionen fachlich korrigieren (z. B. „Gesamt“-Zeiträume).
- [x] Drilldown-Pfade paginieren und performance-budgetieren.

### Feedback/Umfragen/Challenges
- [x] Subscription-Lifecycle robust machen (keine gegenseitige Listener-Abschaltung).
- [x] Owner-Workflows auf „offen -> bearbeiten -> erledigt/geschlossen“ standardisieren.
- [x] Einheitliche SLA/Statusdarstellung im UI.

### Akzeptanzkriterien
- [x] Jeder Owner-Kernflow ist stabil, berechtigt, auditierbar und auf mobile nutzbar.
- [x] Keine bekannten P0/P1-Inkonsistenzen in Daten-/Rollenlogik.

### Risiken
- [x] Reporting-Refactor kann initial KPI-Abweichungen verursachen, wenn Backfill fehlt.

### Abschlussstand (2026-02-16)
- Report-Pipeline auf Daily-Read-Model umgestellt (`gyms/{gymId}/reportDaily/*`) mit Legacy-Fallback.
- No-Functions-Modus aktiv: Owner/Admin-Kernflows funktionieren ohne Cloud Functions; Functions-Trigger bleiben optional für späteres Hardening.
- Globaler Callable-Toggle eingebaut: `ENABLE_CLOUD_FUNCTIONS=false` ist Standard (`lib/bootstrap/firebase.dart`), spätere Aktivierung bewusst per `--dart-define=ENABLE_CLOUD_FUNCTIONS=true`.
- Device-ID-Vergabe auf transaktionsbasierten Counter migriert (`deviceNumberCounter` statt `max+1`).
- Survey-Subscription-Lifecycle auf subscriber-basiertes Handling gehärtet (kein gegenseitiges Canceln mehr).
- Members-Segment-Aktionen mit Guardrails und Audit-Logging versehen.
- Globales Hersteller-Seeding aus UI entfernt; globaler Herstellerkatalog nur noch app-admin-schreibbar in Rules.
- Gym-User-Removal läuft clientseitig (Rules-gesichert + Best-Effort-Cleanup + Audit), kein Callable-Blocker mehr.
- Firestore-Rule-Suiten sind für den aktuellen Rollen-/Avatar-Contract grün (`npm run test:rules:phase0` und `npm run test:rules`), inklusive Anti-Bypass-Härtung bei `/users/{uid}`-Fallback.

## Phase 3: Performance, Wartbarkeit, Testabdeckung

### Tasks
- [x] Presentation/Domain/Data sauber trennen in allen Owner/Admin/Report-Modulen.
- [x] Direkte Firestore-Aufrufe aus UI in UseCases/Repositories verlagern.
- [x] Query-Budgets und Performance-Ziele pro Screen definieren und messen.
- [x] Testpyramide ausbauen:
- [x] Unit: Rollenauflösung, UseCases, Aggregationslogik.
- [x] Widget: Owner-Cockpit, Error-/No-Access-Zustände als regressionssichere Tests.
- [x] Integration: End-to-End Owner-Kernflows.
- [x] Rule-Tests: Rollenmatrix (`member`, `gymowner`, `admin`) und kritische Collections.
- [x] Observability ergänzen: action success rate, latency, permission-denied rate, failed command rate.

### Akzeptanzkriterien
- [x] Kritische Owner-Flows sind automatisiert getestet.
- [ ] Performance-Budgets werden in realistischen Gym-Datengrößen eingehalten.
- [ ] Änderungen sind ohne regressionsanfällige Seiteneffekte weiterentwickelbar.

### Risiken
- [ ] Ohne feste Metriken bleibt „Launch-Ready“ subjektiv.

### Zwischenstand (2026-02-16)
- Owner-Workspace ist lokalisiert (Header, KPI-/Tasks-/Quick-Action-Sektionen, State- und Task-Texte), harte Strings in diesen Komponenten wurden entfernt.
- Widget-Tests decken zentrale Owner-States ab: `no-access`, `missing-gym-context`, `load-error` (`test/features/home/presentation/screens/owner_screen_test.dart`).
- Stabilitätsfix umgesetzt: `OwnerScreen` nutzt in `dispose()` keine `ref.read(...)`-Zugriffe mehr (verhindert Dispose-Race im Widget-Lifecycle).
- Unit-Absicherung für Aggregationslogik ergänzt:
  - `test/features/report/data/repositories/report_repository_impl_test.dart` (Aggregate-Read-Model + Legacy-Fallback + Since-Filter).
  - `test/features/home/application/owner_workspace_provider_test.dart` (Owner-KPI-Snapshot + aktive Challenges).
- Integrationsnahe Absicherung für kritischen Owner-Flow ergänzt:
  - `test/features/admin/data/services/gym_user_removal_service_test.dart` (Detachment von `users/{uid}.gymCodes`, Best-Effort-Cleanup über Geräte/Maschinen, Audit-Write, Not-Found-Fall).
  - `test/features/admin/presentation/screens/admin_remove_users_screen_test.dart` (No-Access-State + Confirm/Delete-Flow über UI inkl. Membership-Detach und Audit-Write).
- Rules-Suite für kritische Owner/Admin-Collections erweitert (läuft im Standardlauf `npm run test:rules`):
  - `tests/rules/run.js` deckt jetzt zusätzlich `surveys`, `feedback`, `reportDaily` (read-only) und `adminAudit` inkl. Cross-Gym-Blockierung ab.
- Owner/Admin-Command-Observability eingeführt:
  - `lib/core/observability/owner_action_observability_service.dart` erfasst pro Action `attempts`, `successes`, `failures`, `permissionDenied`, `avgLatencyMs`, `successRate`, `failedCommandRate`, `permissionDeniedRate`.
  - Kritische Flows sind instrumentiert: `owner.remove_user_from_gym`, `owner.challenges.create`, `owner.deals.create/update/toggle_active/delete/undo_delete`.
  - Testabdeckung ergänzt: `test/core/observability/owner_action_observability_service_test.dart` + erweiterte Assertions in `test/features/admin/data/services/gym_user_removal_service_test.dart`.
- UI/Architektur-Entkopplung weitergeführt (direkte Firestore-Aufrufe reduziert):
  - Challenge-Create aus Screen in Data-Service verlagert: `lib/features/admin/data/services/challenge_admin_service.dart` + Nutzung in `lib/features/admin/presentation/screens/challenge_admin_screen.dart`.
  - Mitglieder-Streams in Report-Screens in Repository verlagert: `TrainingDayRepository.watchGymMembers(...)` nutzt Data-Layer statt Screen-Queries (`report_members_screen.dart`, `report_members_usage_screen.dart`).
  - Neue Data-Layer-Tests: `test/features/admin/data/services/challenge_admin_service_test.dart` und `test/features/report/data/training_day_repository_test.dart`.
- Weitere Owner/Admin-Screen-Entkopplung umgesetzt:
  - Branding-Write-Flow in Service verlagert: `lib/features/admin/data/services/branding_admin_service.dart` + Screen-Nutzung in `lib/features/admin/presentation/screens/branding_screen.dart` (inkl. Audit + Observability).
  - Gym-Mitgliederverzeichnis in Service verlagert: `lib/features/admin/data/services/gym_member_directory_service.dart`; genutzt in `admin_symbols_screen.dart` und `admin_remove_users_screen.dart` statt direkter Screen-Firestore-Queries.
  - `user_symbols_screen.dart` nutzt für Namensauflösung jetzt ebenfalls den Directory-Service (`watchDisplayName`) statt direktem User-Doc-Stream im Screen; zusätzlich wurde ein nicht benötigter Membership-Debug-Read entfernt.
  - Neue Service-Tests: `test/features/admin/data/services/branding_admin_service_test.dart` und `test/features/admin/data/services/gym_member_directory_service_test.dart`.
  - Zusätzlicher Widget-Regressionstest für Admin-Symbol-Flow: `test/features/admin/presentation/screens/admin_symbols_screen_test.dart` (No-Access + Filter + Navigation).
- Query-Budget-Observability für Owner-/Report-Reads ergänzt:
  - Neues Budget-Tracking: `lib/core/observability/owner_query_budget_service.dart` (`runs`, `failures`, `budgetBreaches`, `avgQueries`, `avgDocsRead`, `avgLatencyMs` pro Flow).
  - Instrumentierte Flows:
    - `owner.workspace.snapshot` in `lib/features/home/application/owner_workspace_provider.dart`
    - `owner.report.usage_stats` und `owner.report.heatmap_timestamps` in `lib/features/report/data/repositories/report_repository_impl.dart`
    - `owner.report.members_training_day_counts` in `lib/features/report/data/training_day_repository.dart`
  - Testabdeckung ergänzt:
    - `test/core/observability/owner_query_budget_service_test.dart`
    - `test/features/home/application/owner_workspace_provider_test.dart`
    - `test/features/report/data/repositories/report_repository_impl_test.dart`
    - `test/features/report/data/training_day_repository_test.dart`
- Owner-Quick-Actions wurden teststabil vorbereitet:
  - Stabile Widget-Keys für Quick-Actions hinzugefügt (`lib/features/home/presentation/widgets/owner/owner_hub_sections.dart`), um route-/flow-nahe Widget-Tests robust zu machen.
- Report-Members-Flow wurde auf Provider-basierte Data-Layer-Injection umgestellt (keine Repository-Instanziierung im UI):
  - `lib/features/report/providers/report_providers.dart` ergänzt `trainingDayRepositoryProvider`.
  - `lib/features/report/presentation/screens/report_members_screen.dart` nutzt Repository per Provider/DI.
  - `lib/features/report/presentation/screens/report_members_usage_screen.dart` nutzt Repository per Provider/DI.
- Integrationsnahe Widget-Absicherung für Report-Members-Flow ergänzt:
  - `test/features/report/presentation/screens/report_members_flow_test.dart` deckt Members-Tabelle + Segment-Actions sowie Usage-Buckets über echte Screen-Flows ab.
- Lifecycle-Härtung in Provider-Ebene umgesetzt:
  - Double-Dispose-Fehler behoben durch Entfernen redundanter `ref.onDispose(...dispose)`-Aufrufe in
    - `lib/features/report/providers/report_providers.dart`
    - `lib/core/providers/gym_scoped_resettable.dart`
  - `test/features/report/report_provider_test.dart` läuft danach stabil grün.
- Letzter Firestore-Instanz-Fallback aus der Presentation-Schicht entfernt:
  - `lib/features/admin/presentation/screens/admin_remove_users_screen.dart` nutzt Service-Provider (`lib/features/admin/providers/admin_service_providers.dart`) statt direkter Firestore-Instanzierung.
- Mobile-UX im Members-Report verbessert (kein erzwungenes Horizontal-Scrolling auf kleinen Screens):
  - `lib/features/report/presentation/screens/report_members_screen.dart` rendert auf schmalen Viewports eine responsive Karten-/Listenansicht statt `DataTable`.
  - Verhalten ist über Widget-Test abgesichert (`test/features/report/presentation/screens/report_members_flow_test.dart`).
- Vollständige Lokalisation in Owner/Admin/Report weiter geschlossen:
  - Harte UI-Strings aus `admin_deals_screen.dart`, `admin_symbols_screen.dart`, `user_symbols_screen.dart`, `device_form_dialog.dart`, `challenge_admin_screen.dart`, `report/presentation/widgets/device_usage_chart.dart` und `report/presentation/widgets/calendar_heatmap.dart` entfernt.
  - Neue l10n-Keys ergänzt (u. a. Deal-Fehler/Undo-Texte, Symbols-Backfill/Inventory-Texte, Device-Name-Hint, Calendar-Heatmap-Tap-Feedback).
- Admin-Symbol-Screens weiter entkoppelt:
  - `admin_symbols_screen.dart` und `user_symbols_screen.dart` nutzen Service-Provider (`admin_service_providers.dart`) als Standardpfad statt direkter Service-Neuerstellung in der UI.
- Action-Feedback im Deals-Flow verbessert:
  - Success-Snackbars für Create/Update und Active/Inactive-Toggle ergänzt (`lib/features/admin/presentation/screens/admin_deals_screen.dart`).
  - L10n-Keys für Deal-Status-/Success-Feedback ergänzt (`lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`).
- Accessibility-Basics in Owner/Admin/Report umgesetzt:
  - Owner-Workspace-Komponenten mit zusätzlicher Semantik gehärtet (Header-/Section-Markierung, KPI-/Task-/Quick-Action-Beschriftung) in `lib/features/home/presentation/widgets/owner/owner_hub_sections.dart`.
  - Tastatur-/Fokus-Navigation verbessert via `FocusTraversalGroup` in `lib/features/home/presentation/screens/owner_screen.dart` und `lib/features/report/presentation/screens/report_members_screen.dart`.
  - Report-Member-Segmentaktionen und Segmentfilter mit Tooltip-/Semantik-Labels ergänzt (`lib/features/report/presentation/screens/report_members_screen.dart`).
  - Admin-Deals-Interaktionen mit Tooltip-/Toggle-Semantik ergänzt (`lib/features/admin/presentation/screens/admin_deals_screen.dart`).
  - Regressionsabsicherung grün: `test/features/home/presentation/screens/owner_screen_test.dart`, `test/features/report/presentation/screens/report_members_flow_test.dart`.

## UI/UX Verbesserungsleitlinien (verbindlich)

- [ ] Informationsdichte priorisieren: zuerst „Was ist heute wichtig?“, danach Details.
- [ ] Mobile-first: keine Kernaktion darf horizontales Tabellen-Scrolling erzwingen.
- [ ] Konsistente Komponentenbibliothek für Owner-Aktionen, Status-Chips, KPI-Cards, Confirm-Dialoge.
- [ ] Klare Rückmeldung nach jeder Aktion (Erfolg, Fehlerursache, nächster Schritt).
- [x] Vollständige Lokalisierung: keine harten Strings in Owner/Admin/Report.
- [x] Accessibility-Basics: Kontrast, Semantik, Fokusführung, Touch-Targets.

## Optimierungsvorschläge (über Mindestziel hinaus)

- [ ] „Owner Inbox“ einführen: priorisierte Aufgabenliste mit due dates und Verantwortlichkeit.
- [ ] Rollenspezifische Feature-Toggles pro Gym (kontrollierter Rollout neuer Owner-Funktionen).
- [ ] Event-/Audit-Feed für Admin-Aktionen zur Nachvollziehbarkeit bei Teams.
- [ ] Read-Model Cache für Owner-Cockpit (schneller erster Paint bei App-Start).

## Definition of Launch-Ready (GymOwner)

Launch-ready ist erreicht, wenn alle Punkte erfüllt sind:
- [ ] Rollenmodell ist final auf `member`/`gymowner`/`admin` vereinheitlicht.
- [ ] Owner ist der primäre, effiziente Workspace für Studiopersonal.
- [ ] Alle Owner-Kernflüsse sind sicher, robust, mobil nutzbar und fachlich korrekt.
- [ ] Reporting ist performant ohne Rohdaten-Vollscan als Standard.
- [ ] Kritische Flows sind durch Rule-, Widget- und Integrationstests abgesichert.
- [ ] Monitoring zeigt stabile Produktionsqualität über mindestens einen vollständigen Release-Zyklus.
