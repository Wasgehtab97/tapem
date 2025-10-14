# PR3 – XP-Engine (Daily / Geräte / Muskeln)

## Prompt
- XP bei Sessionschluss vergeben (Daily, Device, Muscle)
- Bonuspunkte für prEvents in derselben Session
- Exercise→Muskel Mapping bereitstellen
- onSessionClosed Pipeline mit idempotenten Upserts erweitern
- sessions.summary.xpTotal aktualisieren
- Analytics: xp_awarded Event mit Breakdown
- Tests für Formel, Muskelaggregation und PR-Bonus

## Ziel/Kontext
Der dritte PR der XP-Serie verknüpft die neue Session-Schließpipeline mit einem nachvollziehbaren XP-System. Ziel ist eine konsistente Tagesaggregation pro Nutzer, die Geräte- und Muskelverteilung berücksichtigt und Boni aus den frisch erzeugten PR-Events einpreist. Sicherheit (Owner-only Reads) und Telemetrie runden die Integration ab.

## Ergebnis
- Neue `xp_engine`-Logik berechnet Basis-XP pro Set (inkl. RIR-Gewichtung) sowie PR-Boni und verteilt die Werte auf Geräte und Muskeln.
- `onSessionClosed` ruft die Engine auf, schreibt day-Docs unter `users/{uid}/xp/daily/days/{date}` idempotent und ergänzt `sessions.summary.xpTotal`.
- Analytics loggt `xp_awarded` inkl. Bonusübersicht und Top-Muskeln.
- Firestore-Regeln erlauben nur Owner-Reads für die XP-Tagesdokumente und akzeptieren `summary.xpTotal`.
- Unit- und Integrationstests decken Formel, Aggregation, PR-Bonus sowie Sicherheitsregeln ab.
