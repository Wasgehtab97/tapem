## Training planen – Roadmap

Diese Roadmap beschreibt die Implementierung eines konsistenten, sauberen und effektiven Trainingsplanungs-Features in der bestehenden tapem-App – für normale Mitglieder und für Coaches im Coaching-Kontext.

Ziele:

- Mitglieder können ihre Trainingstage selbst planen, indem sie Pläne konkreten Tagen zuweisen.
- Coaches können für ihre Clients Trainingstage planen, inklusive direkter Plan-Zuweisung.
- Der neue Flow „Training starten“ integriert Plan-Zuweisung und Freestyle-Training in einen sauberen, intuitiven Einstieg.

Status-Legende (bitte pflegen):

- [ ] nicht gestartet
- [~] in Arbeit
- [x] abgeschlossen

---

## Phase 1: Grundlagen & UX-Konzept

Ziel: Klar definieren, wie das Zusammenspiel von Kalender, Plänen und dem neuen „Training starten“-Flow aussehen soll – sowohl für Members ohne Coach als auch für Clients/Coaches im Coaching-Modul.

### 1. Use-Cases & Flows definieren

- [x] Member ohne Coach:
  - Kann auf der Profilseite über den Trainingstagekalender einzelne Tage auswählen.
  - Bei Klick auf einen Tag erscheint eine Wahl:
    - „Trainingdetailspage“ – öffnet wie bisher die Trainingdetails/Session-Historie für diesen Tag.
    - „Plan“ – öffnet eine Auswahl aller aktiven eigenen Trainingspläne, um einen Plan diesem Tag zuzuweisen.
- [x] Client mit Coach:
  - Hat dieselben Möglichkeiten wie ein normaler Member (eigene Planung).
  - Zusätzlich kann der Coach über den Coaching-Bereich Trainingstage planen (siehe Phase 2).
- [x] Training starten (Member & Client):
  - Neuer Button „Training starten“ auf der Profilseite.
  - Standardverhalten ohne zugewiesenen Plan:
    - Button startet den globalen Trainingstags-Timer.
    - Nutzer landet automatisch auf der Gym-Page (freies Training / Gerätesuche).
  - Verhalten mit zugewiesenem Plan für den aktuellen Tag:
    - Bei Klick auf „Training starten“ erscheint eine Auswahl:
      - „Plan (Planname)“ – startet direkt den zugewiesenen Plan in der WorkoutDayScreenPage; alle Übungen des Plans sind sofort offen, als hätte der Nutzer den Plan manuell gestartet.
      - „Freestyle“ – wie oben: Gym-Page öffnen und Timer starten, ohne Planbindung.

### 2. UX-Details & Interaktionsdesign

- [x] Tag-Auswahl-Dialog:
  - Einheitlicher UI-Baustein als **Bottom-Sheet**, der sowohl für Member als auch für Coaches verwendet wird:
    - Komponente: `TrainingDayActionSheet` (oder ähnlich) im Profil-/Coaching-Feature-Namespace.
    - API:
      - Pflicht: `date` (lokales Datum des Trainingstags),
      - optional: `assignedPlanName` (falls für den Tag bereits ein Plan zugewiesen ist),
      - Callbacks: `onOpenDetails()`, `onOpenPlanSelection()`.
    - Inhalt:
      - Primäre Optionen:
        - „Trainingdetailspage“ (führt `onOpenDetails` aus),
        - „Plan“ (führt `onOpenPlanSelection` aus).
      - Optionaler Subtext: bei vorhandener Zuweisung Anzeige „Aktueller Plan: <Name>“.
- [x] Plan-Auswahl-Dialog:
  - Klar strukturierte Liste der aktiven Pläne in einem eigenen Bottom-Sheet:
    - Komponente: z.B. `PlanSelectionSheet`, wiederverwendbar für Member & Coaches.
    - API:
      - Input: Liste von `TrainingPlan` oder Future/Provider-Handle,
      - Callbacks: `onSelect(TrainingPlan plan)`, `onCancel()`.
    - Darstellung je Plan:
      - Name (Pflicht),
      - optional:
        - Badge „Coach-Plan“, falls `plan.coachId != null && plan.coachId != ownerUserId`,
        - Meta-Info (z.B. „3 Übungen“).
  - Es werden nur Pläne angezeigt, die im aktuellen Modell als „aktiv“ gelten (impliziter Status über Nutzung/Ort, kein zusätzliches Statusfeld nötig).
