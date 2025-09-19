# Tap’em

**NFC-basiertes Gym-Tracking & -Management**

Tap’em ist eine Flutter-App für Fitnessstudios. Sie setzt auf ein modulares Konzept: jedes Feature liegt in einem eigenen Verzeichnis unter `lib/features/<feature>` und ist dort noch einmal in `data`, `domain` und `presentation` aufgeteilt. So lassen sich Funktionen wie Authentifizierung, NFC, Trainingsplan oder Gamification klar trennen und weiterentwickeln.

---

## Features

- **NFC-Integration**: Direktes Navigieren zum passenden Trainings-Dashboard per Tap am Gerät
- **Multi-Tenant-Architektur**: Jedes Studio bekommt seine eigene Konfiguration & Datenbank-Segmente
- **Firebase-Backend**: Authentifizierung, Firestore-Datenhaltung, Cloud Functions (optional)
- **Dynamisches Branding**: Farbschema, Logos und App-Namen pro Studio konfigurierbar
- **State Management**: Provider für skalierbare Business-Logik
- **Visualisierung**: Kalender-Übersicht, Charts (fl_chart), Streak-Badges, Trainingshistorie
- **Muskel-Heatmap**: Muskelgruppen wahlweise als 2D-Silhouette oder 3D-Modell
- **Challenges & Badges**: Wöchentliche und monatliche Aufgaben mit XP-Zielen
- **Offline-Support**: Firestore-Persistence für unterbrechungsfreie Datenerfassung
- **CI/CD ready**: GitHub Actions für Analyse, Tests und Matrix-Builds von Flavors

## Tests lokal & CI

Die Avatars-V2 Rules- und Functions-Tests laufen komplett im Firebase Emulator. Lokal können sie mit folgendem Befehl gestartet werden:

```bash
npm run test:all
```

CI führt denselben Ablauf aus, siehe Workflow `avatars_emulator_tests`.

---

## Projektstruktur

```
lib/
  core/                Basiskomponenten (Themes, Router ...)
  features/
    auth/
    nfc/
    ...                weitere Features, jeweils mit data/, domain/, presentation/
  services/            Hilfsklassen wie API-Clients
```

Weitere Details zum State-Management stehen in [docs/provider_structure.md](docs/provider_structure.md).

Eine Übersicht über die Steuerung des Pausen-Timers findet sich in [docs/device_timer.md](docs/device_timer.md).

---

## Voraussetzungen

- Flutter SDK ≥ 3.7.0
- Android Studio oder VS Code
- Xcode für iOS-Builds
- Ein Firebase-Projekt pro Flavor (dev, prod) mit `google-services.json` und `GoogleService-Info.plist`
- Git ≥ 2.20

---

## Erste Schritte

1. **Repository klonen**
   ```bash
   git clone git@github.com:<DeinUser>/tapem.git
   cd tapem
   ```
2. **Umgebungsdatei anlegen**
   ```bash
   cp .env.example .env.dev
   cp .env.example .env.prod
   # Werte für dein Firebase-Projekt eintragen
   ```
3. **Abhängigkeiten installieren**
   ```bash
   flutter pub get
   ```
4. **Firebase konfigurieren**
   - `google-services.json` in `android/app/`
   - `GoogleService-Info.plist` in `ios/Runner/`
   - Details siehe [docs/environment-setup.md](docs/environment-setup.md)

5. **Firestore-Indexe deployen**
   ```bash
   firebase deploy --only firestore:indexes
   ```
   Ohne die Indexe schlagen bestimmte Abfragen fehl (z. B. "Heute bereits gespeichert?").
   Für die Freundes-Suche ist ein zusammengesetzter Index auf `users(publicProfile ASC, usernameLower ASC)` erforderlich.

---

## Freundes-Suche & Requests (Spark)

