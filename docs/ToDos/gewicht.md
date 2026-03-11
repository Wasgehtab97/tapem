# Gewicht Feature - Roadmap (Ernaehrung)

Ziel: Im bestehenden Nutrition-Feature eine neue Seite **"Gewicht"** einfuehren, auf der User nur ihr Tagesgewicht eingeben muessen. Alles weitere (Persistenz, Aggregation, Verlauf, Durchschnittswerte) laeuft automatisch im Hintergrund.

Status-Legende:
- [ ] nicht gestartet
- [~] in Arbeit
- [x] abgeschlossen

---

## 1) Zielbild (Produkt + UX)

- [ ] Neue Action auf der Ernaehrungs-Startseite: **"Gewicht"** (gleichwertig zu "Tagesuebersicht", "Tagesziel setzen", "Gerichte", "Jahreskalender").
- [ ] Neue Seite **Gewicht** mit Premium-UI:
  - Oben: ein prominentes Eingabefeld fuer **heutiges Gewicht (kg)**.
  - Darunter: Verlaufschart mit **Durchschnittswerten**.
  - Umschaltbar: **Wochenschnitt**, **Monatsschnitt**, optional **Quartal/Jahr**.
- [ ] User-Flow bleibt minimal:
  - User gibt Wert ein (z. B. `82.4`), tippt auf Speichern.
  - UI aktualisiert sofort "Heute" + Verlauf.
  - Persistenz/Sync ohne weiteren Aufwand fuer den User.

Abnahme:
- Button sichtbar und aufrufbar von Nutrition Home.
- Gewicht kann in < 5 Sekunden eingetragen werden.
- Chart zeigt bei jeder Aggregationsstufe Mittelwerte (keine Rohpunkte als Hauptdarstellung).

---

## 2) Ist-Zustand (Codebasis)

- [x] Entry-Point vorhanden: `lib/features/nutrition/presentation/screens/nutrition_home_screen.dart`
- [x] Nutrition-Navigator vorhanden: `lib/features/nutrition/presentation/widgets/nutrition_tab_navigator.dart`
- [x] Routing-Konstanten vorhanden: `lib/app_router.dart`
- [x] Firestore-Repository-Muster vorhanden: `lib/features/nutrition/data/nutrition_repository.dart`
- [x] Shared Date-Key Utilities vorhanden (`yyyyMMdd`): `lib/features/nutrition/domain/utils/nutrition_dates.dart`
- [x] Chart-Library vorhanden: `fl_chart` in `pubspec.yaml`

Risiko jetzt:
- Aktuell gibt es noch kein Gewichtsdatenmodell, keine Rules, keine UI/State fuer Gewicht.

---

## 3) Ziel-Architektur (sauber, wartbar, kosteneffizient)

### 3.1 Datenmodell (Firestore)

- [ ] `users/{uid}/nutrition_weight_logs/{yyyyMMdd}`
  - Felder:
    - `kg` (number, z. B. `82.4`)
    - `source` (`manual`)
    - `updatedAt` (timestamp)
  - Regel: pro Tag ein kanonischer Wert (letzter gespeicherter Wert des Tages).

- [ ] `users/{uid}/nutrition_weight_year_summary/{yyyy}`
  - Felder:
    - `days.{yyyyMMdd}.kg`
    - `days.{yyyyMMdd}.updatedAt`
  - Zweck: Jahresansicht und Aggregation mit minimalen Reads (1 Doc pro Jahr).

- [ ] `users/{uid}/nutrition_weight_meta/current`
  - Felder:
    - `kg`
    - `dateKey`
    - `updatedAt`
  - Zweck: aktuelles Gewicht schnell laden (ohne Chart-Datenstruktur zu parsen).

### 3.2 Aggregationslogik (immer Durchschnittswerte)

- [ ] Basis: taegliche Werte aus `nutrition_weight_year_summary`.
- [ ] Aggregation in Buckets:
  - Woche: Durchschnitt aller Tageswerte je Kalenderwoche.
  - Monat: Durchschnitt aller Tageswerte je Kalendermonat.
  - Quartal/Jahr: analog je Zeitbucket.
- [ ] Sparse-Daten robust:
  - Wenn in einer Woche nur 1 Messung existiert, ist der Wochenschnitt = dieser Wert.
  - Wenn keine Werte im Bucket existieren: kein Punkt (oder explizite Luecke).
- [ ] UI zeigt immer:
  - `avgKg` je Bucket als Chartpunkt.
  - Tooltip: Zeitraum + Durchschnitt + Anzahl Messungen.

### 3.3 Read/Write-Strategie

- [ ] Save Gewicht:
  - 1 Write `nutrition_weight_logs/{yyyyMMdd}`
  - 1 Merge-Write `nutrition_weight_year_summary/{yyyy}`
  - 1 Merge-Write `nutrition_weight_meta/current`
- [ ] Load Gewicht Screen:
  - 1 Read `nutrition_weight_meta/current`
  - 1-2 Reads `nutrition_weight_year_summary/{yyyy}` (abhaengig vom Zeitraum ueber Jahresgrenze)