- [x] „Training starten“-Interaktion:
  - UX-Konzept:
    - Visuell hochwertiger Button „Training starten“ auf der Profilseite (Stil analog zu „Entdecken“/„Coaching“-Button).
    - Verhalten ohne Plan-Zuweisung:
      - Tap startet explizit den globalen Trainingstags-Timer.
      - Anschließend Navigation zur Gym-Page (freies Training).
    - Verhalten mit Plan-Zuweisung für den aktuellen Tag:
      - Bottom-Sheet mit zwei Optionen:
        - „Plan (<Planname>)“ – Plan-basiertes Training:
          - Setzt den aktiven Plan-Kontext (WorkoutDayController),
          - öffnet die WorkoutDayScreenPage mit allen Plan-Übungen.
        - „Freestyle“ – identisch zum Standardverhalten ohne Plan (Timer + Gym).
  - Timer-Interaktion:
    - Wenn der Tag über „Training starten“ begonnen wurde, läuft der Timer bereits; das Abhaken des ersten Satzes darf ihn nicht erneut starten oder beeinflussen.
    - Tritt der Nutzer ohne „Training starten“ in ein Training ein, bleibt das Auto-Start-Verhalten bestehen: der Timer startet beim ersten abgehakten Satz.

---

## Phase 2: Member-Trainingstage planen (ohne Coach)

Ziel: Mitglieder können ihre eigenen Trainingstage planen, indem sie Pläne Tagen zuweisen; der Kalender ist das zentrale UI für die Planung.

### 3. Datenmodell & Persistenz

- [x] Struktur für Plan-Zuweisungen:
  - Entscheidung, wie Plan-Zuweisungen gespeichert werden:
    - Umsetzung V1: pro User und Tag ein „PlanAssignment“-Dokument unter `users/{uid}/training_schedule/{dateKey}` mit Feldern:
      - `dateKey` (z.B. `yyyy-MM-dd` lokal)
      - `planId`
      - `createdAt`, `updatedAt`
  - Es existiert ein Domainmodell `TrainingDayAssignment` sowie `TrainingScheduleRepository` mit Firestore-Implementierung.
- [x] Firestore-Regeln:
  - Owner-orientiertes Modell:
    - `users/{uid}/training_schedule/{dateKey}`:
      - `read`, `get`, `list` für:
        - `uid` selbst,
        - globale Admins,
        - Gym-Admins des `activeGymId`, sofern der User dort Mitglied ist,
        - Coaches mit aktiver Relation (`hasActiveCoaching(activeGymId(), uid)`).
      - `create`/`update` für:
        - Owner (`uid`),
        - aktive Coaches mit entsprechender Relation.
      - `delete` für:
        - Owner,
        - Gym-Admins im `activeGymId` (sofern Mitgliedschaft besteht).
  - Keys begrenzen und validieren:
    - `keys().hasOnly(['planId','createdAt','updatedAt'])`.
    - `planId` ist `string` und referenziert einen existierenden Plan des Users.

### 4. Profilseite – Kalender-Interaktion für Members

- [x] Tag-Click-Handler erweitern:
  - Aktuell: Klick auf einen Tag öffnet direkt die Trainingdetails für diesen Tag.
  - Neu: Klick öffnet einen Dialog/Sheet mit:
    - Aktion „Trainingdetailspage“:
      - Öffnet die aktuelle Trainingdetails-Page für den Tag (bestehender Flow).
    - Aktion „Plan“:
      - Lädt alle aktiven Pläne des Nutzers (`TrainingPlanRepository.getPlans(...)`).
      - Zeigt Plan-Auswahl via `PlanSelectionSheet` (vgl. Phase 1.2).
      - Nach Auswahl wird eine `training_schedule`-Zuweisung für diesen Tag gespeichert (`TrainingScheduleRepository.setAssignment(...)`).
- [x] UI-Markierungen im Kalender:
  - Tage mit zugewiesenem Plan werden im Profil-Kalender optisch hervorgehoben:
    - `Calendar`-Widget akzeptiert zusätzlich `scheduledDates` (`List<String>` mit `yyyy-MM-dd`).
    - Tage mit Plan-Zuweisung erhalten einen farbigen Rahmen in Brand-Farbe (sofern nicht „Heute“ markiert ist).
  - Die Markierung ist rein visuell; Detailinformationen zum Plan werden im Tag-Action-Sheet angezeigt („Aktueller Plan: <Name>“).

---

## Phase 3: Coaching – Trainingstage für Clients planen

