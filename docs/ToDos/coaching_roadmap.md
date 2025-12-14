## Coaching-Feature Roadmap

Diese Roadmap beschreibt die vollständige, saubere und effektive Implementierung des Coaching-Features in der bestehenden tapem-App. Sie ist bewusst detailliert formuliert, damit wir jederzeit:

- den Gesamtüberblick behalten,
- den aktuellen Stand dokumentieren können,
- einzelne Arbeitspakete klar abgrenzen und priorisieren können.

Status-Legende (bitte pflegen):

- [ ] nicht gestartet
- [~] in Arbeit
- [x] abgeschlossen

---

## Phase 1: Grundlagen & Architektur

Ziel: Rollenmodell, Datenmodell und grundlegende Architektur für Coaching sauber in das bestehende System integrieren, ohne direkt alle UI-Features zu bauen.

### 1. Produkt-Scope & Ziele schärfen

- [x] Konkrete Coaching-Szenarien definieren:
  - 1:1 Coaching (Coach ↔ einzelner Client)
  - Studio-interne Coaches (Coaches eines Studios coachen Mitglieder dieses Studios)
  - Externe Coaches (Coach ist nicht direkt im Studio-Angestellten-System, aber betreut Mitglieder)
- [x] MVP-Scope definieren:
  - Welche Funktionen gehören zwingend in Version 1?
  - Welche Funktionen kommen ausdrücklich später (z.B. Chat, Zahlungsabwicklung, automatische Reports)?
- [x] Produktziele/KPIs festlegen:
  - Kern-KPIs für V1:
    - Anzahl aktiver Coaching-Beziehungen pro Gym.
    - Anteil der Clients mit mindestens einem aktiven Trainingsplan.
    - Durchschnittliche Anzahl abgeschlossener Einheiten pro Client und Woche.
    - Anteil der Coach-Clients, die in den letzten 14 Tagen aktiv waren.
  - Diese KPIs werden initial über bestehende Stats/Exports beobachtet; spätere automatisierte Dashboards sind als Erweiterung vorgesehen.

### 2. Rollen- & Berechtigungsmodell erweitern

- [x] Bestehendes Rollenmodell analysieren (User-Rollen, Permissions, Guards/Middleware).
- [x] Neue Rolle `coach` ergänzen:
  - Rolle im Usermodell/Identity-System hinzufügen
  - Migrations/Seeding anpassen (z.B. erste Test-Coaches anlegen)
- [x] Rechte definieren und dokumentieren:
  - `member`:
    - Vollzugriff auf eigene Profildaten, Trainingspläne und Progress.
    - Kann interne Coaches im Gym auswählen und externe Coaches per E-Mail einladen.
    - Kann Coach-Client-Beziehungen beenden und eigene Coaching-Einladungen verwalten.
  - `coach`:
    - Kann nur Trainingsdaten von Clients einsehen/bearbeiten, mit denen eine aktive `coachClientRelation` besteht.
    - Kann neue Pläne für diese Clients anlegen und bestehende Pläne im Rahmen der Berechtigungen anpassen.
    - Sieht keine Daten anderer Mitglieder ohne aktive Beziehung.
  - `admin`:
    - Kann Studio-spezifische Konfiguration und Memberships verwalten.
    - Kann Coaching-Beziehungen und Einladungen im jeweiligen Gym einsehen und in Ausnahmefällen übersteuern (z.B. Beenden von Relationen).
- [x] Backend-Absicherung (erste Stufe):
  - Neue `coach`-Rolle im Auth-State verfügbar gemacht (`isCoach` Getter).
  - Firestore-Sicherheitsregeln für `coachClientRelations` ergänzt (Lesen/Schreiben nur für beteiligten Coach/Client oder Admin).
  - Weitere Detailregeln für konkrete Coaching-APIs folgen in späteren Phasen.

### 3. Datenmodell & Beziehungen designen

- [x] Bestehendes Datenmodell der Trainingsfunktionen analysieren:
  - Wie sind Trainingspläne, Workouts, Sets, Stats aktuell gespeichert?
  - Welche Entitäten können wiederverwendet, welche müssen erweitert werden?
