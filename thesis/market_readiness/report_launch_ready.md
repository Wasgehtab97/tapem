# Report-Feature – Launch-Ready Roadmap

Stand: _Entwurfsfassung – kann iterativ ergänzt werden_

Ziel: Das Report-Feature wird so „launch-ready“ gemacht, dass Studiobetreiber:

- innerhalb von 1–2 Minuten die wichtigsten Kennzahlen verstehen,
- konkrete Maßnahmen aus den Daten ableiten können,
- das Feature als klaren Mehrwert wahrnehmen (Retention- & Umsatztreiber),
- und es „dumm“ wäre, die App **nicht** zu nutzen.

Die Roadmap ist in Phasen und Sprints gegliedert:

- **Phase 1 – Launch-Ready (MVP+ UI/UX & Kern-KPIs)**
- **Phase 2 – „Wow-Effekte“ (Differenzierung vs. Konkurrenz)**
- **Phase 3 – Pro & Predictive (High-End für Ketten & Power-User)**

Jede Phase beinhaltet:

- Ziele & Erfolgskriterien
- UX & UI-Tasks
- Daten- & Logik-Tasks
- QA/Testing & Go-Live-Checkliste

---

## 1. Phase 1 – Launch-Ready (MVP+)

Zeithorizont: ca. 2–4 Wochen (abhängig von Teamgröße).  
Fokus: Konsistente UI/UX, klare Navigation, zentrale KPIs, verlässliche Datenbasis, einfache Exporte.

### 1.1 Ziele & Erfolgskriterien (Phase 1)

- **Ziel 1 – Klarer Report-Einstieg**
  - Studiobetreiber versteht beim Öffnen des „Report“-Tabs sofort:
    - Anzahl aktiver Mitglieder,
    - grundlegende Nutzung/Auslastung,
    - Status von Feedback & Umfragen.
  - Erfolgskriterium:
    - 3–5 Kern-KPIs auf der Report-Übersichtsseite sichtbar, ohne Scrollen.

- **Ziel 2 – Konsistente, intuitive Navigation**
  - Alle Report-Screens folgen einem einheitlichen Layout:
    - Title-Bar mit klarem Screen-Titel,
    - optionaler Zeitraum-Filter,
    - klar erkennbare CTAs (Buttons, Chips).
  - Erfolgskriterium:
    - Usability-Review: kein Screen mit doppelten Titeln, verwirrenden Aktionen oder inkonsistenten Farben.

- **Ziel 3 – Verlässliche Kennzahlen**
  - Mitglieds-, Nutzungs-, Feedback- und Umfragedaten werden korrekt aggregiert und gefiltert.
  - Erfolgskriterium:
    - Stimmt mit Testdaten / Backend-Queries überein,
    - mindestens 3 Test-Szenarien pro Report-Typ (normal, leer, „extrem“).

- **Ziel 4 – Basis-Export**
  - Studiobetreiber können zentrale Listen/Kennzahlen exportieren (CSV/PDF).
  - Erfolgskriterium:
    - Export-Funktion auf mindestens `Mitglieder`- und `Nutzung`-Reports verfügbar.

---

### 1.2 Report-Übersichtsseite (Dashboard-Einstieg)

**Ziel:** Diese Seite fungiert als „Daily Briefing“ für Studioleiter.

#### 1.2.1 UI/UX-Aufgaben

- **Header aufräumen**
  - Nur **ein** Titel `Report` (zentriert oder linksbündig).
  - Entfernen der mehrfach untereinander angezeigten „Report“-Titel.
  - Untertitel ergänzen:
    - z. B. „Kennzahlen zu Mitgliedern, Nutzung und Feedback.“
  - Rechts oben: Icon-Button für `Export` oder `Teilen` (z. B. Share-Sheet / E-Mail).

- **Globaler Zeitraum-Filter**
  - Direkt unter dem Header:
    - Chips/Button-Leiste: `7 Tage`, `30 Tage`, `90 Tage`, `Jahr`, `Benutzerdefiniert`.
  - Design:
    - Aktiver Zeitraum in Akzentfarbe (Blau), andere dezent.
  - Funktional:
    - Zeitraum gilt für alle KPIs der Übersichtsseite.

