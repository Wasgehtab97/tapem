# Funnel & Activation – Ideen & ToDos

Stand: Entwurf. Ziel: Die App so optimieren, dass sie auch mit sehr wenigen aktiven Nutzern pro Studio (z. B. 10 von 100–200 Mitgliedern) maximalen Mehrwert liefert und sich möglichst leicht weiterempfehlen lässt.

Fokus:

- Einstieg so einfach wie möglich („erstes Training in <60 Sekunden“).
- Virale/organische Verbreitung im Studio (Trainer + Mitglieder).
- Aktivierungs‑Coach & Churn‑Radar, das auch bei wenigen Nutzern funktioniert.

---

## 1. Einstiegs‑Funnel – „Erstes Training in <60 Sekunden“

### 1.1 Ultra-leichter Start

- Registrierung/Anmeldung:
  - Minimal: E‑Mail + Name.
  - Alles weitere (Profil, Ziele, Details) optional später.
- Option „Erst testen, später Account“ (Gastmodus):
  - Nutzer kann sofort eine Session tracken.
  - Beim späteren Registrieren werden Gastdaten mit Account verknüpft.

### 1.2 Kein „leerer Zustand“ – Start mit Vorlagen

- Beim allerersten Start:
  - 2–3 schnelle Fragen:
    - Trainingsziel (z. B. Muskelaufbau, Abnehmen, fitter werden).
    - Level (Einsteiger, Fortgeschritten, Profi).
    - 1–2 Lieblingsgeräte oder Körperbereiche.
  - Daraus wird automatisch eine **„Schnellstart‑Session“** generiert (z. B. 3–5 Übungen).
- UX:
  - Direkt großer CTA „Training starten“ mit der generierten Session.
  - Kein Zwang, zuerst lange Pläne anzulegen.

### 1.3 Minimaler Input beim Tracken

- Quick‑Actions:
  - Buttons wie „wie letztes Mal“, „+5 kg“, „Standardgewicht“, statt vollständiger Eingabe.
- Super-Leichtgewicht-Modus:
  - Ein Button „Heute war ich im Studio“ → zählt als Session mit minimalen Daten.
  - Besser eine grobe Info als gar kein Signal – wichtig für kleine Nutzerbasis.

### 1.4 Onboarding von Papier/anderen Apps

- Feature-Idee: „Übernimm deinen bisherigen Trainingsplan“
  - Nutzer kann ein Foto seines alten Plans (Notizbuch / Screenshot anderer App) machen.
  - UI weist klar darauf hin, dass daraus (erst einmal) nur einfache Geräte/Übungen angelegt werden.
- ToDo:
  - UX-Flow definieren (Schrittfolge, Erklärtexte).
  - Technisch: vorerst manueller Prozess denkbar (oder halbautomatisch via Backend/Tool).

---

## 2. Virale Loops im Studio – von 10 zu 50 App-Nutzern

### 2.1 Trainer‑Modus als Hebel

- Trainer-spezifische Funktionen:
  - Trainer können neue Mitglieder in wenigen Sekunden onboarden:
    - QR‑Code im Trainer‑Profil:
      - Scan → Gym ist vorausgewählt.
      - optional direkte Zuordnung „Trainer X betreut dieses Mitglied“.
  - Trainer sehen eine Liste:
    - „Mitglieder ohne App“,
    - „Mitglieder mit App, aber noch kein Training geloggt“.
- Aktionen für Trainer:
  - 1‑Tap „Einladen“ (QR‑Code, Link, E‑Mail).
  - Vorlagen für persönliche Ansprache im Studio.

### 2.2 In‑Studio‑Prompts & Materialien

- QR‑Poster/Flyer aus der App heraus generieren:
  - App erstellt Poster-PDF mit:
    - Gym‑Branding,
    - kurzer Erklärung,
    - QR‑Code zur App/Gym‑Registration.
  - ToDo:
    - Design in Figma definieren,
    - Export‑Funktion in der App (oder separat).
- Positionierung:
  - Am Tresen, im Eingangsbereich, bei beliebten Geräten, im Kursbereich.

### 2.3 Social Proof im Gym

- Kleine Kennzahlen‑Tiles:
  - „Heute: 7 aktive App‑Nutzer“
  - „Aktive App‑Nutzer in diesem Monat: 23“
- Optional:
  - Anzeige im Ranking‑Tab oder als „Studio-Statistik“ für Betreiber.
  - Idee für später: Export/API für Monitor im Studio.

### 2.4 Member‑Referral („Bring-a-Friend“)