- [x] Neue/erweiterte Entitäten definieren (erste Stufe, implementiert im Code):
  - `User` (Erweiterung): Rolle `coach` über bestehendes `role`-Feld abgebildet; zusätzliche Getter (`isCoach`, `isMember`).
  - `CoachClientRelation`:
    - Dart-Domainmodell `CoachClientRelation` mit Feldern `gymId`, `coachId`, `clientId`, `status`, Timestamps, Grund/Notiz.
    - Persistenz als Sammlung `coachClientRelations` in Firestore (top-level).
  - `TrainingPlan`:
    - Bestehendes User-basiertes Trainingsplanmodell bleibt Grundlage; Verknüpfung mit Coach/Client erfolgt in späteren Phasen.
  - `TrainingPlanVersion`:
    - Konzeptionell vorgesehen, aber noch nicht implementiert (kommt in späterer Phase, sobald Plan-Änderungslogik gebaut wird).
  - `ProgressEntry`:
    - Bestehende Trainings-Logs und Stats werden weiterverwendet; Coach-spezifische Auswertung folgt später.
- [x] Datenschutz/Ownership-Regeln festlegen:
  - Pläne gehören fachlich immer dem Client (Owner = Nutzer unter `users/{uid}`), auch wenn sie von einem Coach erstellt oder bearbeitet wurden.
  - Beim Coach-Wechsel bleiben bestehende Pläne beim Client erhalten; der alte Coach verliert den Schreibzugriff (da keine aktive Relation mehr besteht).
  - Progress-Daten werden wie bisher langfristig gespeichert, um Trainingshistorie und Analytics zu ermöglichen; eine genauere Aufbewahrungsdauer kann bei Bedarf später policy-seitig festgelegt werden.

### 4. Technische Architektur & Schnittstellen

- [x] Architekturentscheidung dokumentieren:
  - Coaching-Domäne liegt im Frontend unter `lib/features/coaching` mit klarer Trennung in `domain`, `data`, `application`.
  - Firestore verwendet eine neue Collection `coachClientRelations` als zentrale Quelle für Coach-Client-Beziehungen.
  - Trainingspläne bleiben bei den Users (`users/{uid}/training_plans`); Coaching verknüpft später Pläne mit Relationen.
- [x] API-Design für Coaching-Funktionalität (erste Stufe, im Code abgebildet):
  - Repository-Interface `CoachingRepository` mit Kernoperationen:
    - `getRelationsForCoach`, `getRelationsForClient`
    - `requestCoaching`, `updateRelationStatus`
  - Firestore-Implementierung `FirestoreCoachingSource` + `CoachingRepositoryImpl`.
- [x] Fehler- und Rechtehandling definieren (Grundlage):
  - Zugriff auf `coachClientRelations` nur für beteiligten Coach/Client oder Admin (über Firestore-Regeln).
  - Status-Felder (`pending`, `active`, `ended`, `rejected`) im Domainmodell vorgesehen; Detailfehlercodes folgen bei den konkreten Flows.

---

## Phase 2: Coach-Client-Beziehungen & Einladungen

Ziel: Saubere Mechanik, wie Coaches und Clients miteinander verbunden werden – sowohl intern im Studio als auch mit externen Coaches.

### 5. Zuordnung Coach ↔ Client (intern im Studio)

- [x] Studio-Kontext klären:
  - Nutzer sind bereits über `gymCodes` und `gyms/{gymId}/users/{uid}`-Memberships an ein Studio gebunden.
  - Coaches werden perspektivisch ebenfalls über diese Memberships/Role-Felder einem Gym zugeordnet (Admin setzt Rolle im Membership-Doc).