- **Hero-KPIs einführen**
  - 3–4 KPIs im oberen Bereich (Cards oder Kachel-Layout), z. B.:
    - `Aktive Mitglieder` (inkl. Trend vs. Vorperiode),
    - `Ø Trainingstage / Mitglied` im gewählten Zeitraum,
    - `Zufriedenheit` (z. B. NPS oder Feedback-Score),
    - `Antwortquote Umfragen`.
  - Jede KPI ist tappbar → führt in den entsprechenden Detail-Report.

- **Feature-Cards neu strukturieren**
  - Vier Cards: `Mitglieder`, `Nutzung`, `Feedback`, `Umfragen`.
  - Jede Card enthält:
    - Icon,
    - Titel,
    - Kurzbeschreibung (1 Zeile),
    - eine kleine Zahl / KPI,
    - Pfeil-Icon für Navigation.
  - Beispiel:
    - Mitglieder: „Überblick über aktive / inaktive Mitglieder.“ + „Aktive: 426“.
    - Nutzung: „Gerätenutzung & Stoßzeiten analysieren.“ + „Auslastung: 68 %.“
    - Feedback: „Offene Rückmeldungen im Blick.“ + „Offen: 3 Tickets.“
    - Umfragen: „Mitgliederstimme messen.“ + „Aktive Umfragen: 1.“

- **Empty-, Loading- und Error-States**
  - Loading:
    - Skelett-Karten für KPIs und Feature-Cards (kein komplett leerer Screen).
  - Empty:
    - Falls kein Datensatz (z. B. neues Studio): „Noch keine Daten – starte mit Umfragen oder aktiviere die Nutzungserfassung.“
  - Error:
    - „Daten konnten nicht geladen werden. Erneut versuchen.“ + Retry-Button.

#### 1.2.2 Daten- & Logik-Aufgaben

- Backend/Service:
  - Aggregation für globale KPIs:
    - Aktive Mitglieder (Definition festlegen: z. B. Mitglieder mit aktiver Mitgliedschaft),
    - Trainingsfrequenz (Summe Trainingstage / Anzahl Mitglieder im Zeitraum),
    - Feedback-Score (z. B. Durchschnittswert aus Bewertungen oder NPS),
    - Umfrage-Antwortquote (Antworten / versendete Einladungen).
  - API-Endpunkte/Queries so strukturieren, dass ein Request die wichtigsten Kennzahlen liefert.

- Frontend:
  - Globale Filterzustände (Zeitraum) in einem zentralen State (z. B. Provider / Bloc / Riverpod) verwalten.
  - Caching der letzten geladenen Daten (bessere Performance, Offline-Toleranz).

---

### 1.3 Mitglieder-Report

**Ziel:** Fragen beantworten wie:

- Wie viele Mitglieder sind aktiv, inaktiv, gefährdet?
- Wer hat in den letzten X Tagen nicht trainiert?
- Welche Mitglieder zeigen sinkende Aktivität?

#### 1.3.1 UI/UX-Aufgaben

- **Header & Kontext**
  - Titel: `Mitglieder`.
  - Untertitel: „Aktive, inaktive und gefährdete Mitglieder im Überblick.“
  - Rechts oben:
    - Option 1: Button `Export`,
    - Option 2: Overflow-Menü (`…`) mit `Export`, `Filter zurücksetzen`.

- **KPI-Bereich über der Tabelle**
  - 3–4 Kennzahlen:
    - `Aktive Mitglieder` (mind. 1 Trainingstag im Zeitraum),
    - `Inaktive Mitglieder` (0 Trainingstage),
    - `Gefährdete Mitglieder` (z. B. 1–2 Trainingstage, definierbare Grenze),
    - `Ø Trainingstage / Mitglied`.
  - Darstellung mit kleinen Cards; Klicken auf eine Card setzt entsprechenden Filter in der Tabelle.

