# Owner/Admin Area Current State Audit

Stand: 2026-02-15  
Scope: GymOwner/Admin Bereich (Rollen/Permissions, Owner/Home, Report, Admin, Navigation, Datenflüsse, UX/UI, Performance, Security, Tests)

## Executive Summary

Der Owner/Admin-Bereich ist funktional breit vorhanden, aber noch nicht launch-ready in Stabilität, Skalierung und Sicherheitsklarheit.

Kernaussagen:
- Ein kritischer Delete-Flow (`AdminRemoveUsers`) ist fachlich inkonsistent: Mitgliedschaften werden gelöscht, aber die zentrale Gym-Zuordnung am User bleibt bestehen.
- Der Report-Stack skaliert derzeit schlecht (N+1-Reads, Vollscans über Device-Logs).
- Rollenmodell und Guards sind clientseitig nicht konsistent mit den Firestore Rules (`gym_admin`, `global_admin` vs. `admin`, `gymowner`).
- UI-/Architekturqualität ist uneinheitlich (teilweise Screen-Logik direkt gegen Firestore, viele harte Strings, begrenzte mobile Tabellen-UX).
- Testabdeckung ist für Owner/Admin/Report-Flows deutlich unter Launch-Anforderung.

## Harte Annahmen (explizit)

1. Es wird angenommen, dass `firestore.rules` (prod) und `firestore-dev.rules` semantisch identisch betrieben werden.
2. Es wird angenommen, dass `gym_admin` und/oder `global_admin` in der Praxis genutzt werden oder kurzfristig genutzt werden können (Rules unterstützen das bereits).
3. Es wird angenommen, dass Gym-Admin-Aktionen (User entfernen, Deals/Manufacturers pflegen) gym-spezifisch und nachvollziehbar sein sollen.
4. `deals` werden als globaler Katalog behandelt; falls stattdessen gym-spezifische Isolation gewünscht ist, steigt die Priorität der entsprechenden Security-Themen.

---

## Ist-Zustand Architektur

### Rollen, Routing, Access
- Rollen-Tiering im Client läuft über `UserAccessTier` und `isAdminLikeRole`:
  - `lib/core/auth/role_utils.dart`
  - `lib/core/providers/auth_provider.dart`
- Route-Schutz für Member erfolgt primär über `AppRouter.shouldRedirectRestrictedRoute(...)` + `FF.limitTabsForMembers`:
  - `lib/app_router.dart`
  - `lib/core/config/feature_flags.dart`
- `GymContextGuard` schützt nur Gym-Kontext, nicht Rollenrechte:
  - `lib/core/widgets/gym_context_guard.dart`

### Owner/Home
- Owner-Einstieg ist als eigener Tab-Navigator implementiert:
  - `lib/features/home/presentation/widgets/owner_tab_navigator.dart`
  - `lib/features/home/presentation/screens/owner_screen.dart`
  - `lib/features/home/presentation/widgets/owner/owner_hub_sections.dart`
- Owner-Hub verlinkt in Report/Admin, enthält Feature-Flag-Varianten (legacy/v1/v2).

### Report-Stack
- UI:
  - `lib/features/report/presentation/screens/report_screen.dart`
  - `lib/features/report/presentation/screens/report_screen_new.dart`
  - `lib/features/report/presentation/screens/report_usage_screen.dart`
  - `lib/features/report/presentation/screens/report_members_screen.dart`
  - `lib/features/report/presentation/screens/report_members_usage_screen.dart`
  - `lib/features/report/presentation/screens/report_feedback_screen.dart`
  - `lib/features/report/presentation/screens/report_surveys_screen.dart`
- State/Domain:
  - `lib/core/providers/report_provider.dart`
  - `lib/features/report/providers/report_providers.dart`
  - `lib/features/report/data/repositories/report_repository_impl.dart`
  - `lib/features/report/data/sources/firestore_report_source.dart`
  - `lib/features/report/data/training_day_repository.dart`
- Verknüpfte Flows:
  - Surveys: `lib/features/survey/survey_provider.dart` + Survey-Screens
  - Feedback: `lib/features/feedback/feedback_provider.dart` + Feedback-Screens