Ziel: Coaches können für ihre aktiven Clients Trainingstage planen und Plans zuweisen – parallel zur eigenen Planung der Clients.

### 5. Einstieg: „Trainingstage planen“ im Coaching-Client-Detail

- [x] Button hinzufügen:
  - Im `CoachingClientDetailScreen`:
    - Neuer Button „Trainingstage planen“ (gestalterisch passend zu „Plan für Client erstellen“).
    - Nur sichtbar bei `relation.isActive`.
- [x] Navigation zum Client-Kalender:
  - Klick auf „Trainingstage planen“ öffnet den Trainingstagekalender **für den Client**:
    - Nutzung desselben Kalender-Widgets wie auf der Profilseite, aber mit:
      - `userId = clientId` (statt `auth.userId`).
      - Lesen/Schreiben der `training_schedule`-Zuweisungen des Clients.
    - Zugriff nur erlaubt, wenn:
      - Aktive Coaching-Beziehung (`hasActiveCoaching(gymId, clientId)`).

### 6. Tag-Interaktionen im Coaching-Kalender

- [x] Tag-Klick-Dialog für Coaches:
  - Bei Klick auf einen Tag im Client-Kalender:
    - Option „Trainingdetailspage“:
      - Öffnet die Trainingdetails dieses Tages für den Client (History/Session-Ansicht).
      - History- und Detail-Screens müssen Daten für `clientId` laden, nicht für den Coach (Owner-Kontext wie in Phase 3 umgesetzt).
    - Option „Plan“:
      - Lädt alle aktiven Pläne des Clients (Client-Pläne, nicht Coach-eigene).
      - Zeigt Plan-Auswahl wie bei Members.
      - Speichert `training_schedule`-Zuweisung für `clientId` und gewählten `dateKey`.
- [x] Berechtigungen & Regeln:
  - Firestore-Regeln für `users/{clientId}/training_schedule`:
    - `read`/`write` erlaubt für:
      - Owner `clientId`.
      - Coach mit aktiver `coachClientRelation` im entsprechenden Gym.
      - Admins des Gyms.
  - Prüfen, dass bestehende History-/Details-APIs mit `ownerUserId` umgehen können (analog zu Plan-Stats & History).

---

## Phase 4: „Training starten“ – Entry Point für Training

Ziel: Ein einheitlicher, klarer Flow, wie Mitglieder und Clients ein Training starten – mit oder ohne zugewiesenen Plan.

### 7. Button „Training starten“ auf der Profilseite

- [x] UI-Integration:
  - Neuer Button „Training starten“ auf der Profilseite, z.B. im unteren Bereich nahe „Coaching“/„Entdecken“.
  - Stilistisch an bestehende Buttons angepasst (Branding, Gradient, Icon).
- [x] Standardverhalten ohne Plan-Zuweisung:
  - Bei Klick:
    - Starte den globalen Trainingstag-Timer (expliziter Start).
    - Navigiere zur Gym-Page (Geräte/Workout-Entry-Point).

### 8. Verhalten bei zugewiesenem Plan (aktueller Tag)

- [x] Ermitteln des geplanten Plans:
  - Beim Klick auf „Training starten“:
    - Lade `training_schedule` für den aktuellen `dateKey` (lokales Datum) des Users (Member oder Client).
    - Prüfe, ob ein `planId` hinterlegt ist und der Plan noch aktiv ist.
- [x] Auswahl-Dialog:
  - Wenn **kein** Plan zugewiesen:
    - Direktes Freestyle-Verhalten wie oben (Timer + Gym).
  - Wenn **ein Plan** zugewiesen:
    - Zeige Dialog mit zwei Optionen:
      - „Plan (Planname)“:
        - Startet direkt die WorkoutDayScreenPage für den Plan:
          - Setzt den aktiven Plan-Kontext (wie beim manuellen Start).
          - Öffnet die Übungen des Plans (Plan-basiertes Training).
      - „Freestyle“:
        - Starte Timer und navigiere zur Gym-Page, ohne den Plan-Kontext zu setzen.
  - Wenn **mehrere Pläne** für den Tag unterstützt werden (optionale spätere Erweiterung):
    - Zeige zusätzlich eine Liste der geplanten Pläne; V1 kann bei einem Plan bleiben.

### 9. Synchronisation mit laufenden Trainings