- [x] Flows für Studio-interne Beziehungen (Backend-Grundlage, UI folgt in Phase 4):
  - [x] Client wählt Coach:
    - Persistenz-Ebene: `coachClientRelations`-Collection in Firestore mit Feldern (`gymId`, `coachId`, `clientId`, `status`, Timestamps, Reason/Notiz).
    - Anfrage-Flow im Backend: `requestCoaching(gymId, coachId, clientId)` im `CoachingRepository`, implementiert über `FirestoreCoachingSource`.
  - [x] Coach verarbeitet Anfragen:
    - Backend stellt `getRelationsForCoach(coachId)` und `getRelationsForClient(clientId)` bereit (Riverpod-Provider `coachRelationsProvider`/`clientRelationsProvider`).
    - `updateRelationStatus(relationId, status, endedReason)` kann später von UI genutzt werden, um Anfragen anzunehmen/abzulehnen.
  - [x] Statuswechsel (erste fachliche Regeln definiert, technisch vorbereitet):
    - Status-Feld erlaubt Werte `pending`, `active`, `ended`, `rejected` (Domainmodell).
    - Erstellung immer mit Status `pending` (durch Firestore-Regeln erzwungen).
    - Übergänge `pending` → `active` / `rejected` und `active` → `ended` werden über `updateRelationStatus` abgebildet (UI-Logik folgt).
  - [x] Relation beenden (Berechtigungen serverseitig geregelt):
    - Firestore-Regeln erlauben Updates nur für beteiligten Client, zugehörigen Coach mit `role == coach` im Gym oder Admin des Gyms.
    - Löschen ist auf Client/Admin begrenzt, um Missbrauch zu vermeiden.
    - Detailverhalten bzgl. Trainingsplänen beim Beenden wird in Phase 3/4 konkretisiert (derzeit Konzept: Pläne bleiben als Historie beim Client, Coach verliert Schreibzugriff).

### 6. Externe Coaches einladen

- [x] Einladungskonzept:
  - Client kann einen externen Coach per E-Mail einladen (`InviteExternalCoachScreen`).
  - Technische Grundlage: Collection `coachInvites` (top-level) mit Feldern (`gymId`, `clientId`, `email`, `status`, `createdAt`, optional `acceptedAt`, `coachId`).
  - Dart-Domainmodell `CoachInvite` + `FirestoreCoachInviteSource` und Riverpod-Provider `clientCoachInvitesProvider`/`pendingInvitesForCoachEmailProvider` sind implementiert.
  - Externe Coaches sehen ihre offenen Einladungen über den `ExternalCoachInvitesScreen` und können diese dort annehmen.
- [x] Registrierung für externe Coaches:
  - Entscheidung für V1: Externe Coaches registrieren sich wie normale Nutzer und aktivieren die Coach-Rolle über den „Coach“-Schalter in den Einstellungen (`coachEnabled`), es gibt keinen separaten Onboarding-Flow.
  - Beim Annehmen einer Einladung wird automatisch eine Coach-Client-Beziehung (`coachClientRelations`) mit Status `active` angelegt; weitere aktive Beziehungen des Clients im selben Gym werden dabei in `ended` überführt (siehe Business-Regeln in Punkt 7).
- [x] Rechte für externe Coaches:
  - Firestore-Regeln erlauben externen Coaches den Zugriff auf Einladungen, wenn ihre Login-E-Mail der in der Einladung hinterlegten E-Mail entspricht (`request.auth.token.email`).
  - Zugriff auf Trainingsdaten der eingeladenen Clients erfolgt identisch zu internen Coaches über aktive `coachClientRelations` und `hasActiveCoaching(...)`; Studio-spezifische Admin-Funktionen bleiben Admins vorbehalten.

### 7. Business-Regeln für Beziehungen

- [x] Maximale Anzahl Coaches pro Client definieren:
  - Umsetzung V1: pro (`gymId`, `clientId`) gibt es maximal einen aktiven Coach; mehrere `pending`-Anfragen sind erlaubt.
  - Aktiviert ein Coach eine Relation (`status = 'active'`), werden andere aktive Relationen des Clients im gleichen Gym automatisch auf `ended` gesetzt (Business-Logik in `FirestoreCoachingSource.updateRelationStatus`).
  - Spätere Erweiterung (z.B. Secondary Coaches) bleibt möglich, würde dann ein angepasstes Regelwerk erfordern.
- [x] Konsistenzregeln:
  - Ein Client kann weitere Coaches anfragen, auch wenn bereits ein aktiver Coach existiert – die neuen Relationen bleiben zunächst `pending`.
  - Beim Coach-Wechsel bleiben Pläne und Progress-Daten beim Client erhalten; der alte Coach verliert den Schreibzugriff, sobald seine Relation nicht mehr `active` ist (siehe Phase 3/11 und Firestore-Regeln).