### Admin-Stack
- Hub:
  - `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`
- Kern-Screens:
  - `lib/features/admin/presentation/screens/admin_devices_screen.dart`
  - `lib/features/admin/presentation/screens/admin_remove_users_screen.dart`
  - `lib/features/admin/presentation/screens/admin_symbols_screen.dart`
  - `lib/features/admin/presentation/screens/user_symbols_screen.dart`
  - `lib/features/admin/presentation/screens/admin_deals_screen.dart`
  - `lib/features/admin/presentation/screens/challenge_admin_screen.dart`
  - `lib/features/admin/presentation/screens/branding_screen.dart`
  - `lib/features/manufacturer/presentation/screens/manage_manufacturers_screen.dart`

### Firestore Rules Abhängigkeiten (Owner/Admin-relevant)
- Zentrale Rule-Funktionen und Rollenlogik:
  - `firestore.rules` (`isAdminLikeRole`, `isAdmin`, `isGlobalAdmin`, `activeGymId`)
- Kritische Collections:
  - `/gyms/{gymId}/users/{userId}`
  - `/users/{uid}`
  - `/gyms/{gymId}/devices/{deviceId}`
  - `/gyms/{gymId}/surveys/*`, `/gyms/{gymId}/feedback/*`
  - `/deals/{dealId}`
  - `/manufacturers/{manufacturerId}`

---

## Problemkatalog (P0/P1/P2)

## P0 (Launch-Blocker)

### P0-1: User-Remove Flow ist nicht dauerhaft wirksam
- Problem:
  - `AdminRemoveUsersScreen` löscht gym-spezifische Membership-/Leaderboard-Daten, entfernt aber **nicht** dauerhaft die Gym-Zuordnung in `users/{uid}.gymCodes`.
  - In der Funktion wird `gymCodes` lokal verändert, aber nicht persistiert.
- Auswirkung:
  - User bleibt logisch weiter dem Gym zugeordnet und kann durch Membership-Re-Sync wieder erscheinen.
  - UI verspricht „unwiderruflich gelöscht“, Verhalten ist faktisch inkonsistent.
- Betroffene Dateien:
  - `lib/features/admin/presentation/screens/admin_remove_users_screen.dart`
  - `lib/services/membership_service.dart`
  - `lib/core/providers/auth_provider.dart`
  - `firestore.rules` (Update-Limits auf `/users/{uid}`)
- Empfohlene Ziel-Lösung:
  - Entkoppelten serverseitigen „Remove Membership“-Pfad über Cloud Function einführen (atomar):
    1) `users/{uid}.gymCodes` aktualisieren,
    2) `gyms/{gymId}/users/{uid}` + Unterdaten löschen,
    3) Audit-Eintrag schreiben.
  - Client-Screen nur noch gegen diesen Command laufen lassen.
- Maßnahme-Typ:
  - Strukturell (kein Quick Win).

### P0-2: Report-Datenmodell skaliert nicht (N+1 + Vollscan)
- Problem:
  - Für jede Device-Statistik werden Logs je Device vollständig geladen (`fetchLogsForDevice` in Schleife).
  - Heatmap lädt alle Zeitstempel über alle Devices vollständig.
- Auswirkung:
  - Hohe Read-Kosten, Latenz und UI-Jank bei größeren Gyms.
  - Schlechte Launch-Skalierung bei wachsender Log-Historie.
- Betroffene Dateien:
  - `lib/features/report/data/repositories/report_repository_impl.dart`
  - `lib/features/report/data/sources/firestore_report_source.dart`
  - `lib/features/report/presentation/screens/report_usage_screen.dart`
- Empfohlene Ziel-Lösung:
  - Aggregationsmodell einführen (daily/hourly rollups pro Gym/Device), Report-UI auf Aggregates statt Rohlogs.
  - Nur Drilldown-Fälle laden Rohlogs paginiert.
- Maßnahme-Typ:
  - Strukturell.

---

## P1 (hoch)

