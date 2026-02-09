# Ranking Roadmap (Launch-Ready, Competitive-Game Niveau)

## Kontext
- Stand: 08. Februar 2026
- Zielbild: Das Ranking wird als eigenes Premium-Produkt innerhalb der App wahrgenommen.
- Design-Prinzip: Visuell und im Interaction-Design klar getrennt vom restlichen App-Look.
- Produktziel: User sollen Rankings nicht nur "mitnehmen", sondern aktiv und regelmäßig öffnen.

## Produktziele (Business + UX)
- [ ] `D1/D7 Retention` über Ranking-Flows messbar steigern.
- [ ] `Sessions pro Woche` im Ranking-Bereich signifikant erhöhen.
- [ ] `Time in Ranking` pro User erhöhen (mit klarer Informationsdichte, nicht nur Deko).
- [ ] `Trainings-Conversion` aus Ranking heraus steigern (CTA "Trainiere jetzt für Platz X").
- [ ] `Wahrgenommene Qualität` verbessern (Design, Geschwindigkeit, Klarheit, Fairness).

## Leitprinzipien (Non-Negotiables)
- [ ] Ranking als "Mini-App" mit eigenem visuellen System (Farben, Typo, Motion, Sounds/Haptics optional).
- [ ] In < 3 Sekunden muss jeder User erkennen:
- [ ] eigener Rang,
- [ ] Distanz zum nächsten Ziel,
- [ ] warum der Rang so ist (XP/Score-Transparenz),
- [ ] was als nächstes zu tun ist.
- [ ] Keine Dark Patterns: motivierend, aber fair, transparent und regelklar.
- [ ] Mobile-first, performant, auch auf Mid-/Low-End Geräten.

## Ist-Zustand (Kurzdiagnose)
- [ ] UI auf mehreren Ranking-Seiten aktuell Placeholder-/MVP-Charakter.
- [ ] Data/Rules-Mismatch blockiert Leaderboard-Reads in realen Member-Szenarien.
- [ ] Device-Leaderboard-Logik (Level/Sortierung) ist inkonsistent.
- [ ] Powerlifting-Ranking kann stale werden (Create-only-Updatepfad).
- [ ] `showInLeaderboard` ist nicht durchgängig synchron.
- [ ] Test-Coverage für Ranking-/Powerlifting-Kernpfade unvollständig.

## Zielarchitektur: "Ranking as a Product Surface"

### 1) Ranking Foundation Layer
- [ ] Neues Ranking-Theme-Modul anlegen (eigene Tokens, eigene Components, eigene Motion).
- [ ] Eigene Typografie für Ranking (Display + Data-Readable Body).
- [ ] Eigenes Spacing-/Density-System für Tabellen, Chips, Stats-Bars.
- [ ] Eigenes Icon-/Badge-System für Tiers, Progress, Delta, Streak.

### 2) Ranking Data Layer
- [ ] Einheitliche Ranking-Read-Modelle für:
- [ ] Experience,
- [ ] Device Level,
- [ ] Muscle Level,
- [ ] Powerlifting.
- [ ] Klare Trennung von:
- [ ] "raw stats",
- [ ] "leaderboard-ready projection",
- [ ] "user-facing explanations".
- [ ] Konsistente Sortierregeln zentral definieren (keine divergente Screen-Logik).

### 3) Ranking Navigation Layer
- [ ] Ranking-Hub mit klaren Einstiegen bauen:
- [ ] Experience,
- [ ] Device,
- [ ] Muscle,
- [ ] Powerlifting.
- [ ] Einheitliche Header-Struktur: eigener Kontext statt generische AppBar-Ästhetik.
- [ ] Schnellwechsel zwischen Modi (Gym/Friends/Season) ohne visuelle Brüche.

## Phase 0 - Strategie, Scope, Success Metrics
- [ ] Ranking-Vision schriftlich freigeben (1-Pager: "Warum öffnet man Rankings täglich?").
- [ ] KPI-Set finalisieren:
- [ ] Open Rate Ranking (daily/weekly),
- [ ] Wiederkehrrate,
- [ ] Scroll-Tiefe,
- [ ] CTA-Conversion zu Trainingsstart,
- [ ] Anteil User mit Ziel-Interaktion.
- [ ] V1-Scope locken:
- [ ] Must-have für Launch,
- [ ] Nice-to-have für Post-Launch.
- [ ] Feature-Flag-Strategie definieren (internal, beta gyms, full rollout).