---

## Phase 3: Trainingspläne & Progress (Kern-Coaching-Funktionalität)

Ziel: Coaches können für ihre Clients Trainingspläne anlegen, fortlaufend anpassen und den Fortschritt nachvollziehen.

### 8. Trainingsplan-Modell & Logik

- [x] Datenstruktur für Trainingspläne definieren/überprüfen:
  - Bestehendes Trainingsplan-Modell (`TrainingPlan`) wird genutzt und um optionale Felder erweitert:
    - `coachId`, `clientId`, `coachingRelationId` zur sauberen Verknüpfung mit Coaching-Beziehungen.
  - Pläne liegen weiterhin unter `users/{uid}/training_plans/{planId}` und enthalten ein `gymId`-Feld.
- [x] Versionierung (optional für V1, aber konzeptionell klären):
  - Entscheidung für V1: keine technische Versionierung; es gibt je Plan genau einen aktuellen Stand mit `createdAt`/`updatedAt`.
  - Vollständige Versionierung (mit Historie pro Änderung) wird bei Bedarf in einer späteren Phase (Logging & Auditing) umgesetzt.
- [x] Status eines Plans:
  - Entscheidung für V1: impliziter Status – angelegte Pläne gelten als „active“, Deaktivierung/Archivierung erfolgt rein über UI/Usage (kein separates Status-Feld in Firestore).
  - Explizite Status-Felder (`draft`, `scheduled`, `completed/archived`) bleiben als Option für eine spätere Ausbaustufe vorgesehen.

### 9. Plan-Management für Coaches (Backend)

- [x] APIs für Trainingspläne:
  - Basis-CRUD für Trainingspläne ist über `TrainingPlanRepository` und `FirestoreTrainingPlanSource` vorhanden und wird auch für Coaching genutzt.
  - Feld-Set `coachId`, `clientId`, `coachingRelationId` erlaubt, Pläne eindeutig einer Coach-Client-Beziehung zuzuordnen.
  - Provider `clientTrainingPlansProvider` lädt Pläne eines beliebigen Clients (für Coach-Ansichten); Plan-Erstellung für Clients erfolgt über den bestehenden Plan-Builder mit Coach-Metadaten.
- [x] Rechteprüfung:
  - Firestore-Regeln erlauben Coaches mit aktiver `coachClientRelation` (Status `active`) das Lesen und Bearbeiten von `users/{clientId}/training_plans/{planId}` und dem zugehörigen `meta/stats`-Dokument.
  - Helper `hasActiveCoaching(gymId, clientId)` nutzt deterministische Relation-IDs (`gymId_coachId_clientId`), um die Berechtigung serverseitig zu prüfen.
  - Fallback-Regeln bleiben unverändert owner-orientiert; nur spezifische `training_plans`-Matches erlauben den Coach-Zugriff.

### 10. Progress-Erfassung & -Auswertung

- [x] Daten erfassen:
  - Workouts/Trainingsdaten werden wie bisher über bestehende Logging-Mechanismen erfasst; Trainingspläne enthalten nun optionale `coachId`/`coachingRelationId`, sodass Zuordnung zu einem Coaching-Kontext möglich ist.
- [x] Progress-Entitäten:
  - Entscheidung für V1: Es werden keine zusätzlichen Entitäten eingeführt; Progress basiert auf der bestehenden Stats-Struktur (`training_plans/{planId}/meta/stats`) und den dort gepflegten Aggregaten (z.B. `completions`, `firstCompletedAt`, `lastCompletedAt`).
  - Eigene Modelle wie `ProgressEntry`/`SummaryEntry` bleiben als optionale spätere Erweiterung vorgesehen, falls feinere Historien- oder Analysefunktionen benötigt werden.
- [x] APIs für Progress:
  - Lesen: Firestore-Regeln erlauben Coaches mit aktiver Relation das Lesen der Trainingsplan-Stats (`meta/stats`) eines Clients.
  - Schreiben: bleibt beim Client bzw. bestehenden Mechanismen (`incrementCompletion`), Coaches schreiben keine Progress-Daten direkt.