- [ ] Kein 365-Tage-Scan ueber Einzel-Dokumente.

---

## 4) Milestones mit Checklisten

## Milestone A - Domain + Rules + Repository

- [x] Neue Domain-Modelle anlegen:
  - `nutrition_weight_log.dart`
  - `nutrition_weight_year_summary.dart`
  - `nutrition_weight_meta.dart`
  - `nutrition_weight_bucket.dart` (Chart-DTO)
- [x] `NutritionRepository` erweitern:
  - `fetchWeightLog(uid, dateKey)`
  - `upsertWeightLog(uid, log)`
  - `fetchWeightYearSummary(uid, year)`
  - `upsertWeightYearDay(uid, year, dateKey, kg)`
  - `fetchCurrentWeight(uid)`
  - `upsertCurrentWeight(uid, kg, dateKey)`
- [x] Firestore Rules erweitern (`firestore.rules`, `firestore-dev.rules`):
  - Zugriff nur Owner.
  - `kg` Range validieren (z. B. `20 <= kg <= 400`).
  - `dateKey`/`year` validieren analog Nutrition-Pattern.
- [x] Falls noetig: `allowed`-Subcollections-Fallbackliste aktualisieren.

Stand 2026-03-05:
- Domainmodelle + Repository-APIs implementiert.
- Gewicht-Rules in `firestore.rules` und `firestore-dev.rules` implementiert.
- Neue Rule-Tests in `firestore-tests/nutrition_weight_rules.test.js` angelegt und erfolgreich ausgefuehrt.

Abnahme Milestone A:
- Repository kann Gewicht lesen/schreiben.
- Rules lassen gueltige Writes durch und blocken ungueltige Daten.

## Milestone B - State Management + Aggregation Service

- [x] Neuer Provider `nutrition_weight_provider.dart`:
  - State:
    - `todayKg`, `todayDateKey`
    - `selectedRange` (week/month/quarter/year)
    - `chartBuckets`
    - `isSaving`, `isLoading`, `error`
  - Actions:
    - `load(uid)`
    - `saveTodayWeight(uid, kg)`
    - `setRange(range)`
    - `reloadSeries(uid)`
- [x] Neuer Service `nutrition_weight_aggregation_service.dart`:
  - Eingabe: map `dateKey -> kg`
  - Ausgabe: sortierte Bucket-Liste mit `avgKg`, `count`, `label`, `startDate`.
- [x] Caching im Provider:
  - Jahr-Docs lokal im Memory-Cache halten, um Umschalten der Range ohne neue Reads zu ermoeglichen.

Stand 2026-03-05:
- `nutrition_weight_provider.dart` implementiert (inkl. Year-Cache, Range-Umschaltung, Save/Reload-Flow).
- `nutrition_weight_aggregation_service.dart` implementiert (Woche/Monat/Quartal/Jahr, Sparse-Daten via Durchschnitt pro Bucket).
- Zusaeztlicher Enum `nutrition_weight_range.dart` fuer stabile Range-Definition.
- Tests implementiert:
  - `test/features/nutrition/domain/services/nutrition_weight_aggregation_service_test.dart`
  - `test/features/nutrition/providers/nutrition_weight_provider_test.dart`

Abnahme Milestone B:
- Durchschnittswerte sind fuer Woche/Monat korrekt.
- Sparse-Daten (nur einzelne Messungen) werden korrekt verarbeitet.

## Milestone C - Navigation + Routing Integration

- [x] Neue Route in `AppRouter`:
  - `static const nutritionWeight = '/nutrition/weight';`
- [x] `NutritionTabNavigator` erweitert um Screen-Route.
- [x] `NutritionHomeScreen` erweitert um neuen Action-Tile:
  - Titel: `Gewicht`
  - Subtitle: z. B. `Tagesgewicht eintragen und Verlauf sehen.`
  - Position: in gleicher Aktionsliste neben den vorhandenen Buttons.

Stand 2026-03-05:
- Route-Konstante `AppRouter.nutritionWeight` hinzugefuegt.
- Navigation im Nutrition-Tab-Navigator auf neue Gewicht-Route verdrahtet.
- Neuer Action-Tile `Gewicht` auf der Nutrition-Home-Seite hinzugefuegt.
- Platzhalter-Screen `nutrition_weight_screen.dart` angelegt, damit die Navigation bereits stabil funktioniert; Premium-UI folgt in Milestone D.

Abnahme Milestone C:
- Von Nutrition Home ist die Seite "Gewicht" per Tap erreichbar.
- Back-Navigation funktioniert im Nutrition-Navigator-Stack sauber.

## Milestone D - Premium UI der Gewicht-Seite

- [x] Neue Screen-Datei:
  - `lib/features/nutrition/presentation/screens/nutrition_weight_screen.dart`
- [x] Header/Hero Card:
  - aktuelles Gewicht
  - letzter Update-Zeitpunkt
  - visuell an bestehende Nutrition-Premium-Cards angelehnt