### P1-1: Rollenmodell-Mismatch zwischen Client und Rules
- Problem:
  - Client `isAdminLikeRole` kennt nur `admin` und `gymowner`.
  - Rules kennen zusätzlich `gym_admin`; `global_admin` ist separat abgebildet.
- Auswirkung:
  - Potenziell legitime Admins serverseitig erlaubt, clientseitig aber als Member behandelt (Tabs/Routes/Guard-Verhalten).
- Betroffene Dateien:
  - `lib/core/auth/role_utils.dart`
  - `lib/core/providers/auth_provider.dart`
  - `firestore.rules`
  - `firestore-dev.rules`
- Empfohlene Ziel-Lösung:
  - Einheitliches Rollen-Vokabular als Shared Contract (Doku + Client-Mapping + Rule-Tests + Widget-Tests).
- Maßnahme-Typ:
  - Quick Win + strukturelles Hardening.

### P1-2: Mehrere Admin-Screens ohne expliziten Rollenguard
- Problem:
  - Nur `AdminDashboardScreen` enthält klaren `isAdmin`-Guard.
  - Andere Admin-Screens verlassen sich primär auf Routing/Feature-Flag-Gating.
- Auswirkung:
  - Bei zukünftigen Routing-/Flag-Änderungen können unautorisierte UI-Flows sichtbar werden (auch wenn Writes Rules-seitig scheitern).
- Betroffene Dateien:
  - `lib/features/admin/presentation/screens/admin_devices_screen.dart`
  - `lib/features/admin/presentation/screens/admin_deals_screen.dart`
  - `lib/features/admin/presentation/screens/challenge_admin_screen.dart`
  - `lib/features/admin/presentation/screens/branding_screen.dart`
  - `lib/features/manufacturer/presentation/screens/manage_manufacturers_screen.dart`
  - `lib/app_router.dart`
- Empfohlene Ziel-Lösung:
  - Einheitlicher `AdminGuard`-Wrapper (Screen-Level) + Fail-Closed Verhalten.
- Maßnahme-Typ:
  - Quick Win.

### P1-3: Survey-Listener-Lifecycle ist global fragil
- Problem:
  - `SurveyProvider` nutzt globale Subscriptions; mehrere Screens triggern `listen()`/`cancel()`.
  - Ein Screen kann indirekt die Streams eines anderen beenden.
- Auswirkung:
  - Inkonsistente Live-Daten, sporadisch leere Survey-KPIs.
- Betroffene Dateien:
  - `lib/features/survey/survey_provider.dart`
  - `lib/features/survey/presentation/screens/survey_overview_screen.dart`
  - `lib/features/survey/presentation/screens/survey_vote_screen.dart`
  - `lib/features/report/presentation/screens/report_screen_new.dart`
  - `lib/features/report/presentation/screens/report_surveys_screen.dart`
- Empfohlene Ziel-Lösung:
  - Gym- und Screen-scope sauber trennen: StreamProvider/autoDispose + referenzgezähltes Subscription-Handling.
- Maßnahme-Typ:
  - Strukturell.

### P1-4: Device-ID Vergabe race-prone
- Problem:
  - `CreateDeviceUseCase` ermittelt `max(id)+1` via Read-all, ohne serverseitige Synchronisation.
- Auswirkung:
  - Bei parallelen Admin-Aktionen mögliches ID-Race / inkonsistente Device-Nummern.
- Betroffene Dateien:
  - `lib/features/device/domain/usecases/create_device_usecase.dart`
  - `lib/features/admin/presentation/screens/admin_devices_screen.dart`
- Empfohlene Ziel-Lösung:
  - Serverseitiger Counter (Transaction/Cloud Function) oder Firestore-allocated monotonic ID.
- Maßnahme-Typ:
  - Strukturell.

### P1-5: Members-Report erzeugt teure N+1 Count-Abfragen
- Problem:
  - Pro Member wird `users/{uid}/trainingDayXP.count()` ausgeführt.
- Auswirkung:
  - Hohe Last/Latenz bei vielen Mitgliedern und bei Stream-Updates.