- **Filter & Suche**
  - Suchfeld:
    - Placeholder: „Name, Mitgliedsnummer oder E-Mail suchen“.
  - Filterchips:
    - `Alle`, `Aktiv`, `Inaktiv`, `Gefährdet`.
  - Optional (später erweiterbar):
    - Filter nach Vertragsart (Monatlich, Jahresvertrag, Probe), Trainer, Kursnutzung.

- **Tabellen-Layout**
  - Spalten:
    - `Name` (falls verfügbar) oder `Mitgliedsnummer`,
    - `Status` (Aktiv/Inaktiv/Gefährdet),
    - `Trainingstage` im gewählten Zeitraum,
    - optional: `Letzter Besuch` (Datum).
  - UX:
    - Sticky Header für Spaltentitel beim Scrollen,
    - Zeilen tappbar → Member-Detail-View (Verlauf, Nutzung, Feedback-Historie).

- **Empty- & Error-States**
  - Kein Ergebnis durch Filter:
    - „Keine Mitglieder für diesen Filter/Zeitraum gefunden.“
  - Loading:
    - Skeleton-Rows in der Tabelle.

#### 1.3.2 Daten- & Logik-Aufgaben

- Definitionen & Segmente festlegen:
  - Aktiv: Mitglieder mit ≥1 Trainingstag im Zeitraum.
  - Inaktiv: Mitglieder mit 0 Trainingstagen im Zeitraum.
  - Gefährdet: z. B. 1–2 Trainingstage im Zeitraum oder deutlicher Rückgang vs. Vorperiode (Phase 2 erweiterbar).

- Backend:
  - API-Filter-Parameter für:
    - Zeitraum,
    - Status (aktiv / inaktiv / gefährdet),
    - Freitextsuche,
    - Pagination.

- Frontend:
  - Tabellenkomponente mit:
    - Sortierung (z. B. nach Name, Trainingstagen),
    - lokaler Filterung (wenn sinnvoll),
    -,Loading & Error-Handling.
  - Export-Lösung (z. B. CSV-Download bzw. generierte Datei teilen).

---

### 1.4 Nutzung-Report (Gerätenutzung & Aktivität)

**Ziel:** Studiobetreiber verstehen Auslastung, Stoßzeiten und Top-/Schwach-Geräte.

#### 1.4.1 UI/UX-Aufgaben

- **Zeitraum-Filter vereinheitlichen**
  - Gleicher Zeitraum-Selector wie auf der Report-Übersicht.
  - Keine doppelten oder widersprüchlichen Filter (nur eine „Quelle der Wahrheit“).

- **KPI-Cards im Header-Bereich**
  - Beispiele:
    - `Gesamt Sessions` im Zeitraum,
    - `Top Gerät` (Name + Sessions),
    - `Spitzenzeit` (z. B. „Mo 18–20 Uhr“),
    - `Ø Trainingsdauer` (optional).

- **Chart-Bereich strukturieren**
  - Primärer Chart:
    - „Nutzung nach Gerät“ (Top 5 Geräte) als Balkendiagramm.
  - Tabs innerhalb des Chart-Bereichs:
    - `Geräte`, `Wochentage`, `Uhrzeiten`.
  - Interaktion:
    - Tap auf Balken → Tooltip mit Zahlen und Vergleich zur Vorperiode (z. B. `+12 % vs. letzte 30 Tage`).

- **Such- und Filterleiste**
  - Suchfeld: „Gerät oder Beschreibung suchen“ (Placeholder deutlich sichtbar).
  - Filterchips:
    - `Alle`, `Cardio`, `Kraft`, `Freihantel`, `Kurse` (abhängig von Datenstruktur).

- **Textuelle Zusammenfassung**
  - Unterhalb des Charts:
    - 2–3 Insights in Klartext, z. B.:
      - „60 % der Mitglieder trainieren mindestens 1x pro Woche.“
      - „Dienstagabend ist die am stärksten ausgelastete Zeit.“

- **Details-Sektion**
  - Liste:
    - `Top 5 Geräte` (Name, Sessions, Auslastung, Trend),
    - `Stoßzeiten` (einfacher Text oder kleine Heatmap-Preview),
    - `Geräte mit geringster Nutzung`.

#### 1.4.2 Daten- & Logik-Aufgaben

