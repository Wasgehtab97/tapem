## Dev/Prod-Trennung – Lokales Setup (Mac)

Ziel: Saubere Trennung von Entwicklung und Produktion, ohne dass du aus Versehen in Prod schreibst oder Configs mischst.

Kurzantwort: Ein einziger Projektordner mit sauberer Branch-Strategie kann reichen, wenn du zusaetzlich klare Config-Trennung und Tools nutzt. Zwei lokale Ordner sind optional und v.a. fuer Parallelbetrieb sinnvoll.

---

## Aktueller Ansatz (ein Repo, zwei Branches)

Dein aktuelles Setup ist grundsaetzlich ok, wenn du folgende Regeln einhaeltst:

- Dev/Prod haben getrennte Firebase-Projekte (nicht nur Branches).
- Lokale Configs sind strikt getrennt (z.B. dev/prod JSON/Plist).
- Deployment-Skripte nutzen explizit das richtige Firebase-Projekt.

Wenn diese drei Punkte fehlen, ist dein Risiko hoch, versehentlich in Prod zu schreiben.

---

## Best Practice Empfehlung (Minimaler Aufwand, hohe Sicherheit)

### 1) Ein Repo, getrennte Firebase-Projekte

- `tapem-dev` (Firebase Projekt)
- `tapem-prod` (Firebase Projekt)

Vorteil: Gleiches Codebase, aber echte Trennung der Daten.

### 2) Lokale Config-Trennung per Build-Flavors

Flutter:
- Android: `flavor dev` / `flavor prod`
- iOS: `Scheme dev` / `Scheme prod`

Dateien:
- `android/app/src/dev/google-services.json`
- `android/app/src/prod/google-services.json`
- `ios/Runner/GoogleService-Info-dev.plist`
- `ios/Runner/GoogleService-Info-prod.plist`

Damit kannst du lokal sicher testen, ohne Prod zu beruehren.

### 3) Env-Variablen fuer Admin-Web / Functions

- `.env.dev`
- `.env.prod`

Beispiel:
- `FIREBASE_PROJECT_ID=tapem-dev`
- `FIREBASE_PROJECT_ID=tapem-prod`

### 4) Deploy nur ueber Scripts

- `make deploy-dev`
- `make deploy-prod`

Keine manuellen Deploys, damit du dich nicht vertust.

---

## Alternative: Zwei lokale Projektordner

Vorteile:
- Du kannst Dev und Prod parallel offen haben.
- Weniger Risiko, falsche Config zu laden.

Nachteile:
- Pflegeaufwand (zweimal pull, zweimal dependencies).
- Gefahr von Drift zwischen Ordnern.

Empfehlung: Nur wenn du wirklich parallel arbeitest oder stark unterschiedliche Branches hast.

---

## Sicherheits-Checkliste (solltest du haben)

- [ ] Firebase Projects strikt getrennt (dev/prod)
- [ ] Unterschiedliche API Keys/Configs
- [ ] Build-Flavors korrekt eingerichtet
- [ ] Deploy nur ueber Scripts
- [ ] Sichtbarer Hinweis im UI (z.B. DEV badge)
- [ ] Firestore Rules verhindern writes ausserhalb erlaubter Umgebung

---

## Ist dein aktuelles Setup ausreichend?

Ja, wenn:
- du Dev/Prod in Firebase getrennt hast
- du lokal klar zwischen dev/prod configs unterscheiden kannst
- deine Deploys immer das richtige Projekt treffen

Nein, wenn:
- du nur Branches nutzt, aber in dasselbe Firebase-Projekt schreibst
- dir die Configs lokal leicht durcheinander geraten koennen

---

## Empfohlene naechste Schritte

1) Firebase-Projekte trennen (falls noch nicht geschehen)
2) Flutter Flavors einrichten
3) Deploy-Skripte erstellen und verpflichtend nutzen
4) Optional: DEV-Badge im UI einfuegen

