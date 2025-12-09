# Reporting – ToDo-Liste (Fortsetzung Phase 2+)

Stand: initiale Fassung für spätere Weiterentwicklung.  
Ziel: Alle offenen Ideen/Features rund um das Report-Feature kompakt sammeln, damit wir später strukturiert weitermachen können.

---

## 1. Ziele & Benchmarks

- **Zieldefinition pro Gym**
  - Trainingsfrequenz pro Mitglied (z. B. „≥ 1,8 Trainings/Woche“).
  - Antwortquote für Umfragen (z. B. „≥ 50 %“).
  - Maximal tolerierte offene Feedbacks (z. B. „< 5 offene Tickets“).
  - Optional: Zielauslastung bestimmter Geräte oder Zeiten.

- **UI-Einbindung**
  - Ziele im Report-Dashboard als kleine Progress-Widgets darstellen:
    - z. B. „Ø Trainingsfrequenz: 1,6 / 1,8“ mit farbcodiertem Zustand (grün/gelb/rot).
  - In Detail-Screens (Mitglieder, Nutzung, Feedback, Umfragen) jeweils ein Ziel-Block pro relevantem KPI.
  - Einstellmöglichkeit für Ziele:
    - Entweder in einer eigenen „Ziele“-Seite unter Admin/Report.
    - Oder einfach als JSON/Feld in der GymConfig, falls UI später.

- **Technik**
  - Erweiterung `GymConfig` um optionale Zielwerte.
  - Helper, der „Ziel erreicht / in Reichweite / verfehlt“ berechnet.
  - Optionale Hinweise im Dashboard: „Trainingsfrequenz liegt 0,2 unter dem Ziel.“

---

## 2. Feedback & Umfragen verknüpfen („Problemfelder“)

- **Kategorisierung einführen**
  - Feedback-Einträge:
    - Kategorie-Feld ergänzen (`device`, `course`, `staff`, `cleanliness`, `app`, `other`).
  - Umfragen:
    - Pro Umfrage eine oder mehrere Kategorien zuordnen.
  - UI:
    - Beim Feedback-Erstellen Kategorie auswählen (DropDown, Chips).
    - Bei Umfragen Kategorie(n) wählen.

- **Problemfelder-Report**
  - Aggregation je Kategorie:
    - Anzahl Feedback-Einträge (offen + erledigt).
    - Anteil negativer Antworten/Score aus Umfragen (z. B. Bewertungen < 3).
  - Darstellung:
    - Liste „Top-Problemfelder“ mit Score (z. B. 0–100).
    - Balken oder Ranking (z. B. „Sauberkeit“, „Duschen“, „Geräte“).
    - Kurztext: „Am meisten Beschwerden: Sauberkeit (12 Feedbacks, 3,0/5).“
  - Drilldown:
    - Tap auf Kategorie → gefilterte Feedback-Liste + Umfrage-Ergebnisse.

- **Technik**
  - Schema-Update Feedback/Surveys (Firestore-Felder).
  - Helper, der aus Feedback/Survey-Daten je Kategorie einen Score berechnet.
  - Kleiner zusätzlicher Screen oder Sektion im Report („Problemfelder“).

---

## 3. Kampagnen-Funktion richtig integrieren

Aktuell:  
- Report-Members-Screen kann Segment-Gruppen filtern (Hochrisiko, Neu, Stammkunden) und **Mitgliedsnummern kopieren/teilen**.

Nächster Schritt:

- **Kampagnen-Entität im System**
  - Struktur:
    - `id`, `gymId`
    - `name` (z. B. „Hochrisiko-Mitglieder KW 23“)
    - `segmentType` / Kriterien (z. B. `highRisk`, `newMembers`, `loyal`)
    - `memberIds` oder `memberNumbers`
    - `createdAt`, `createdBy`
    - optional: `channel` (Push, E-Mail, Offline), `notes`.

- **Creating Campaigns aus dem Report**
  - Im Segment-Actions-Sheet zusätzlich:
    - „Als Kampagne speichern“.
  - Flow:
    - Name eingeben,
    - optional Kanal/Notiz,
    - Server-Call, der Kampagnen-Dokument anlegt.