## Phase 1 - Stabilisierung der Basis (Blocker vor UI-Polish)

### Security Rules + Zugriff
- [ ] Leaderboard-Read-Pfade für legitime Gym-Member sauber erlauben.
- [ ] Rules für `rank/*` und device leaderboard mit Produktlogik abgleichen.
- [ ] Dev/Prod Rules synchron halten (`firestore.rules` + `firestore-dev.rules`).
- [ ] Security-Testmatrix für Member/Admin/Friend/Coach ausführen.

### Datenkonsistenz
- [ ] Device-Leaderboard: Level korrekt aus persisted `level` + `xp` abbilden.
- [ ] Device-Leaderboard: Sortierung konsistent auf `level desc`, dann `xp desc`.
- [ ] Privacy-Toggle (`showInLeaderboard`) bei jedem relevanten Write sauber aktualisieren.
- [ ] Powerlifting-Rank-Update für Delete/Reset/Assignment-Änderungen robust machen.
- [ ] Cross-Gym Assignment-Mixing im Powerlifting-Provider beheben.

### Done-Kriterien Phase 1
- [ ] Keine `permission-denied` Fehler mehr in Standard-Ranking-Usecases.
- [ ] Ranking-Reihenfolge und Leveldarstellung fachlich korrekt.
- [ ] Opt-In/Opt-Out wirkt in allen Ranglisten sofort korrekt.
- [ ] Powerlifting-Rank entspricht immer den gültigen Quellen.

## Phase 2 - UX-Konzept & Informationsarchitektur

### Core User Jobs
- [ ] "Wo stehe ich gerade?" (Rang + Fortschritt).
- [ ] "Wie weit bis zum nächsten Platz/Tier?" (Gap + ETA-Hinweis).
- [ ] "Was bringt mir mein nächstes Training?" (klarer Reward-Ausblick).
- [ ] "Wofür werde ich heute belohnt?" (transparentes XP-System).

### Layout-Hierarchie pro Ranking-Seite
- [ ] Above the fold immer:
- [ ] eigener Rang,
- [ ] nächste Zielmarke,
- [ ] letzter Fortschritt (seit gestern/letzte Woche).
- [ ] Darunter:
- [ ] Top-Liste,
- [ ] Filter,
- [ ] Kontext-Info (Season/Gym/Friends),
- [ ] CTA zurück ins Training.
- [ ] Empty/Low-activity States als motivierende "Start now"-States designen.

### IA-Entscheidungen
- [ ] Einheitliche Filter-Sprache für alle Rankings (`Gesamt`, `Season`, `4W`, `8W`, `YTD`).
- [ ] Ranking-Typen in ein konsistentes Tab-/Segment-Modell bringen.
- [ ] Navigationskonsistenz zwischen Hub und Detailseiten sicherstellen.

## Phase 3 - Visuelles System (Independent Competitive Identity)

### Art Direction
- [ ] Moodboard definieren (Competitive, hochwertig, modern, nicht "fantasy kitsch").
- [ ] Farbwelten für:
- [ ] neutral background,
- [ ] status colors,
- [ ] tier colors,
- [ ] alert/fall/rise indicators.
- [ ] Visuelle Tier-Sprache festlegen (z. B. Bronze -> Elite).

### Design Tokens (Ranking-only)
- [ ] `ranking_color_*` Tokens.
- [ ] `ranking_gradient_*` Tokens.
- [ ] `ranking_glow_*` Tokens.
- [ ] `ranking_radius_*` Tokens.
- [ ] `ranking_motion_*` Tokens.
- [ ] `ranking_typography_*` Tokens.

### Component Library (Ranking-only)
- [ ] `RankingShell` (Background, Header, Context Strip).
- [ ] `PlayerRankCard` (Self Card, Tier Badge, Delta).
- [ ] `LeaderboardTable` (sticky header, dense rows, tie handling).
- [ ] `GapIndicator` (Differenz zum nächsten Rang).
- [ ] `RankDeltaChip` (+/- Position, XP Delta).
- [ ] `SeasonSwitch`, `ScopeSwitch`, `TimeRangeSwitch`.
- [ ] `MotivationCTA` ("Noch X XP bis Platz Y").

### Motion
- [ ] Soft entry animations (keine UI-Overload-Microanimations).
- [ ] Rank-change Transition (hoch/runter visuell klar).
- [ ] Pull-to-refresh mit eigenem Ranking-Motion-Muster.
- [ ] Performance-Limit definieren (60fps Ziel, Animationen degradierbar).