- Betroffene Dateien:
  - `lib/features/report/data/training_day_repository.dart`
  - `lib/features/report/presentation/screens/report_members_screen.dart`
  - `lib/features/report/presentation/screens/report_members_usage_screen.dart`
- Empfohlene Ziel-Lösung:
  - Voraggregierte Member-Engagement-Kennzahlen pro Gym (materialized counters) + inkrementelle Updates.
- Maßnahme-Typ:
  - Strukturell.

### P1-6: KPI-Berechnung „Gesamt“ ist fachlich falsch
- Problem:
  - `DeviceUsageRange.all` setzt `days = 1`; dadurch ist `Ø Sessions/Tag` verzerrt.
- Auswirkung:
  - Falsche Management-KPIs im Report.
- Betroffene Dateien:
  - `lib/features/report/presentation/widgets/usage_key_metrics.dart`
- Empfohlene Ziel-Lösung:
  - Zeitraum korrekt aus min/max Eventdatum ableiten oder bei „Gesamt“ andere KPI-Definition anzeigen.
- Maßnahme-Typ:
  - Quick Win.

### P1-7: Global-Manufacturer-Seeding aus UI + globale Schreibrechte
- Problem:
  - `ManageManufacturersScreen` stößt beim Öffnen Seeding an.
  - Rules erlauben Writes auf global `/manufacturers` für Admin-Kontexte über Client.
- Auswirkung:
  - Unerwünschte globale Datenänderungen durch Gym-spezifische Admin-Flows möglich.
- Betroffene Dateien:
  - `lib/features/manufacturer/presentation/screens/manage_manufacturers_screen.dart`
  - `lib/features/manufacturer/data/repositories/manufacturer_repository_impl.dart`
  - `firestore.rules`
- Empfohlene Ziel-Lösung:
  - Globales Seeding nur serverseitig (Deploy-/Ops-Pipeline), Client nur read + gym-scoped selection.
- Maßnahme-Typ:
  - Strukturell.

### P1-8: Report-KPI-Status für Feedback kann stale sein
- Problem:
  - `ReportScreenNew` liest `feedbackProvider`, lädt aber dort nicht aktiv `loadFeedback(gymId)`.
- Auswirkung:
  - KPI „Offenes Feedback“ kann veraltet oder leer erscheinen, bis anderer Screen geladen wurde.
- Betroffene Dateien:
  - `lib/features/report/presentation/screens/report_screen_new.dart`
  - `lib/features/feedback/feedback_provider.dart`
  - `lib/features/feedback/presentation/screens/feedback_overview_screen.dart`
- Empfohlene Ziel-Lösung:
  - Report-KPI-Loader entkoppeln (eigener lightweight count-provider) oder konsistentes initiales Load im Report-Entry.
- Maßnahme-Typ:
  - Quick Win.

---

## P2 (mittel)

### P2-1: Unnötiger Rebuild-Reset im Report-Wrapper
- Problem:
  - `ReportScreen` erzeugt `ReportScreenNew(key: UniqueKey())` bei jedem Build.
- Auswirkung:
  - Potenziell unnötige Neuinitialisierung/State-Verlust.
- Betroffene Dateien:
  - `lib/features/report/presentation/screens/report_screen.dart`
- Empfohlene Ziel-Lösung:
  - Stabilen Key verwenden oder Key entfernen.
- Maßnahme-Typ:
  - Quick Win.

### P2-2: Viele harte Strings/uneinheitliche Lokalisierung
- Problem:
  - In Owner/Admin/Report und Manufacturer-Screens sind zahlreiche Texte hart codiert.
- Auswirkung:
  - Inkonsistente Sprache, schlechtere Wartbarkeit, erschwerte i18n-Qualität.
- Betroffene Dateien (Auszug):
  - `lib/features/home/presentation/screens/owner_screen.dart`
  - `lib/features/home/presentation/widgets/owner/owner_hub_sections.dart`
  - `lib/features/admin/presentation/screens/*.dart`
  - `lib/features/report/presentation/screens/*.dart`
  - `lib/features/manufacturer/presentation/screens/manage_manufacturers_screen.dart`