- [x] Basic-Analytics für V1:
  - Pro Plan werden im Coaching-Client-Detail die Gesamt-Abschlüsse und Ø-Abschlüsse/Woche angezeigt.
  - Zusätzlich gibt es einen aggregierten „Überblick“ pro Client (Anzahl Pläne, Abschlüsse gesamt, Ø Abschlüsse pro Woche, letzte Aktivität).

### 11. Kontinuierliche Anpassungen

- [x] Anpassungslogik:
  - Coaches können dank der Firestore-Regeln laufende Pläne ihrer aktiven Clients bearbeiten (Exercises, Volumen, Struktur).
  - Entscheidung für V1: Änderungen gelten für zukünftige Nutzung des Plans; bereits absolvierte Sessions bleiben unverändert in den vorhandenen Logs/Stats.
- [x] Historie/Transparenz:
  - Entscheidung für V1: kein separates Änderungslog oder Versionierung auf UI-/Datenebene; Transparenz erfolgt über Plan-Inhalte und Zeitstempel (`createdAt`/`updatedAt`).
  - Ein echtes Änderungslog (Wer hat was wann geändert?) wird gebündelt mit den Themen Logging & Auditing in Phase 5/16 betrachtet.

---

## Phase 4: Coaching-UI (Coach-Sicht & Client-Sicht)

Ziel: Eine eigene „Coaching“-Sektion in der App, in der Coaches effizient arbeiten können, und eine klare Client-Sicht auf den Coach und den Plan.

### 12. Coaching-Dashboard (Coach-Sicht)

- [x] Coaching-Hauptnavigation:
  - Eigener Tab `Coaching` in der Bottom-Navigation, der nur für Nutzer mit Rolle `coach` sichtbar ist (`auth.isCoach`).
  - Screen `CoachingHomeScreen` zeigt zentral alle Coach-Client-Beziehungen des Coaches.
- [x] Dashboard-Übersicht:
  - Liste aller Coaching-Clients (aktive, ausstehende, beendete Beziehungen) mit Name, Gym-ID und Status.
  - Pro Client:
    - Name über `userDisplayNameProvider` (Username → E-Mail → ID).
    - Status-Chip (aktiv, Anfrage offen, beendet, abgelehnt).
    - Anzeige der Anzahl vorhandener Trainingspläne.
  - Detailansicht `CoachingClientDetailScreen` pro Client mit:
    - Kopfbereich zum Status und Gym-Kontext.
    - Liste der Trainingspläne inklusive einfacher Progress-Infos (Anzahl Übungen, Anzahl Abschlüsse).
- [x] Filter-/Suchfunktionen:
  - Suche nach Client-Name direkt im `CoachingHomeScreen` (Textfeld in der AppBar).
  - Status-Filter über Choice-Chips für „Alle“, „Aktiv“, „Anfragen“.

### 13. Client-Detailseite für Coaches

- [x] Grundaufbau:
  - Detail-Screen `CoachingClientDetailScreen` mit Sektionen:
    - Coaching-Kopfbereich (`_ClientHeader`) mit Status (aktiv, Anfrage, beendet, abgelehnt) und Gym-ID.
    - Abschnitt „Trainingspläne“ mit Liste aller Pläne des Clients.
- [x] Übersicht:
  - Fokus auf Plan-Liste, Statusinformationen sowie einem kompakten „Überblick“-Block mit aggregierten Kennzahlen (Anzahl Pläne, Abschlüsse gesamt, Ø Abschlüsse/Woche, letzte Aktivität).
  - Erweiterte Visualisierungen (z.B. Graphen über die Zeit) bleiben für spätere Ausbaustufen vorgesehen.
- [x] Trainingsplan-Tab / -Sektion:
  - Planstruktur (Name, Anzahl Übungen) wird angezeigt.
  - Coach kann über bestehende Plan-Detail- und Builder-Mechanismen Pläne einsehen und bearbeiten (soweit durch Regeln erlaubt).
