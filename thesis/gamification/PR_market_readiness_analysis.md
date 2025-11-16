# Market-Readiness-Analyse & Launch-TODOs (Dokumentations-PR)

## Kontext
Tap’em ist eine Flutter-/Firebase-basierte Fitness-App mit NFC-Workflows, Gamification und Multi-Tenant-Branding. Die Repository-Änderung dokumentiert den Einsatz von Prompt-Driven Development im Rahmen einer Masterarbeit.

## Original-Prompt
Kurzfassung: Erstelle eine ehrliche Analyse des aktuellen App-Stands, leite eine Market-Readiness-TODO-Liste (technisch + geschäftlich) ab und protokolliere die Ergebnisse in Markdown-Dateien für die Masterarbeit.

## Ziel des PRs
- Transparente Beschreibung der aktuellen Architektur, Features und Baustellen.
- Sammlung priorisierter technischer Tasks (MUST-HAVES, NICE-TO-HAVES, Post-Launch, Schulden) inklusive Aufwandsschätzungen.
- Checkliste nicht-technischer Launch-Aufgaben für Gründer ohne Vorerfahrung.
- Dokumentation des Prompts im Gamification-Log für die Masterarbeit.

## Geänderte/neu angelegte Dateien
- `thesis/market_readiness/app_market_readiness_analysis.md`
- `thesis/gamification/PR_market_readiness_analysis.md`

## Kurzfassung der Ergebnisse
- Repository deckt viele Features ab (Auth, NFC, Training, Gamification), aber wirkt eher wie ein Alpha-Build.
- State-Management mischt Provider und Riverpod; Bootstrapping ist komplex und anfällig für Fehler.
- Offline-Funktionalität beschränkt sich auf Session-Drafts, kein Konflikt-Handling.
- Firebase-Push/App-Check/Dynamic Links sind vorbereitet, aber nicht produktionsreif aktiviert.
- Firestore-Regeln sind umfangreich, dennoch müssen Auth-Claims und Gym-Zuordnungen stabilisiert werden.
- UX leidet unter fehlenden Lade-/Fehlerzuständen und fehlenden Branding-Regression-Tests.
- Technische TODOs priorisiert (A-D) mit groben Aufwandsschätzungen (M bis XL) und Abhängigkeiten.
- Nicht-technische Bereiche (Legal, Finanzen, Datenschutz, Stores, Marketing, Support, Analytics) erfordern umfangreiche Arbeit parallel zur Technik.

## Hinweise für die Masterarbeit
Diese Änderung dient als Beispiel, wie ein LLM aus einem großen Codebestand eine umfassende Markt-Readiness-Analyse ableitet und daraus Roadmaps erstellt. Sie kann als Referenz für Prompt-Driven Requirements-Discovery und als Dokumentation einzelner “virtueller PRs” genutzt werden.