Alle Aktionen rund um Freundschaften laufen vollständig clientseitig über Firestore. Anfragen werden unter `users/{toUid}/friendRequests/{fromUid_toUid}` gespeichert, die Freundschaft als symmetrische Kante unter `users/{uid}/friends/{friendUid}`. Die Suche filtert nur öffentliche Profile (`publicProfile == true`) und arbeitet prefix-basiert auf `usernameLower`.

Hinweis: `.gitignore` schützt diese Dateien. Weitere Regeln stehen in [docs/secrets-policy.md](docs/secrets-policy.md).

Die Dateien `pubspec.lock` und – sobald vorhanden – `ios/Podfile.lock` werden versioniert, um reproduzierbare Builds zu gewährleisten.

---

## Flavors

Das Projekt sieht die Flavors **dev** und **prod** vor. Die jeweils zugehörige `.env`-Datei legt Firebase-IDs und weitere Einstellungen fest.

Beispiel für einen Android-Release-Build des Prod-Flavors:

```bash
flutter build apk --flavor prod --release
```

Die CI erstellt beide Flavors automatisch (siehe unten).

---

## Umgebungsvariablen (.env)

```
FIREBASE_PROJECT_ID=<id>
FIREBASE_API_KEY=<api-key>
DEFAULT_GYM_ID=<default-gym>
APP_NAME=<Anzeigename>
```

`.env.dev` und `.env.prod` enthalten Beispielwerte für Entwicklung und Produktion.

---

## CI/CD

Im Ordner `.github/workflows` befindet sich die Pipeline [ci.yml](.github/workflows/ci.yml). Sie führt bei jedem Push aus:

1. **Analyse** (`flutter analyze`)
2. **Tests** (`flutter test` und Security-Rules-Tests)
3. **Build Matrix**: erstellt APKs für die Flavors `dev` und `prod`
4. **Artefakt-Upload** der gebauten APKs

---

## Build & Run lokal

Für schnelle Tests kann man das Dev-Flavor starten:

```bash
flutter run --flavor dev
```

Vor dem Start müssen die passenden `.env`-Dateien vorhanden sein.

---

## Web lokal starten

Die Next.js-Seite lebt im Ordner `website/`.

```bash
cd website
npm install
npm run dev
# http://localhost:3000
```

Die Dev-Config liegt in `website/next.config.js` und ist für lokale Platzhalter-Bilder auf `images.unoptimized = true` gesetzt.

## Geschützte Bereiche (Stub)

Die geschützten Bereiche des Web-Dashboards (`/gym`, `/admin`) laufen aktuell mit einem einfachen Dev-Login. Die Firebase-Authentifizierung folgt in einem späteren Schritt.

- **Verwendung nur in Entwicklung & Vercel-Previews:** In Production antworten die Routen `/api/dev/login` und `/api/dev/logout` mit `403` und dem Hinweis _dev login disabled in production_.
- **Login testen:**
  ```bash
  cd website
  npm run dev
  # http://localhost:3000/login öffnen
  ```
  Rolle auswählen, optional E-Mail angeben und anmelden. Ohne `next`-Parameter leitet der Stub nach `/gym` weiter.
- **Rollen wechseln:** In der Top-Navigation erscheint in Entwicklungs- und Preview-Umgebungen eine Dev-Toolbar. Über die Buttons kannst du zwischen `owner`, `operator` und `admin` wechseln oder dich abmelden.
- **Seitenzugriff:**
  - `/gym` ist für Rollen `owner`, `operator` und `admin` freigeschaltet.
  - `/admin` ist nur für `admin` erreichbar.

Die SSR-Routen liefern aktuell Mock-Daten aus `website/src/server/mocks/gym.ts`. Eine Firebase-Anbindung ersetzt die Stubs später.


## Recht & SEO

- Unter `/imprint` und `/privacy` findest du rechtliche Pflichtseiten mit deutschsprachigen Platzhaltertexten. Bitte vor dem Livegang
  rechtlich prüfen und anpassen.