- [x] Aktiver Plan-Kontext:
  - Sicherstellen, dass beim Start über „Plan (Planname)“:
    - Die gleiche Logik verwendet wird wie beim manuellen Plan-Start (WorkoutDayController etc.).
    - Der Timer korrekt läuft und Sessions mit dem Plan verknüpft werden.
- [x] Wiederholtes Klicken auf „Training starten“:
  - Wenn bereits ein Plan aktiv ist:
    - Button könnte Training beenden oder zum aktiven Plan springen (UX-Entscheidung):
      - V1: Beim laufenden Training → Hinweis „Training läuft bereits / zum aktiven Plan wechseln“.
  - Zusammenspiel mit dem bisherigen Auto-Start des Timers:
    - Bestehendes Verhalten: Wenn kein Trainingstag aktiv ist, wird der Timer beim Abhaken des ersten Satzes der ersten Übung automatisch gestartet.
    - Neu:
      - Wenn der Trainingstag bereits über „Training starten“ begonnen wurde (Timer läuft), darf das Abhaken des ersten Satzes den Timer nicht noch einmal beeinflussen – er läuft einfach weiter.
      - Wenn der Nutzer NICHT über „Training starten“ eingestiegen ist, bleibt das bisherige Auto-Start-Verhalten erhalten: der Timer beginnt beim ersten abgehakten Satz.

---

## Phase 5: Technische Details, Refactoring & Berechtigungen

Ziel: Saubere technische Basis, die bestehende Trainingslogik nicht bricht und Coaching-/Member-Flows sauber trennt.

### 10. APIs & Provider

- [x] Scheduling-Repository:
  - Neues Repository/Source-Paar für `training_schedule`:
    - `TrainingScheduleRepository` mit Operationen:
      - `getAssignment(dateKey, userId)`
      - `setAssignment(dateKey, userId, planId)`
      - `clearAssignment(dateKey, userId)`
  - Riverpod-Provider:
    - `trainingScheduleForDayProvider(dateKey)` – lädt Assignment für den aktuellen User (Member).
    - `clientTrainingScheduleForDayProvider(clientId, dateKey)` – für Coaches im Client-Kalender.
- [x] Wiederverwendung von Komponenten:
  - Tag-Dialog (Trainingdetails vs. Plan) als eigener Widget/Helper.
  - Plan-Auswahl-Dialog als wiederverwendbare Komponente (für Member + Coach).

### 11. Firestore-Regeln erweitern

- [x] `training_schedule`-Subcollection:
  - Regeln analog zu `training_plans`:
    - `read`/`write` für:
      - Owner (`uid`).
      - Coaches mit `hasActiveCoaching(gymId, uid)`.
      - Gym-Admins (wenn nötig).
  - Schlüssel-Validierung:
    - `dateKey` Format, zulässige Felder und Typen.

---

## Phase 6: Tests, QA und Rollout

Ziel: Sicherstellen, dass der neue Planungs-Flow stabil, intuitiv und kompatibel mit dem bestehenden Training-/Coaching-System ist.

### 12. Manuelle Testszenarien

- [ ] Member ohne Coach:
  - Plan erstellen → Tag im Kalender wählen → Plan zuweisen → „Training starten“ → „Plan (Name)“ starten → Session/Stats werden korrekt geschrieben.
- [ ] Client mit Coach:
  - Coach erstellt Plan für Client → Tag im Client-Kalender planen → Plan zuweisen.
  - Client startet Training über „Training starten“:
    - Auswahl zwischen „Plan (Name)“ und „Freestyle“.
    - Stats und History sichtbar für Client und Coach.
- [ ] Mischszenarien:
  - Planänderungen (Umbenennen, Übungen ändern) vor/ nach Zuweisung.
  - Beenden von Coaching-Beziehungen und Verhalten der Scheduling-Daten.

### 13. Technische Tests & Refactorings

- [ ] Unit-Tests:
  - TrainingScheduleRepository (Lesen/Schreiben von Assignments).
  - Provider-Logik für Plan-Ermittlung beim „Training starten“-Flow.
- [ ] Integrationstests:
  - End-to-End-Flow: Plan erstellen → Tag zuweisen → Training starten → Stats/History prüfen.

---

## Pflege & Erweiterungen

- Die Datei `docs/ToDos/training_planen.md` dient als lebende Dokumentation für alle Themen rund um Trainingsplanung.
- Bitte beim Arbeiten:
  - Status-Kästchen (`[ ]`, `[~]`, `[x]`) pflegen.
  - Größere Entscheidungen kurz notieren (Datum, Entscheidung, kurze Begründung).
