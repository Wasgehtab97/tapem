# Gymowner App Roadmap

## Zielbild
- `gymowner` soll genau die Member-Bottom-Tabbar plus **einen** zusätzlichen Tab `Owner` sehen.
- Auf der Seite `Owner` liegen zentral alle owner-spezifischen Einstiege.
- `Report` und `Admin` werden über die `Owner`-Seite geöffnet.
- `Ernährung` und `Plan` bleiben für `gymowner` außerhalb der Bottom-Bar (weiterhin über Profil erreichbar).

## Phase 1: Navigation konsolidieren
- [x] Neue Rolle `gymowner` mit Admin-äquivalenten Berechtigungen eingeführt.
- [x] Bottom-Tab `Owner` nur für `gymowner` ergänzt.
- [x] Neue Seite `Owner` erstellt.
- [x] Buttons `Report` und `Admin` auf `Owner`-Seite eingebaut.
- [x] `gymowner`-Bottom-Bar auf `member-tabs + owner-tab` begrenzt.
- [x] `Ernährung` und `Plan` aus der `gymowner`-Bottom-Bar entfernt.

## Phase 2: Rollen- und Routing-Härtung
- [x] Rollenauflösung zentralisieren (einheitlicher Role-Resolver für UI, Router, Guards).
- [x] Guard-Tests ergänzen: `member`, `coach`, `admin`, `gymowner`, Mischfälle.
- [x] Deep-Link- und Named-Route-Verhalten für `Owner`-Flow testen.
- [x] Sicherstellen, dass `gymowner` auf allen relevanten Routen identisch zu `admin` behandelt wird, wo fachlich gewünscht.

## Phase 3: Owner-Hub ausbauen
- [x] `Owner`-Page als Hub-Komponente strukturieren (`OwnerQuickActions`, `OwnerInsights`, `OwnerDangerZone`).
- [x] Action-Cards statt reine Buttons (Status, Beschreibung, letzte Aktivität).
- [x] Feature-Flags für schrittweisen Rollout (`owner_hub_v1`, `owner_hub_v2`).
- [x] Owner-spezifische Telemetrie-Events hinzufügen (Klicks, Abbrüche, Zielseiten).

## Phase 4: Qualität und Wartbarkeit
- [ ] Widget-Tests für `Owner`-Tab und `Owner`-Seite ergänzen.
- [ ] Integrations-/Golden-Tests für Bottom-Bar-Konfiguration je Rolle ergänzen.
- [ ] Dokumentation aktualisieren: Rollenmatrix, Navigationsmatrix, QA-Checkliste.
- [ ] Refactoring: Tab-Konfiguration in deklarative Rollenmatrix auslagern (statt verteilt im Screen).

## Phase 5: UI/UX Launch-Ready
- [ ] Informationsarchitektur für `Owner` validieren (Top-Aufgaben, Häufigkeit, Priorität).
- [ ] Mobile-First Layout/Spacing/Typografie für `Owner`-Hub finalisieren.
- [ ] States vervollständigen: Loading, Empty, Error, No-Access.
- [ ] Accessibility prüfen (Kontraste, Focus-Order, Screenreader-Labels).
- [ ] Finales QA-Szenario pro Rolle vor Release durchführen.