- [x] Progress-Tab / -Überblick:
  - Basis-Progress pro Plan wird über `trainingPlanStatsProvider` eingebunden (z.B. „n× abgeschlossen“).
  - Zusätzlich eigenständiger Abschnitt „Progress-Überblick“ mit zusammengefassten Stats pro Plan (Abschlüsse und Ø-Abschlüsse/Woche).
  - Erweiterte Visualisierungen (Graphen/Charts) bleiben eine mögliche spätere Ausbaustufe.

### 14. Client-Sicht in der App

- [x] Anzeige des Coach-Status:
  - In der `ProfileScreen`-Ansicht integriert:
    - Sektion „Coaching“ mit Anzeige des aktiven Coaches („Dein Coach“ + Name) oder Hinweis, dass kein Coach vorhanden ist.
    - Anzeige der Anzahl ausstehender Coaching-Anfragen.
- [x] Zugriff auf Coaching-Pläne:
  - Client sieht Trainingspläne wie bisher in der Plan-Übersicht.
  - Pläne, die von einem Coach stammen, sind in der Übersicht explizit mit einem „Coach-Plan“-Badge markiert (`coachId` != currentUser).
- [x] Feedback-Möglichkeiten (optional V1):
  - Entscheidung für V1: keine zusätzlichen Feedback-Formulare im Training-Flow; qualitative Feedback-Mechanismen werden gemeinsam mit Kommentaren/Notizen in Phase 7 umgesetzt.
  - Die Roadmap behält Feedback explizit als eigenen Ausbaustein, ist aber für den MVP-/Launch-Scope nicht verpflichtend.

---

## Phase 5: Sicherheit, Datenschutz & Compliance

Ziel: Sicherstellen, dass das Coaching-Feature datenschutzkonform, sicher und nachvollziehbar ist.

### 15. Zugriffskontrolle & Datenschutz

- [x] Serverseitige Zugriffskontrolle:
  - Firestore-Regeln erzwingen:
    - Zugriff auf `coachClientRelations` nur für beteiligten Coach/Client, mit festen ID- und Feld-Invarianten sowie erlaubten Statusübergängen.
    - Zugriff auf `coachInvites` nur für Client, eingeloggten Coach (E-Mail-Match) oder Admin; Kernfelder sind unveränderlich.
    - Zugriff auf `users/{clientId}/training_plans` und zugehörige `meta/stats` nur für Client selbst, aktive Coaches mit `hasActiveCoaching(...)` oder Gym-Admins.
  - Jede Coaching-relevante Operation im Frontend geht über diese Collections/Regeln, sodass kein Coach Zugriff auf Daten von Nicht-Clients erhalten kann.
- [x] Einwilligungslogik:
  - Coach-Zugriff entsteht nur über eine explizite Coach-Client-Beziehung (`coachClientRelations` mit Status `active`), die in der App durch Client-Aktion (Coach auswählen/Einladung annehmen) ausgelöst wird.
  - Beendete Beziehungen (`status = 'ended'` oder `rejected`) entziehen Coaches automatisch den Zugriff auf zukünftige Planänderungen, da `hasActiveCoaching(...)` dann `false` liefert.
- [x] Datennutzung transparent machen:
  - Entscheidung für V1: rechtliche Details (Nutzungsbedingungen/Datenschutzhinweise) werden außerhalb der App gepflegt; technisch ist der Datenzugriff klar auf Coach/Client/Admin-Kreise begrenzt.
  - `coaching_roadmap.md` dokumentiert das Berechtigungsmodell als Grundlage für die rechtliche Ausformulierung.

### 16. Logging & Auditing

- [x] Änderungslog:
  - Neue Collection `coachingEvents` als zentrales Audit-Log:
    - Erfasst Ereignisse wie `relation_requested`, `relation_status_changed`, `external_coach_invite_created`, `external_coach_invite_accepted`, `plan_created_by_coach`, `plan_updated_by_coach`.
    - Alle Einträge enthalten mindestens `gymId`, `type`, `actorId`, optional `coachId`, `clientId`, `relationId`, `planId`, `inviteId`, sowie `createdAt`.
  - Implementierung über `FirestoreCoachingAuditSource`, der „best effort“ aus dem Client schreibt und die wichtigsten Coaching-Aktionen automatisch loggt.
