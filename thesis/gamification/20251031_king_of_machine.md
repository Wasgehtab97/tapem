# King/Queen of the Machine

## Prompt
Implementiere in der Flutter-App Tap’em (Firebase/Firestore, Spark-Plan ohne Cloud Functions) das Feature King/Queen of the machine auf der Device-Detailseite.

## Ziel & Kontext
- Gamification-Feature zur Anzeige von e1RM-Bestleistungen pro Gerät.
- Integration in bestehende Device-Ansicht inklusive neuer Datenhaltung und Sicherheit.
- Erweiterung der Nutzerprofile um Körperdaten für relative Auswertungen.

## Umsetzung / Änderungen (Kurz-Changelog)
- Neuer Firestore-Writepfad `machines/{machineId}/attempts` inkl. DTOs, Repository und `LeaderboardService`.
- Bottom-Sheet mit Tabs (Heute/Woche/Monat), Filterchips (Alle/w/m, Absolut/Relativ) und Top-Listings.
- Speicherung von Attempts beim Session-Save (inkl. Epley-e1RM, Gender, Körpergewicht) sofern `showInLeaderboard` aktiv.
- Erweiterte Profileinstellungen um Geschlecht und Körpergewicht sowie aktualisierte `SettingsProvider`-Logik.
- Anpassung der Firestore-Rules & Indexe, plus Emulator-Tests für die neuen Constraints.
- Unit-Tests für e1RM- und Zeitraum-Helper sowie Widget-Test für das Leaderboard-Sheet.

## Screenshots (Pfade)
- _Noch keine Screenshots erzeugt._

## Offene Punkte
- Nutzer-Onboarding für neue Körperdaten-Felder (Hinweis-Dialog?).
- Beobachtung der Firestore-Query-Performance bei großem Datenvolumen; ggf. weitere Indizes.
- UX-Review für relative Darstellung (ggf. zusätzliche Erläuterung im UI).