- Die Footer-Navigation der Landing-Page verlinkt diese Routen dauerhaft sichtbar.
- Das Standard-Metadaten-Setup liefert ein dynamisches OpenGraph-Bild sowie Twitter Cards.

### OG-Bild testen

1. `npm run dev` im Ordner `website/` starten.
2. `http://localhost:3000/opengraph-image` im Browser öffnen – dort wird das generierte 1200×630 Bild angezeigt.
3. Für öffentliche Deployments kannst du den Meta-Debugger von Facebook oder Twitter Card Validator nutzen, um das Live-Bild zu
   prüfen.

### Assets & Screens

- Bilder werden ausschließlich lokal in `website/public/images/` verwaltet (Repo enthält nur eine `.gitkeep`).
- Neue Assets dort ablegen und den Dev-Server kurz neu laden, damit Next.js die Dateien erkennt.
- Bitte weiterhin keine Binärdateien per Git einchecken.

---

## Backlog erzeugen

Pilot-Issues und Labels können automatisiert erstellt werden:

```bash
python3 scripts/create_issues.py --token $GITHUB_TOKEN_PILOT_ISSUES
```

Die zugehörigen Definitionen stehen in `project/roadmap/issues_pilot.json`.

---

## Avatars V2 Flags

Für lokale Tests mit dem Firebase Emulator können die Remote-Config-Flags so gesetzt werden:

```bash
firebase remoteconfig:set avatars_v2_enabled=true avatars_v2_migration_on=false avatars_v2_images_cdn=false
```

Standardmäßig sind alle Flags `false`.

## Changelog

- `OverlayNumericKeypadHost.closeOnOutsideTap` wurde entfernt. Nutze stattdessen
  `outsideTapMode` (z. B. `OutsideTapMode.closeAfterTap`).

---

## Häufige Probleme

- Falls es nach dem Entfernen oder Hinzufügen von Abhängigkeiten zu "Target of URI doesn't exist" Fehlern kommt, hilft meist ein erneutes Ausführen von
  `flutter pub get`. Damit aktualisiert Flutter die verwendeten Pakete.
- Die App nutzt wieder den `file_picker` für Logo-Upload und Plan-Import.
  Führe nach Änderungen an den Abhängigkeiten `flutter pub get` aus.

---

## Lizenz

Siehe [LICENSE](LICENSE).

---

## Web lokal starten

```bash
cd website
npm install
npm run dev
# http://localhost:3000
```

## Assets hinzufügen

Die Landing-Page im Ordner `website/` arbeitet mit Platzhaltern, solange keine echten Screenshots vorhanden sind. Um Bilder lokal
hinzuzufügen (ohne sie zu committen), gehe wie folgt vor:

1. Lege deine Dateien manuell unter `website/public/images/` ab. Das Repository enthält dort nur eine `.gitkeep`, damit keine
   Binärdateien eingecheckt werden.
2. Verwende sprechende Dateinamen und diese Richtwerte für Maße:

   | Datei            | Empfohlene Maße          | Beschreibung                     |
   | ---------------- | ------------------------ | -------------------------------- |
   | `logo.png`       | 512 × 512 oder SVG       | Primäres App-Logo               |
   | `hero.png`       | ca. 1600 × 900           | Mockup für den Hero-Bereich     |
   | `screenshot-1.png` | 1200 × 800             | Trainingshistorie/Analytics     |
   | `screenshot-2.png` | 1200 × 800             | Ranglisten & Challenges         |
   | `screenshot-3.png` | 1200 × 800             | Studio-Konfiguration/Branding   |

3. Nach dem Speichern genügt ein Neustart von `npm run dev`, damit die Galerie automatisch von Platzhaltern auf die echten Bilder
   umschaltet. Das geschieht über eine Dateiprüfung in `src/app/page.tsx`.
4. Committe Binärdateien nur, wenn ausdrücklich erlaubt (z. B. via Git LFS). Standardmäßig bleiben Bilddateien außerhalb des
   Repositories.