- **Kampagnen-Übersicht**
  - Eigener Screen (z. B. unter Admin/Report):
    - Liste der Kampagnen (Titel, Segment, Größe, Datum).
    - Status (geplant, durchgeführt, abgeschlossen).
  - Optional:
    - Verknüpfung mit späteren Push-/Mail-Funktionen, um Ergebnisse zu tracken (z. B. Aktivierungsrate der Kampagne).

---

## 4. Erweiterte Risiko- und Segmentlogik

Status:  
- Risikomodell bereits implementiert:
  - Berücksichtigt Mitgliedsdauer und Trainingsfrequenz pro Monat.
  - Segmente: `Gefährdet (hohes Risiko)`, `Neu im Studio`, `Stammkunden`.

Offene Erweiterungen:

- **Zeitliche Veränderung (Trend)**
  - Zukünftig: „Frequenz sinkt vs. steigt“ (z. B. Vergleich letzte 30 Tage vs. vorherige 30).
  - UI:
    - Trendpfeil oder Badge „Frequenz sinkt“.
  - Technik:
    - Zweite Abfrage/Statistik über definierte Zeitfenster.

- **Mehr Segmente**
  - z. B. „Reaktivierte Mitglieder“ (vorher inaktiv, jetzt wieder aktiv).
  - „Schläfer“ (lang gebucht, aber monatelang nicht gekommen).

---

## 5. Erweiterte Heatmap- und Stoßzeiten-Features

Status:  
- `CalendarHeatmap` (Tagesaktivität) + Weekly-Heatmap (Wochentag × Morgen/Mittag/Abend) sind integriert.

Offene Ideen:

- **Drilldown aus Heatmap**
  - Tap auf einen Tag:
    - → Liste der Sessions oder „typische Geräte“ dieses Tages.
  - Tap auf Wochen-Tageszeit-Kachel:
    - → Gefilterte Nutzungsliste (Top-Geräte zu diesem Slot).

- **Mehr Zeit-Slots**
  - z. B. 4–5 feinere Slots (Früher Morgen, Vormittag, Nachmittag, Abend, Spätabends).

- **Verknüpfung mit Kurs- und Trainerplanung**
  - Kombination: Peaks in der Heatmap + Kursplan:
    - Vorschläge wie „Neuen Kurs Dienstagvormittag hinzufügen“ oder „Trainer-Shift anpassen“.

---

## 6. Predictive / Pro-Features (Später)

- **Prognosen**
  - Simple Forecasts anhand historischer Daten (z. B. gleitende Durchschnitte).
  - Auslastungsprognosen für bestimmte Tage/Zeiträume.

- **Empfehlungen**
  - Regelbasierte oder ML-basierte Hinweise:
    - „Gerät X dauerhaft untergenutzt → Umstellen/Promoten.“
    - „Kurs Y immer voll → Zusatztermin überlegen.“

- **Multi-Studio-Vergleiche**
  - Für Betreiber mit mehreren Studios:
    - Vergleichstabellen und Rankings (Auslastung, Zufriedenheit, Churn).

---

## 7. Offene UX-/Copy-Aufgaben

- Texte lokalisieren:
  - Risiko-Labels (niedrig/mittel/hoch/neu im Studio).
  - Heatmap-Beschreibungen (z. B. „Stärkste Auslastung: Di Abend“).
  - Kampagnen-Texte („Aktionen für Gruppe“, Beschreibungen der Segmente).

- Microcopy & Tooltips:
  - Kurze Info-Icons bei komplexeren KPIs (z. B. „Wie wird Risiko berechnet?“).
  - Onboarding-Hinweise für die neuen Segmente und Heatmaps.

---

Diese Datei ist als Arbeitsgrundlage gedacht: Wenn wir wieder am Report-Feature weiterarbeiten, können wir hier gezielt Punkte auswählen, in Issues übersetzen und Schritt für Schritt implementieren.***
