Was sagt Codex: Was MUSS in der App noch passieren (technisch)?

Die TODOs sind in 4 Kategorien aufgeteilt:
A = MUSS, B = Nice-to-have für Launch, C = nach Launch, D = Schulden.

Kategorie A – MUST-HAVES (ohne das: kein ernsthafter Launch)

1. Stabiler Auth- & Gym-Wechsel-Flow

Login/Registrierung/Gym-Wechsel robust machen.

Claims synchronisieren, Sessions sauber „aufräumen“, halb-validen Zustand vermeiden.

Warum: Ohne sicheren und zuverlässigen Login → Datenleaks & frustrierte Nutzer.

2. Einheitliche State-Management-Strategie & Bootstrapping

Entscheiden: Provider oder Riverpod (oder klare Brücke).

Bootstrap in main.dart aufräumen, DI sauber strukturieren.

Ziele: weniger Race Conditions, nachvollziehbarer Start der App.

3. Richtiges Offline- & Sync-Konzept

Weg von „nur Drafts“ hin zu klar definiertem Offline-Verhalten

Was geht offline?

Wie werden Sessions später synchronisiert/zusammengeführt?

Wichtig: Fitness-App ohne verlässliches Offline kann zu Datenverlust & Vertrauensbruch führen.

4. Produktionsreifes Firebase-Setup

Push aktivieren & durchtesten (kEnablePush),

App Check sauber konfigurieren,

Dynamic Links/Deep Links richtig verdrahten,

Secret-Handling für Prod.

Ohne: Funktionen gehen nicht wirklich, oder du läufst in Security-/Review-Probleme.

5. Fehler-/Crash-Monitoring & Analytics

Crashlytics/Performance, strukturierte Logs.

KPIs tracken (Retention, erfolgreiche Workouts, NFC-Nutzung).

Ohne Telemetrie fliegst du blind nach Launch.

6. Security-Review von Firestore-Regeln & Functions

End-to-End prüfen, ob die Regeln wirklich zu allen Queries passen.

Fokus: Multi-Tenant-Isolation, XP-Cheating, Friends/Chats, NFC-Manipulation.

Ohne: großes Risiko für Daten- und Vertrauensprobleme.

Codex-Schätzung: MUST-HAVES ≈ 8–12 Wochen Netto-Engineering für 1–2 erfahrene Devs.

Kategorie B – Nice-to-have für Launch

1. Einheitliche Lade- und Fehlerzustände

Reusable Loading-/Error-Widgets & Skeletons.

Sorgt für professionelles Gefühl und weniger Support-Fragen.

2. Branding- & Theme-Regression-Tests

Sicherstellen, dass jede Gym-Brand wirklich korrekt aussieht.

Gerade wichtig für B2B-Studios, die Wert auf ihr Branding legen.

3. Onboarding & Permission-Education

Erklären, warum NFC/Push/Location wichtig sind.

Steigert die Rate an akzeptierten Permissions und reduziert Verwirrung.

Kategorie C – Nach Launch (Verbesserungen / Wachstum)

1. Social/Community-Iterationen

Moderation, Reporting, Anti-Spam, bessere Feeds.

Wird wichtig, sobald echte Nutzer und mehr Volumen da sind.

2. Advanced Gamification-Balancing

XP-Kurven, Anti-Cheat, A/B-Tests für Belohnungslogik.

Ist nicht nötig, um überhaupt zu starten, aber wichtig, um Engagement hochzuhalten.

3. Feature Parity mit Web/Admin

Studio-Admin-Dashboard, Multi-Device-Sync usw.

Erleichtert späteren Betrieb, aber nicht zwingend für die erste Pilotphase.

Kategorie D – Technische Schulden & Risiken

1. Provider vs. Riverpod auflösen

Langfristig muss dieser Mix weg oder stark strukturiert werden.

Sonst bleibt die Codebase schwer erklärbar für neue Devs.

2. Firestore-Abfragen zentralisieren

Repositories statt „Firestore überall“.

Bessere Testbarkeit, weniger Duplikate, leichteres Offline-Handling.

3. Mocks für NFC & Geräte

Simulationsschicht, um Hardware-unabhängig testen zu können.

Spart enorm Zeit im QA-Prozess.