- Aggregationen:
  - Sessions pro Gerät,
  - Sessions pro Wochentag,
  - Sessions pro Stunde (für Stoßzeiten),
  - Anzahl Mitglieder pro Nutzungsfrequenz (z. B. 0, 1–3, 3–7, >7 Tage).

- Backend:
  - Endpunkte für:
    - `usage/summary` (für KPIs),
    - `usage/by-equipment`,
    - `usage/by-weekday`,
    - `usage/by-hour`.
  - Möglichkeit, Vorperiode zum Vergleich anzufragen.

- Frontend:
  - Mapping der Daten in Chart-Komponenten,
  - Berechnung von Prozenttrends,
  - Konfiguration der Tooltips & Labels.

---

### 1.5 Feedback-Report

**Ziel:** Feedback wird wie ein leichtes Ticket-System nutzbar.

#### 1.5.1 UI/UX-Aufgaben

- **Einstiegsscreen „Feedback“**
  - Card mit:
    - Titel `Feedback`,
    - Kurzbeschreibung: „Verwalte Vorschläge, Beschwerden und Lob deiner Mitglieder.“,
    - KPI: „Offen: X | Erledigt: Y“.
  - CTA `Feedback ansehen` oder direkt Liste angezeigt (Cards).

- **Tabs „Offen“ / „Erledigt“**
  - Layout:
    - `Offen` als Default,
    - `Erledigt` daneben.
  - Offline/Loading:
    - Skeleton statt „leerer schwarzer Screen mit Spinner“.

- **Feedback-Listenansicht**
  - Jede Feedback-Card zeigt:
    - Kategorie (Icon + Label: z. B. Gerät, Kurs, Mitarbeiter, Allgemein),
    - Kurzbeschreibung/Titel,
    - Datum,
    - optional: Verfasser (Name oder anonym),
    - Status (Offen, In Bearbeitung, Erledigt).
  - Sortierung:
    - Standard: „Neueste zuerst“,
    - optional: „Priorität hoch“.

- **Feedback-Detailansicht**
  - Elemente:
    - Voller Beschreibungstext,
    - Kategorie,
    - Gerät/Kurs/Trainer (falls zugeordnet),
    - Datum, Nutzerinfo (falls vorhanden),
    - Status-Selector (Offen/In Bearbeitung/Erledigt),
    - interne Notizen-Feld (nur für Studio-Team sichtbar).

- **Empty States**
  - Offen leer:
    - „Kein offenes Feedback. Halte die Zufriedenheit hoch und starte regelmäßig Umfragen.“,
    - CTA `Umfrage erstellen`.
  - Erledigt leer:
    - „Noch kein Feedback abgeschlossen.“

#### 1.5.2 Daten- & Logik-Aufgaben

- Kategorien definieren:
  - z. B. `Geräte`, `Kurse`, `Mitarbeiter`, `Sauberkeit`, `App`, `Sonstiges`.

- Backend:
  - Endpunkte für:
    - Feedback-Liste gefiltert nach Status, Kategorie, Zeitraum,
    - Feedback-Detail,
    - Status-Update + interne Notiz.

- Frontend:
  - Tabs mit Statusfilter verknüpfen,
  - Detail-View mit Editiermöglichkeiten für Status und Notizen,
  - Optimistische Updates (optional) bei Statuswechsel.

---

### 1.6 Umfragen-Report

**Ziel:** Umfragen als einfache, aber wirkungsvolle „Kampagnen“-Tools.

#### 1.6.1 UI/UX-Aufgaben

- **Umfragen-Übersicht**
  - Oben Primary-Button `Neue Umfrage erstellen`.
  - KPI-Cards:
    - `Aktive Umfragen` inkl. Antwortquote,
    - `Abgeschlossene Umfragen` inkl. Ø Zufriedenheitswert/NPS.

- **Tabs „Offen“ / „Abgeschlossen“**
  - `Offen`:
    - Liste aller aktiven/geplanten Umfragen mit:
      - Titel,
      - Zeitraum,
      - Antwortquote,
      - Anzahl Antworten,
      - Status (Aktiv / Geplant).
  - `Abgeschlossen`:
    - gleiche Darstellung, aber mit Fokus auf Auswertung.