- Empfohlene Ziel-Lösung:
  - String-Extraktion in `AppLocalizations`, i18n-Lint im CI.
- Maßnahme-Typ:
  - Quick Win.

### P2-3: Tabellen-/Listen-UX begrenzt mobil und bei großen Datenmengen
- Problem:
  - Breite DataTables mit horizontalem Scroll, keine Pagination/Virtualisierung, begrenzte Filter-/Sortiermodelle.
- Auswirkung:
  - Mobile Usability sinkt stark bei wachsender Member-Anzahl.
- Betroffene Dateien:
  - `lib/features/report/presentation/screens/report_members_screen.dart`
  - `lib/features/report/presentation/screens/report_members_usage_screen.dart`
  - `lib/features/admin/presentation/screens/admin_remove_users_screen.dart`
  - `lib/features/admin/presentation/screens/admin_symbols_screen.dart`
- Empfohlene Ziel-Lösung:
  - Responsive Listenansichten (cards + progressive disclosure) und server-/clientseitige Pagination.
- Maßnahme-Typ:
  - UX-strukturell.

### P2-4: UI-nahe Firestore/Cloud-Logik reduziert Testbarkeit
- Problem:
  - Mehrere Screens führen Datenzugriffe direkt aus statt via UseCases/Repos.
- Auswirkung:
  - Hoher Mocking-Aufwand, geringere Wiederverwendbarkeit, fragile Widget-Tests.
- Betroffene Dateien:
  - `lib/features/admin/presentation/screens/challenge_admin_screen.dart`
  - `lib/features/admin/presentation/screens/admin_remove_users_screen.dart`
  - `lib/features/report/presentation/screens/report_members_screen.dart`
  - `lib/features/report/presentation/screens/report_members_usage_screen.dart`
- Empfohlene Ziel-Lösung:
  - Thin Screens + UseCase-Schicht konsolidieren, zentrale Error-Mapping-Strategie.
- Maßnahme-Typ:
  - Strukturell.

---

## UX/UI Defizite (kompakt)

1. Informationsarchitektur
- Owner-Hub, Admin-Hub und Report haben überlappende Entry Points mit unterschiedlichem Guarding.
- Nutzerführung bei fehlenden Rechten ist nicht einheitlich (teils Redirect, teils „Kein Zugriff“, teils gar kein Guard).

2. Feedback-/Loading-/Error-Qualität
- Mehrere Flows zeigen nur generische SnackBars (`Fehler: $e`) ohne recoverable Aktionen.
- Report-Heatmap-Fehler werden still geschluckt; Diagnose für Owner/Admin fehlt.

3. Konsistenz
- Mischung aus lokaliserten und harten Strings (DE/EN gemischt, teils Legacy-Wording).
- Unterschiedliche visuelle Patterns zwischen Admin-Screens (Cards, Listen, Dialoge, Farbkontrast).

4. Mobile Usability
- Datenlastige Tabellen ohne mobile-first Darstellung (Filter, Sticky Header, Paging fehlen).

5. Accessibility Basics
- Teilweise unklare semantische Beschriftung bei Aktionselementen (insbesondere Icon-only Aktionen).

---

## Security/Permissions Audit

### Positiv
- Firestore Rules sind grundsätzlich restriktiv für gym-kritische Writes (`isAdmin(gymId)` für Devices/Surveys/Feedback/Challenges etc.).
- `GymContextGuard` verhindert fehlenden Gym-Kontext.

### Risiken

1. Client/Rules Rollen-Drift
- Client kennt `gym_admin`/`global_admin` nicht voll als Access-Tier.
- Risiko: legitime Server-Rechte werden im Client inkonsistent gespiegelt.

2. Remove-Membership Domain-Gap
- Admin kann Membership-Dokument löschen, aber nicht konsistent den User-Gym-Link (`gymCodes`) in einem atomaren Pfad bereinigen.
- Ergebnis: fachliche Inkonsistenz + „Wiederauftauchen“ möglich.