- In der App:
  - Jeder Nutzer bekommt einen Einlade-Link/Code, der:
    - direkt ins richtige Gym führt,
    - optional mit Referral‑Info (wer hat eingeladen?).
- Studioseitig:
  - Optionales Belohnungsmodell:
    - z. B. „Wenn du 3 Freunde aktivierst, bekommst du X“ (intern vom Studio geregelt).
- ToDo:
  - Referral-Token-Modell skizzieren.
  - Einlade-Flow in der UI definieren (Share‑Button + Erfolgsmeldung).

---

## 3. Aktivierungs‑Coach & Churn‑Radar (für kleine Nutzerzahlen)

Ziel: Studioleiter soll auch bei z. B. 10 App-Nutzern sofort wissen, **wer** Aufmerksamkeit braucht und **was** zu tun ist.

### 3.1 Fokus auf individuelle To‑Dos statt große Charts

- Statt weiterer Diagramme:
  - Eine kompakte „To‑Do-Liste“ im Report, z. B.:
    - „Lisa: App installiert, aber noch kein Training → Einstiegsgespräch / Einführung anbieten.“
    - „Tom: seit 14 Tagen keine Session → kurz ansprechen oder Nachricht senden.“
    - „3 neue Mitglieder ohne App-Onboarding → Trainer erinnern.“
- UI‑Idee:
  - Sektion „Aktivierungs‑Coach“ im Report:
    - Max. 5–10 Einträge,
    - jeder Eintrag zeigt:
      - Name / Mitgliedsnummer,
      - Grund (z. B. „Neu, aber inaktiv“, „Frequenz fällt“),
      - empfohlene Aktion (Text).

### 3.2 Einfache Regeln für Onboarding & Churn

- Onboarding-Radar:
  - „Neu & App vorhanden, aber kein Training innerhalb 7 Tagen“ → To‑Do.
  - „Neues Mitglied im Gym, keine App“ → To‑Do „App installieren / QR zeigen“.
- Churn-Radar (für wenige Nutzer):
  - „Aktiv gewesen, aber 14/30 Tage keine Session.“
  - „Frequenz fällt von 2x/Woche auf 0–1x/Woche.“
- Technische ToDos:
  - Definieren, welche Zeitfenster sinnvoll sind (z. B. 7/14/30 Tage).
  - Kleine Helper-Funktionen, die aus Sessions/Trainingsdaten entsprechende Flags generieren.

### 3.3 Aktionen, die Trainer sofort nutzen können

- Action‑Buttons pro To‑Do:
  - „Gesprächs-Vorlage anzeigen“:
    - Kurztext für persönliche Ansprache im Studio oder via WhatsApp.
  - „Als erledigt markieren“:
    - Damit Studioleiter/Trainer den Überblick behalten.
  - Optional später:
    - Verknüpfung mit realer Messaging‑Funktion (Push, Mail).

### 3.4 Kleine, klare Studio-KPIs

- Beispiel‑Kennzahlen für kleine Nutzerbasis:
  - „App‑Nutzer insgesamt: 10“
  - „davon aktiv (letzte 30 Tage): 7“
  - „Hochrisiko-Mitglieder (Churn): 2“
  - „Neue Mitglieder mit App‑Onboarding: 4 von 20“
- UI:
  - Kleine Chips/Karten im Report-Dashboard und im Aktivierungs‑Coach‑Bereich.

---

## 4. Nächste Schritte zur Umsetzung (wenn wir weitermachen)

- **A. UX-Flows konkretisieren**
  - Screen‑Skizzen für:
    - „Erstes Training in <60 Sekunden“,
    - „Trainer‑Onboarding eines Mitglieds“,
    - „Aktivierungs‑Coach“-Sektion mit To‑Dos.

- **B. Datenanforderungen definieren**
  - Welche Events/Daten benötigen wir minimal:
    - App‑Installation bzw. Account‑Erstellung,
    - erste Session,
    - letzte Session,
    - Mitgliedsdauer (bereits vorhanden),
    - optional: Zuordnung zu Trainer.

- **C. MVP‑Umfang festlegen**
  - Was kommt in einen ersten Release:
    - z. B.:
      - Quick‑Schnellstart‑Session,
      - Trainer‑QR‑Onboarding,
      - einfache Aktivierungs‑To‑Do-Liste mit 3–5 Regeln.
  - Was folgt später:
    - Import von bestehenden Plänen,
    - Referral‑Programm,
    - erweiterte Churn‑Analysen.

Diese Datei hält alle Funnel‑ und Aktivierungs‑Ideen fest, sodass wir zu einem späteren Zeitpunkt gezielt UX-Flows bauen und Schritt für Schritt implementieren können.***