- **Umfrage-Detail**
  - Übersicht:
    - Titel, Beschreibung, Zeitraum, Zielgruppe,
    - Antwortquote, Anzahl Antworten.
  - Pro Frage:
    - Balkendiagramm (Verteilung der Antworten),
    - optional: Liste von Freitext-Kommentaren.

- **Empty States**
  - Offen leer:
    - „Derzeit keine aktiven Umfragen. Starte eine neue Umfrage, um deine Mitglieder besser zu verstehen.“ + CTA.
  - Abgeschlossen leer:
    - „Noch keine Umfragen abgeschlossen.“

#### 1.6.2 Daten- & Logik-Aufgaben

- Backend:
  - Endpunkte für:
    - Umfragen-Liste (Status gefiltert),
    - Umfrage-Detail inkl. Antwortverteilung,
    - grundlegende Kennzahlen (Antwortquote).

- Frontend:
  - Tab-Logik & Filterung,
  - Chart-Komponenten für Antwortverteilungen,
  - Export-Option für Umfrageberichte (in Phase 2 ausbaubar).

---

### 1.7 Übergreifende technische Aufgaben (Phase 1)

- Einheitliches Design-System / Styleguide im Code:
  - Typografie-Rampen,
  - Abstands- und Padding-Konventionen,
  - Farben (Primär, Sekundär, Hintergrund, Warnung),
  - Komponenten (Cards, Chips, Tabs, Charts).

- State-Management:
  - Zentraler Store/State für:
    - globalen Zeitraum,
    - ggf. ausgewähltes Studio (für Multi-Standort-Betreiber später).

- Performance:
  - Pagination für große Tabellen (Mitglieder),
  - Caching von Chart-Daten (Nutzung, Umfragen),
  - sinnvolle Limits (z. B. Top 20 Geräte).

- Sicherheit & Berechtigungen:
  - Sicherstellen, dass nur berechtigte Rollen Zugriff auf Report-Features haben (z. B. Studioleiter, Admins).

---

## 2. Phase 2 – „Wow-Effekte“ (Differenzierung)

Zeithorizont: ca. 4–6 Wochen nach Phase 1.  
Ziel: Aus dem soliden Reporting ein „No-Brainer“-Feature machen, das echten Business-Impact zeigt.

### 2.1 Ziele & Erfolgskriterien (Phase 2)

- **Ziel 1 – Proaktive Warnsignale**
  - Studiobetreiber sehen frühzeitig gefährdete Mitgliedergruppen.
- **Ziel 2 – Bessere Flächennutzung**
  - Stoßzeiten und schwache Zeiten werden klar visualisiert.
- **Ziel 3 – Verknüpfung von Feedback & Nutzung**
  - Probleme werden quantifiziert (z. B. viele Beschwerden zu Gerät X bei gleichzeitig hoher Nutzung).

Erfolgskriterien:

- Studio kann konkrete Maßnahmen aus Reports ableiten (z. B. gezielte Kampagnen, Kurs-Optimierung).

### 2.2 Churn-Risiko & Aktivierungs-Insights

- **Churn-Risiko-Score pro Mitglied**
  - Faktoren:
    - Abnehmende Trainingsfrequenz,
    - Inaktivität über Zeitraum X,
    - negatives Feedback,
    - Vertragslaufzeit (z. B. kurz vor Ende).
  - Darstellung:
    - Badge `Risiko: hoch/mittel/niedrig` in Mitglieds-Liste,
    - eigene Ansicht: „Gefährdete Mitglieder“ mit Filteroption.

- **Segment-Reports**
  - vordefinierte Segmente:
    - „Neu im Studio“ (< 3 Monate),
    - „Stammkunden“ (> 12 Monate),
    - „Reaktivierte Mitglieder“ (vorher inaktiv, jetzt wieder aktiv),
    - „Risikogruppe“ (hoher Score).
  - UI:
    - Segment-Chips im Mitglieder-Report,
    - Segment-Beschreibung + KPI-Boxen.

### 2.3 Kapazitäts- & Stoßzeiten-Heatmaps