3. Globale Collections durch Gym-Admin konfigurierbar (Policy-Risiko)
- `/manufacturers` und `/deals` haben globale Oberfläche; Writes hängen u.a. von Admin-Kontexten ab.
- Falls fachlich gym-spezifische Trennung erwartet ist, ist das ein Isolation-Risiko.

### Empfohlene Security-Härtung
- Rollen-Contract zentralisieren (Client + Rules + Claims + Tests).
- Kritische Admin-Operationen über serverseitige Command-Funktionen kapseln.
- Für globale Collections Ownership/Scope explizit machen (global-only via global_admin oder gym-scoped via `gymId`-constraints).

---

## Performance Audit

### Höchste Lasttreiber

1. Device-Log-Scans im Report
- N+1 Query-Muster über alle Geräte + alle Logs im Zeitraum.

2. Member-Count N+1
- Pro Member separater `count()`-Read auf `trainingDayXP`.

3. UI-Rebuild-Verhalten
- `UniqueKey`-Reset im Report-Wrapper.
- Wiederholte `addPostFrameCallback`-Listener-Anstöße in Report-Screens.

### Quick Wins
- KPI-Fehler beheben (`DeviceUsageRange.all`).
- `UniqueKey` entfernen.
- Lightweight Count-Endpunkte/Provider für Feedback-/Survey-KPIs einführen.

### Strukturelle Maßnahmen
- Aggregierte Report-Daten (daily/hourly rollups + device/member aggregates).
- Pagination/Chunking für große Listen.
- Performance-Budget + Firebase Read-Metriken pro Screen.

---

## Test-Gaps

### Vorhanden
- Route-Access Basisfälle:
  - `test/app_router_access_test.dart`
- HomeTab-Policy:
  - `test/features/home/domain/home_tab_policy_test.dart`
- Owner-Screen Navigation:
  - `test/features/home/presentation/screens/owner_screen_test.dart`
- ReportProvider Gym-Reset:
  - `test/features/report/report_provider_test.dart`
- Firestore Rule-Tests vorhanden (breit, aber nicht owner/admin-spezifisch vollständig):
  - `firestore-tests/security_rules.test.js`
  - `firestore-tests/training_details_rules.test.js`
  - weitere.

### Kritische Lücken
1. Keine Widget-/Integration-Tests für zentrale Admin-Screens (Devices, Deals, Remove Users, Challenges, Branding, Manufacturers).
2. Keine End-to-End Tests für Report-Flows (Usage, Members, Surveys, Feedback).
3. Keine gezielten Tests für Rollen-Mismatch (`gym_admin`, `global_admin`) im Client.
4. Keine Tests für Remove-User End-to-End inkl. Persistenz des Membership-Entzugs.
5. Keine Performance-Regressionstests (Read-Counts/Render-Zeit) für Report bei großen Datenmengen.
6. Keine Rule-Tests für `deals`/`manufacturers` Write-Policy.

---

## Konkrete Roadmap-Checkliste

## Phase 0: Stabilisieren (Blocker schließen)

### Tasks
- [ ] [Strukturell] Serverseitigen Membership-Removal-Command einführen (atomar + auditierbar) und `AdminRemoveUsersScreen` darauf umstellen.
- [ ] [Strukturell] Rollen-Contract vereinheitlichen (`admin`, `gymowner`, `gym_admin`, `global_admin`) inkl. Client-Mapping und Route-Policy.
- [ ] [Quick Win] Harte Screen-Guards für alle Admin-Screens einführen (`AdminGuard` + konsistenter No-Access State).
- [ ] [Quick Win] KPI-Bug in `UsageKeyMetrics` für „Gesamt“ korrigieren.
- [ ] [Quick Win] `ReportScreen`-`UniqueKey` entfernen.
- [ ] [Quick Win] Feedback-/Survey-KPI-Loads deterministisch machen.

### Akzeptanzkriterien
- Remove-User entfernt Mitgliedschaft dauerhaft (kein Re-Auto-Provisioning ohne expliziten Rejoin).
- `gym_admin`/`global_admin` verhalten sich im Client erwartungskonform auf Tabs/Routes/Screens.
- Kein Admin-Screen ist ohne Rolle sinnvoll nutzbar.
- Report-KPIs zeigen konsistente Werte bei „Gesamt“.