## Phase 4 - Page-by-Page Rebuild

### Ranking Hub (`RankScreen`)
- [ ] Placeholder-Karten durch Premium Hub-Module ersetzen.
- [ ] Jede Kachel mit:
- [ ] Current Standing,
- [ ] Last Change,
- [ ] Next Goal.
- [ ] Schnellzugriff auf "heute trainieren für X".

### Experience Ranking
- [ ] `DayXpScreen` als kompetitives Profilpanel neu bauen (keine simple stat card).
- [ ] `LeaderboardScreen` als echte Ranking-Tabelle mit Self-Anker bauen.
- [ ] Season/Overall/Range UX harmonisieren.
- [ ] Top-10 + eigener Rang außerhalb Top-10 visuell konsistent darstellen.

### Device Level Ranking
- [ ] `DeviceXpScreen` als Device-Progress-Grid/List mit klaren Prioritäten neu designen.
- [ ] `DeviceXpLeaderboardScreen` auf neues Table-System migrieren.
- [ ] Level-Chips durch hochwertiges Tier-/Level-Navigationselement ersetzen.
- [ ] Device-spezifische Progress-Empfehlungen ergänzen.

### Muscle Level Ranking
- [ ] `XpOverviewScreen`/Muscle Screen visuell in Ranking-System integrieren.
- [ ] Radar + Ranking-Interpretation kombinieren:
- [ ] stärkste/weakeste Muskelgruppe,
- [ ] nächste erreichbare Muskel-Meilensteine.
- [ ] "Trainingsvorschlag basierend auf Gap" ergänzen.

### Powerlifting Ranking
- [ ] Powerlifting Leaderboard als "Prestige Table" mit Lift-Splits redesignen.
- [ ] Total + Lift-Details + Selbstposition klar priorisieren.
- [ ] PR-Delta (neu/gleich/fallend) als first-class signal einführen.
- [ ] Assignment-UX in `PowerliftingScreen` auf Klarheit und Trust optimieren.

## Phase 5 - XP-System Redesign (UX-friendly + motivierend)

### XP-Ökonomie Prinzipien
- [ ] Einfach erklärbar ("Du bekommst XP für X, Y, Z").
- [ ] Sofortiges Feedback nach Session.
- [ ] Vermeidung von Frust-Spikes durch intransparente Penalties.
- [ ] Keine unfairen Exploits (Anti-Farming, Anti-Spam).

### Regelwerk überarbeiten
- [ ] XP-Quellen inventarisieren (Trainingstag, Session, Streak, Challenges, Penalties).
- [ ] Jede Quelle bewerten:
- [ ] Motivation,
- [ ] Exploit-Risiko,
- [ ] Verständlichkeit.
- [ ] Neue XP-Formel Versionieren (`xp_ruleset_v2`).
- [ ] Season-spezifische Balancing-Parameter definieren.

### Feedback-UX
- [ ] Post-Workout Reward-Summary:
- [ ] erhaltene XP,
- [ ] Komponenten,
- [ ] Rank Impact.
- [x] "Nächster erreichbarer Rang in X XP" global anzeigen.
- [ ] Negative Events (Penalty) mit klarer Begründung kommunizieren.

### Anti-Exploit + Fairness
- [ ] Session-Dedupe und "already credited"-Pfad robust testen.
- [ ] Multi-Gym/cross-device Missbrauchspfade abfangen.
- [ ] Regeln dokumentieren und in App transparent machen.

## Phase 6 - Engagement Loops (ohne UX-Manipulation)
- [ ] Weekly Highlights:
- [ ] "größter Sprung",
- [ ] "knapp verpasst",
- [ ] "persönlicher Rekord".
- [ ] Soft Notifications:
- [ ] Rang verloren,
- [ ] Rang verbessert,
- [ ] Season-Ende Reminder.
- [ ] Social Layer:
- [ ] Friends-View mit Compare-Modus,
- [ ] "Beat this score" CTAs.
- [ ] Comeback Loops:
- [ ] Rückkehr-Message mit realistischem nächsten Ziel.

## Phase 7 - Backend, Modellierung, Projektionen

### Data Model
- [ ] Einheitliches `leaderboard_projection` Konzept definieren (pro Rankingtyp).
- [ ] Denormalisierte Felder für schnelle Reads (username/avatar/tier/rankDelta).
- [ ] Aggregationen so bauen, dass UI ohne N+1 User-Reads auskommt.