- Heatmap-Screen:
  - Achsen:
    - X: Wochentage,
    - Y: Tageszeiten (z. B. 6–22 Uhr in 1h-Slots).
  - Farbcodierung: Auslastung (0–100 %).
  - Tooltip: genaue Auslastung, Sessions, Vergleich zu Vorwoche.

- Nutzung:
  - Sondersektion „Auslastung & Stoßzeiten“ im Nutzung-Report.
  - Kurze Insights:
    - „Dienstag 18–20 Uhr ist regelmäßig über 90 % ausgelastet.“
    - „Montagmorgen hat noch Kapazitäten – bewirb diese Zeiten.“

### 2.4 Feedback & Umfragen verknüpfen

- Kategorien-Abgleich:
  - Feedback-Kategorien = Umfrage-Kategorien (Geräte, Kurse, Mitarbeiter, etc.).

- Report:
  - „Top-Problemfelder“:
    - Kombination aus:
      - Anzahl Beschwerden,
      - negative Bewertungen in Umfragen.
  - Darstellung:
    - Liste: Kategorie, Score, Trend, Anzahl Tickets.

### 2.5 Management-Summary & Auto-Berichte

- Wöchentliche / monatliche Zusammenfassung:
  - Generierter Text (z. B.):
    - „Aktive Mitglieder: +3,2 % vs. Vormonat.“
    - „Gefährdete Mitglieder: 34, bitte prüfen.“
    - „Top Gerät: Beinpresse (+12 % Nutzung).“
  - Darstellung:
    - eigener Screen-Abschnitt „Management-Summary“,
    - optional E-Mail-PDF-Versand.

### 2.6 Ziele & Benchmarks im Report

- Studios können Ziele definieren:
  - z. B. `Ø Trainingstage ≥ 1,8`, `Antwortquote Umfragen ≥ 50 %`.

- UI:
  - KPIs zeigen Zielbalken,
  - Anzeige: „1,6 / 1,8“ + farbliche Markierung (grün erfüllt, gelb/rot verfehlt).

---

## 3. Phase 3 – Pro & Predictive (High-End)

Zeithorizont: 6+ Wochen nach Phase 2 (oder parallel in größerem Team).  
Ziel: Aus dem Reporting wird eine echte Steuerungszentrale („Gym OS“) mit Prognosen und Kampagnen.

### 3.1 Prognosen & Empfehlungen

- **Predictive Nutzung**
  - Vorhersage der Auslastung für:
    - bestimmte Tage/Wochen,
    - bestimmte Geräte,
    - Tageszeiten.
  - Anzeige:
    - „Prognose: Nächste Woche voraussichtlich +10 % Auslastung vs. aktuelle Woche.“

- **Empfehlungen**
  - Regeln / ML-Modelle:
    - „Kurs X ist konstant überfüllt → Empfehlung: weiteren Termin anbieten.“
    - „Gerät Y ist dauerhaft untergenutzt → Empfehlung: Umpositionierung/Promotion.“
  - UI:
    - „Empfehlungen“-Sektion mit Karten (Beschreibung + CTA).

### 3.2 Segmentierte Kampagnen aus dem Report heraus

- Segment-Aktionen:
  - Aus Segmenten (z. B. „Mitglieder mit <1 Training/Monat“) direkt:
    - Push-Kampagne starten,
    - E-Mail-Kampagne,
    - Gutschein/Promo zuweisen.

- Erfolgsmessung:
  - Nach Kampagne:
    - „Aktivierungsrate“,
    - Veränderung der Trainingsfrequenz,
    - Vergleich zur Kontrollgruppe (wenn vorhanden).

### 3.3 Multi-Studio-Reports (für Ketten)

- Vergleich der Standorte:
  - KPIs:
    - Auslastung,
    - Zufriedenheit,
    - Churn-Rate,
    - Umsatz (falls integriert).
  - UI:
    - Tabellen-/Ranking-Ansicht der Studios,
    - Karte mit Standorten (optional).

- Insights:
  - „Top-Performer“-Studios,
  - „Aufholer“-Studios (starker Trend nach oben),
  - „Risikostudios“ (kritische Kennzahlen).