### Risiken
- Migration vorhandener Nutzerzustände (`activeGymId`, Membership-Rollen) erfordert saubere Rückwärtskompatibilität.
- Serverseitige Commands benötigen abgestimmte Rule-/Function-Änderungen.

---

## Phase 1: UX/UI konsolidieren

### Tasks
- [ ] [Quick Win] Alle Owner/Admin/Report-Strings in `AppLocalizations` ziehen (DE/EN vollständig, keine Hardcodes).
- [ ] [UX-strukturell] Einheitliches Admin/Owner Interaction Pattern definieren (Loading/Error/Empty/NoAccess).
- [ ] [UX-strukturell] Mobile-first Redesign für Member-/Admin-Listen (statt breiter DataTables).
- [ ] [Quick Win] Fehler-Feedback auf actionable Meldungen umstellen (inkl. Retry).
- [ ] [Quick Win] Basis-Accessibility nachziehen (Semantics labels, Touch Targets, Kontrastprüfung).

### Akzeptanzkriterien
- Keine harten UI-Strings mehr im Owner/Admin/Report-Scope.
- Einheitliche Zustandsdarstellung (loading/error/empty/no-access) über alle Kernscreens.
- Member-/Admin-Listen sind auf kleinen Displays ohne horizontalen Zwang nutzbar.

### Risiken
- UI-Konsolidierung kann kurzfristig visuelle Regressions in bestehenden Flows erzeugen.

---

## Phase 2: Härten und Optimieren

### Tasks
- [ ] [Strukturell] Report-Aggregationspipeline aufbauen (rollups statt Rohlog-Vollscan).
- [ ] [Strukturell] Member-Engagement aggregiert speichern statt N+1 Count je Render.
- [ ] [Strukturell] Survey-Provider Lifecycle refactoren (screen-scope stream handling).
- [ ] [Strukturell] Device-ID-Vergabe serverseitig serialisieren.
- [ ] [Quick Win] Seeding globaler Manufacturers aus UI entfernen; global policy härten.
- [ ] [Strukturell] Testpyramide ausbauen:
  - Widget/Integration für Admin- und Report-Kernflüsse
  - Rule-Tests für `/deals` und `/manufacturers`
  - Rollenmatrix-Tests (`member`, `gymowner`, `admin`, `gym_admin`, `global_admin`)

### Akzeptanzkriterien
- Report-Screens erfüllen definiertes Read-/Latency-Budget in Testdaten mit hoher Last.
- Keine Provider-Lifecycle-Induzierte Inkonsistenz in Survey/Report.
- Kritische Admin-Flows durch Integrationstests abgesichert.

### Risiken
- Aggregationsmodell benötigt Backfill und Monitoring, sonst KPI-Abweichungen möglich.

---

## Definition of Launch-Ready (Owner/Admin)

Ein Owner/Admin-Launch ist erreicht, wenn alle Punkte erfüllt sind:

1. Permissions & Security
- Rollenmodell ist client-/server-seitig konsistent.
- Alle Admin-Aktionen sind fail-closed und serverseitig autorisiert.
- Kritische Writes laufen über auditierbare Server-Commands.

2. Funktionale Stabilität
- Remove-User/Membership-Entzug ist dauerhaft konsistent.
- Report-KPIs sind fachlich korrekt in allen Zeiträumen.
- Keine bekannten Lifecycle-Races in Survey/Feedback-KPIs.

3. UX/UI Qualität
- Einheitliche Zustände (Loading/Error/Empty/NoAccess).
- Mobile Nutzbarkeit für große Mitglieder-/Datensätze.
- Vollständige Lokalisierung im Scope.

4. Performance
- Keine N+1/Vollscan-Pfade in kritischen Report-Ansichten.
- Definierte Performance-Budgets werden eingehalten.

5. Test- und Betriebsreife
- Kernflows durch Unit/Widget/Integration abgesichert.
- Rule-Tests decken Owner/Admin Collections inkl. global Collections ab.
- Monitoring für Fehler- und Performance-Signale vorhanden.