### Cloud Functions / Server-Prozesse
- [ ] Powerlifting-Recompute Jobs ergänzen (onCreate/onDelete/onAssignmentChange).
- [ ] Optional: Scheduled leaderboard materialization für große Gyms.
- [ ] Retry- und Idempotency-Strategie dokumentieren.

### Firestore Indizes + Query Costs
- [ ] Alle Ranking-Queries indexseitig absichern.
- [ ] Query-Kostenbudget definieren (pro Screen Open).
- [ ] Paginierung/Top+Self Muster für große Leaderboards implementieren.

## Phase 8 - Performance, Offline, Reliability
- [ ] Skeleton States für alle Ranking-Views.
- [ ] Smart caching pro Rankingtyp (TTL + invalidation events).
- [ ] Background prefetch für häufig geöffnete Leaderboards.
- [ ] Offline-Fallback mit "last updated" Kennzeichnung.
- [ ] Crash- und Error-Handling für alle Ranking-Pfade vereinheitlichen.

## Phase 9 - Analytics, Experimentation, Telemetry
- [ ] Event-Taxonomie definieren:
- [ ] open, filter_change, row_tap, cta_train, refresh, share.
- [ ] Funnel aufsetzen: Hub -> Detail -> CTA -> Training gestartet.
- [ ] Cohort-Auswertung: aktive vs. passive Ranking-Nutzer.
- [ ] A/B-Tests vorbereiten:
- [ ] Reward copy,
- [ ] gap visualization,
- [ ] CTA wording.
- [ ] Qualitätssignale tracken:
- [ ] permission errors,
- [ ] stale data incidents,
- [ ] load times.

## Phase 10 - QA, Tests, Launch-Gates

### Testabdeckung
- [ ] Unit-Tests:
- [ ] XP-Regeln,
- [ ] Sortierlogik,
- [ ] Rank-Tie Handling.
- [ ] Widget/Golden-Tests:
- [ ] Hub,
- [ ] Experience,
- [ ] Device,
- [ ] Muscle,
- [ ] Powerlifting.
- [ ] Integration-Tests:
- [ ] Member/Admin/Friend-Flows,
- [ ] Privacy on/off,
- [ ] Season switch.
- [ ] Functions-Tests:
- [ ] Powerlifting recompute paths,
- [ ] idempotent XP updates.

### Launch-Gates (must pass)
- [ ] Keine kritischen Rule-/Permission-Fehler in Top-Usecases.
- [ ] Alle Ranking-Seiten < definierter Load-Time-Zielwert.
- [ ] Kein fachlicher Widerspruch zwischen Stats und Leaderboards.
- [ ] UX-Abnahme durch Product + Design + QA.
- [ ] Monitoring + Rollback plan dokumentiert.

## Phase 11 - Rollout Plan
- [ ] Stage 1: Internal dogfood.
- [ ] Stage 2: 1-3 Pilot-Gyms mit aktivem Monitoring.
- [ ] Stage 3: 25% Rollout via Flag.
- [ ] Stage 4: 100% Rollout.
- [ ] Pro Stage:
- [ ] KPI Review,
- [ ] Error Budget Check,
- [ ] qualitative User-Feedback-Auswertung.

## Phase 12 - Post-Launch Iteration
- [ ] Erste 14 Tage: täglicher Health-Check.
- [ ] Nach 30 Tagen: XP-Balance Review + Ranking-UX Review.
- [ ] Season-Ende Retro:
- [ ] was hat Retention erhöht,
- [ ] was hat User verwirrt,
- [ ] was wurde nicht genutzt.
- [ ] V2-Backlog priorisieren (nur datengetrieben).

## Konkrete Deliverables (Artefakte)
- [ ] `Ranking PRD` (Ziele, Scope, KPI, Flows).
- [ ] `Ranking Design Spec` (Tokens, Komponenten, Motion, Copy).
- [ ] `XP Ruleset v2 Spec` (Formel + Beispiele + Edge Cases).
- [ ] `Security/Rules Spec` für Ranking-Reads/Writes.
- [ ] `Analytics Tracking Plan`.
- [ ] `QA Testplan + Launch Checklist`.

## Priorisierte Reihenfolge (empfohlen)
- [ ] 1. Phase 1 (Blocker fixen: Rules, Korrektheit, Konsistenz).
- [ ] 2. Phase 2-3 (IA + visuelle Identität finalisieren).
- [ ] 3. Phase 4 (alle Ranking-Seiten auf neues System heben).
- [ ] 4. Phase 5 (XP-System überarbeiten und verständlich machen).
- [ ] 5. Phase 6-9 (Engagement, Analytics, Performance).
- [ ] 6. Phase 10-12 (QA-Gates, Rollout, Iteration).