### 3.4 Geräte-ROI & Kosten/Nutzen

- Verknüpfung:
  - Gerätenutzung + Investitionskosten + Wartung.

- Reports:
  - „Nutzungsstunden pro € Investition“,
  - „Geräte mit schlechtem Kosten/Nutzen-Verhältnis.“

- Nutzen:
  - Basis für Investitionsentscheidungen, Austausch, Second-Hand-Verkauf.

### 3.5 Trainer- & Kurs-Performance

- KPIs:
  - Auslastung pro Kurs,
  - Bewertungen/Feedback pro Trainer,
  - No-Show-Raten.

- Reports:
  - Liste „Top-Kurse“, „Schwach performende Kurse“,
  - „Top-Trainer“ & „Trainer mit Handlungsbedarf“.

---

## 4. QA, Testing & Go-Live-Checkliste

### 4.1 UX/Produkt-Review

- Alle Screens manuell mit Studio-Persona durchgehen:
  - „Was sehe ich hier?“
  - „Welche Frage beantwortet mir dieser Screen?“
  - „Welche Aktion ergibt sich direkt daraus?“

- Feedback-Runde mit 2–3 echten Studiobetreibern (oder internen Rollen).

### 4.2 Technische Tests

- Unit-Tests:
  - Berechnungslogik der KPIs (Mitgliederstatus, Nutzungsaggregation, Antwortquoten).
- Integrationstests:
  - End-to-End-Flows (z. B. Zeitraum ändern → Daten/Charts aktualisieren).
- Edge Cases:
  - sehr wenige Daten (neues Studio),
  - sehr viele Daten (große Ketten),
  - Offline/Instabile Verbindung.

### 4.3 Performance & Stabilität

- Profiling für:
  - Ladezeiten der Reports,
  - Chart-Rendering.
- Maßnahmen:
  - Pagination,
  - Caching,
  - Lazy Loading von Detail-Daten.

### 4.4 Dokumentation & Onboarding

- Kurze In-App-Erklärungen/Tooltips:
  - z. B. Info-Icon neben KPIs („Wie wird das berechnet?“).
- Onboarding-Screen beim ersten Öffnen des Report-Tabs:
  - 2–3 Screens mit:
    - „Was kann der Report-Bereich?“,
    - „Wo finde ich welche Informationen?“.

---

## 5. Konkrete Umsetzungsschritte von „jetzt“ bis Launch (Phase 1)

**Sprint 1 (1–2 Wochen)**  
- Design:
  - Finalisierung der UI für:
    - Report-Übersicht,
    - Mitglieder,
    - Nutzung,
    - Feedback,
    - Umfragen (Phase-1-Versionen).
- Implementierung:
  - Konsolidierung der Header/Title-Bars,
  - Einführung des globalen Zeitraum-Filters,
  - Implementieren der KPI-Bereiche auf der Report-Übersicht.

**Sprint 2 (1–2 Wochen)**  
- Implementierung:
  - Mitglieder-Report:
    - KPIs,
    - Filter & Suche,
    - Tabellen-UX.
  - Nutzung-Report:
    - Chart-Refactor (einheitliche Tabs),
    - KPIs + textuelle Zusammenfassung.
  - Feedback:
    - Listenansicht mit Tabs „Offen/Erledigt“,
    - Detail-View mit Statuswechsel.

**Sprint 3 (1–2 Wochen)**  
- Implementierung:
  - Umfragen:
    - Übersicht mit KPIs & Listen,
    - Basis-Auswertung pro Umfrage (Charts).
  - Exportfunktion für:
    - Mitglieder-Liste,
    - Nutzung-Report,
    - ggf. Umfrage-Detail.
- QA:
  - Tests, Performance, Edge Cases.
- Go-Live-Vorbereitung:
  - Interne Demo,
  - ggf. Beta-Phase mit 1–2 Studios,
  - Einholen von Feedback für Phase-2-Feintuning.

Damit bildet diese Datei den Referenzplan, um das Report-Feature von heute bis zum „launch-ready“ Zustand (Phase 1) und darüber hinaus (Phase 2 & 3) systematisch auszubauen.