- [x] Zugriffs-Logs (technisch, nicht unbedingt UI):
  - Firestore-Regeln für `coachingEvents`:
    - `create` nur für authentifizierte Nutzer mit `actorId == request.auth.uid`.
    - `read` nur für beteiligte Coaches/Clients oder Admins des jeweiligen Gyms.
    - `update/delete` nicht erlaubt, Audit-Einträge sind unveränderlich.
  - Damit steht eine technische Basis für spätere, erweiterte Auswertungen (z.B. serverseitige Aggregation, Monitoring) zur Verfügung.

---

## Phase 6: Qualitätssicherung, Tests & Rollout

Ziel: Saubere Implementierung mit hoher Qualität, klarer Rollout-Strategie und Möglichkeit zur iterativen Verbesserung.

### 17. Tests & technische Qualität

- [ ] Backend-Tests:
  - Unit-Tests für Coaching-Domäne (Beziehungen, Rechte, Plan-Logik).
  - Integrationstests für zentrale Flows:
    - Coach-Client-Beziehung anlegen → Plan erstellen → Progress speichern.
- [ ] Frontend-Tests:
  - UI-Tests/e2e-Tests für:
    - Coach-Dashboard.
    - Planerstellung/-bearbeitung.
    - Client-Sicht auf Pläne.
- [ ] Performance:
  - Abfragen für Progress-Übersichten optimieren (Pagination, ggf. Aggregation).
  - Bei Bedarf Caching oder voraggregierte Statistiken prüfen.

### 18. Rollout & Monitoring

- [ ] Feature-Flag:
  - Coaching-Funktionalität initial hinter Feature-Flag verstecken.
  - Intern und mit ausgewählten Studios/Coaches testen.
- [ ] Monitoring:
  - Fehler-Tracking (z.B. Sentry) für Coaching-spezifische Endpunkte.
  - Usage-Tracking: Welche Bereiche des Coaching-Features werden genutzt?
- [ ] Feedback-Schleife:
  - Gezieltes Feedback von Coaches und Clients einholen.
  - Anpassungen auf Basis von echtem Nutzungsverhalten priorisieren.

---

## Phase 7: Erweiterungen (nach dem MVP)

Diese Punkte sind bewusst als spätere Ausbaustufen gedacht, damit wir das MVP fokussiert umsetzen können.

### 19. Kommunikation & Collaboration

- [ ] Kommentar-/Notizsystem:
  - Coach kann pro Session oder Plan Notizen hinterlassen.
  - Client kann Feedback geben.
- [ ] In-App-Messaging (optional, später):
  - Direkter Chat zwischen Coach und Client.
  - Integration in bestehendes Messaging, falls vorhanden.

### 20. Templates, Automatisierung & Reports

- [ ] Plan-Templates:
  - Coaches können eigene Vorlagen für verschiedene Ziele (Hypertrophie, Kraft, Anfänger, Fortgeschrittene) speichern.
  - Schnelles Zuweisen/Anpassen für neue Clients.
- [ ] Automatisierte Anpassungsvorschläge:
  - Basierend auf Progress-Daten automatisch Vorschläge für Volumen-/Intensitätsanpassungen.
  - Zunächst nur als „Hinweis“ für Coaches, ohne Auto-Anwendung.
- [ ] Reports:
  - Zusammenfassende Reports pro Client über bestimmte Zeiträume.
  - Studio- oder Coach-spezifische Leistungs-Reports (z.B. Generierung von Fortschrittsberichten).

---

## Versions- und Statuspflege

Bitte beim Arbeiten am Coaching-Feature:

- im jeweiligen Abschnitt die Status-Kästchen (`[ ]`, `[~]`, `[x]`) aktualisieren,
- bei größeren Entscheidungen/Änderungen in einem kurzen Absatz notieren:
  - Datum
  - Entscheidung
  - kurze Begründung

So bleibt `docs/ToDos/coaching_roadmap.md` die zentrale, lebende Dokumentation für das gesamte Coaching-Feature in tapem.