- [x] Eingabebereich:
  - ein einziges prominentes Feld fuer `kg`
  - klare Validierung (Dezimalwert, realistischer Bereich)
  - Save-CTA mit Loading/Success/Error State
- [x] Verlauf-Bereich:
  - Segmentierte Auswahl fuer Wochenschnitt/Monatsschnitt/(Quartal/Jahr)
  - Line-Chart mit Gradient, Dot/Tooltip, ruhigem Grid
  - Empty-State: "Noch keine Daten"
- [x] Responsiv fuer kleine und grosse Displays.

Stand 2026-03-05:
- Finale Gewicht-Screen-UI implementiert (Hero, Tageswert-Karte, Einzelfeld fuer Gewicht, Save-Flow).
- Range-Selector fuer Woche/Monat/Quartal/Jahr integriert.
- Durchschnittsverlauf als stylischer `fl_chart`-Line-Chart mit Tooltips und Empty-State umgesetzt.
- Screen ist an den bestehenden Nutrition-Premium-Stil angepasst (Gradient-Surfaces, Brand-Akzente, klare Typohierarchie).
- `flutter analyze` fuer `nutrition_weight_screen.dart` ohne Befunde.

Abnahme Milestone D:
- UI wirkt hochwertig und konsistent mit bestehendem Brand-Design.
- Eingabe ist schnell, klar und fehlertolerant.

## Milestone E - Lokalisierung + Accessibility

- [x] Neue l10n-Keys in `app_de.arb` und `app_en.arb`:
  - Titel/Subtitle/Button/Fehlermeldungen/Range-Labels/Empty-State
- [x] `app_localizations*.dart` regenerieren.
- [x] Semantics:
  - Input/Buttons/Chart-Beschreibung fuer Screenreader.

Stand 2026-03-05:
- Gewicht-Texte in DE/EN lokalisiert (Home-Card, Gewicht-Screen, Snackbar-Meldungen, Range-Labels, Chart-States).
- Localization-Dateien via `flutter gen-l10n` regeneriert.
- Semantics-Labels fuer Gewichtseingabe und Chart-Bereich integriert.

Abnahme Milestone E:
- Texte lokalisiert (DE/EN).
- Kern-Interaktionen mit Accessibility-Labels vorhanden.

## Milestone F - Tests + QA + Stabilitaet

- [~] Unit-Tests:
  - Aggregationsservice (Woche/Monat/Quartal/Jahr)
  - Sonderfaelle: 1 Messung, Luecken, Jahreswechsel, doppelte Tage
- [ ] Repository-Tests (mit Mocks):
  - Save-Flow schreibt alle 3 Dokumente korrekt
- [ ] Widget-Tests:
  - Gewicht-Screen: Eingabe, Save, Range-Umschaltung, Empty-State
- [ ] Manuelle QA:
  - Offline/Online Verhalten
  - Schreibkonflikte (zwei Saves am selben Tag)
  - Performance bei langen Verlaeufen

Stand 2026-03-05:
- Unit-Tests fuer Aggregationsservice und Weight-Provider implementiert und gruen.
- Offen: dedizierte Repository-Tests, Widget-Tests fuer den Gewicht-Screen, manuelle QA-Matrix.

Abnahme Milestone F:
- Aggregations- und Save-Flow sind testabgedeckt.
- Keine sichtbaren Regressions im Nutrition-Flow.

---

## 5) Technische Leitentscheidungen (festlegen)

- [ ] **Ein Wert pro Tag** als kanonischer Tageswert (letzter Save gewinnt).
- [ ] **Chart zeigt Mittelwerte**, nicht Rohwerte als primaere Darstellung.
- [ ] **Year Summary als Read-Optimierung** verpflichtend.
- [ ] **Eigenstaendiger Weight-Provider** statt NutritionProvider-Aufblähung.
- [ ] **Route + UI modular** (keine Logik direkt im Screen verdrahten).

---

## 6) Umsetzungsreihenfolge (empfohlen)

1. Milestone A (Datenmodell + Repository + Rules)
2. Milestone B (Provider + Aggregation)
3. Milestone C (Navigation)
4. Milestone D (UI/Chart)
5. Milestone E (l10n/a11y)
6. Milestone F (Tests/QA)

---

## 7) Definition of Done (gesamt)

- [ ] "Gewicht" ist ueber Ernaehrung erreichbar.
- [ ] Tagesgewicht kann in einem einzigen klaren Eingabeschritt gespeichert werden.
- [ ] Verlauf zeigt je nach Auswahl Wochenschnitt/Monatsschnitt (und optional Quartal/Jahr) korrekt.
- [ ] Sparse-Eingaben (selten/unregelmaessig) werden korrekt aggregiert und visualisiert.
- [ ] Firestore Rules + Datenmodell sind konsistent, sicher und wartbar.
- [ ] Tests decken Kernlogik + UI-Flow ab.
- [ ] Dokumentation (`docs/ToDos/gewicht.md`) bleibt als lebender Umsetzungsplan erhalten.