## Optionaler Team-Schnitt (für saubere Umsetzung)
- [ ] Product: KPI, Scope, XP-Regeln, Fairness-Prinzipien.
- [ ] Design: Art Direction, Tokens, Components, Motion.
- [ ] App: UI-System + Screen-Migration.
- [ ] Backend: Projection/Rules/Functions/Indexes.
- [ ] QA: Matrix, Automatisierung, Launch-Freigabe.

## Definition of Done (Gesamtprojekt)
- [ ] Ranking ist visuell eigenständig, konsistent und hochwertig.
- [ ] Alle Ranking-Typen zeigen korrekte, faire und erklärbare Daten.
- [ ] XP-System ist verständlich, motivierend und exploit-resistent.
- [ ] Performance, Stabilität und Monitoring sind launch-ready.
- [ ] KPI-Trend bestätigt, dass User Rankings aktiv und regelmäßig nutzen.

## Fortschritt (Start-Implementierung)
- [x] Device-Leaderboard auf `level desc`, dann `xp desc` umgestellt.
- [x] Device-Leaderboard-Leveldarstellung auf persistiertes `level`/`xp` korrigiert.
- [x] `showInLeaderboard` wird bei Leaderboard-XP-Updates aktiv synchron gehalten.
- [x] Powerlifting-Assignments auf Active-Gym gefiltert (kein Cross-Gym-Mixing mehr).
- [x] `clearAssignments()` löscht nur Assignments des aktiven Gyms.
- [x] Powerlifting-Labelauflösung gym-spezifisch stabilisiert.
- [x] Firestore Rules (dev/prod) für öffentliche, gym-interne Leaderboard-Reads angepasst.
- [x] Powerlifting-Recompute bei Log-Delete und Assignment-Änderungen ergänzt.
- [x] `LeaderboardScreen` visuell auf eigenständigen Competitive-Look umgebaut (Hero, Toggle-Gruppen, hochwertige Rows).
- [x] `RankScreen` Hub visuell auf eigenständigen Competitive-Look umgebaut (Intro-Hero + neue Entry-Cards).
- [x] `DeviceXpScreen` Übersicht visuell auf eigenständigen Competitive-Look umgebaut (Hero-Stats + neue Device-Cards).
- [x] `DeviceXpLeaderboardScreen` auf Competitive-Look migriert (Hero-Stats, Level-Ladder, hochwertige Progress-Rows).
- [x] `DayXpScreen` als Experience-Dashboard ausgebaut (Hero, Trend-Chart, KPI-Panel, klarer Leaderboard-CTA).
- [x] `MuscleGroupScreenNew` in Ranking-Visual-System integriert (Hero, Radar-Panel, hochwertige Muskel-Detailkarten).
- [x] `PowerliftingLeaderboardScreen` als Prestige-Leaderboard neu gestaltet (Hero, Podium, Top-10-Tabelle, Self-Highlight).
- [x] `DeviceLeaderboardListScreen` als hochwertiger Ranking-Entrypoint neu gestaltet.
- [x] Gemeinsame Ranking-UI-Foundation extrahiert (`ranking_ui.dart`: Gradient-Background, Hero-Stat-Tile, Segment-Chip) und in Kern-Screens ausgerollt (`RankScreen`, `LeaderboardScreen`, `DayXpScreen`, `DeviceXpScreen`, `DeviceXpLeaderboardScreen`, `PowerliftingLeaderboardScreen`, `MuscleGroupScreenNew`, `DeviceLeaderboardListScreen`).
- [x] `RankingHeroCard` und `RankingSurfacePanel` als weitere Foundation-Bausteine ergänzt und in Hero-/Panel-Komponenten der Ranking-Screens integriert.
- [x] XP-Ruleset-Versionierung gestartet (`xp_ruleset_v2` + Version) und bei XP-Ledger-/Stats-Writes sowie `SessionXpAward` verankert.
- [x] Gezielte XP-Regressionstests grün (`training_day_xp_engine_test`, `firestore_xp_source_test`).
- [x] XP-Transparenz-Flow implementiert: `DayXpBreakdown` (Komponenten, Penalties, Ruleset) von Firestore bis `DayXpScreen` inkl. neuer UI-Aufschlüsselung.
- [ ] End-to-end-Verifikation via Emulator-Suite für Rules/Functions noch ausstehend.
