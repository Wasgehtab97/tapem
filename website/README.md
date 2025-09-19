# Tap'em Landing-Page (Next.js)

Diese App stellt eine statische Landing-Page für Tap'em bereit. Sie basiert auf Next.js (App Router,
TypeScript) und Tailwind CSS.

## Voraussetzungen

- Node.js ≥ 18.17
- npm ≥ 9

## Entwicklung starten

```bash
npm install
npm run dev
# http://localhost:3000
```

Für Produktions-Builds:

```bash
npm run build
npm start
```

## Assets hinzufügen

Der Ordner `public/images/` enthält nur eine `.gitkeep`, damit keine Binärdateien im Repository landen.
Lege deine Mockups lokal dort ab, wenn du reale Screenshots verwenden möchtest.

| Datei              | Empfohlene Maße | Verwendung                         |
| ------------------ | --------------- | ---------------------------------- |
| `logo.png`         | 512 × 512       | App- oder Studio-Logo              |
| `hero.png`         | 1600 × 900      | Hero-Mockup auf der Startseite     |
| `screenshot-1.png` | 1200 × 800      | Trainingshistorie / Analytics      |
| `screenshot-2.png` | 1200 × 800      | Ranglisten & Challenges            |
| `screenshot-3.png` | 1200 × 800      | Studio-Konfiguration & Branding    |

Die Galerie in `src/app/page.tsx` prüft beim Rendern, ob eine entsprechende Datei existiert.
Ist dies der Fall, wird automatisch `<Image src="/images/<datei>" />` geladen. Ohne Datei bleibt der
Platzhalter sichtbar.

## Linting & Formatierung

```bash
npm run lint
```

Prettier-Einstellungen findest du in `.prettierrc`.

## Umgebungsvariablen

Trage die öffentliche Basis-URL in `.env.local` ein (siehe `.env.example`). Sie wird für OpenGraph,
Sitemap und `robots.txt` verwendet.

## Navigation & Rollen

| Route        | Beschreibung                                   | Zugelassene Rollen |
| ------------ | ----------------------------------------------- | ------------------ |
| `/`          | Marketing-Landingpage                           | öffentlich         |
| `/login`     | Dev-Login (Stub)                                | öffentlich         |
| `/gym`       | Betreiber-Dashboard mit KPIs & Unterseiten       | owner, operator, admin |
| `/admin`     | Monitoring für globale Admins                    | admin              |
| `/gym/*`     | Mitglieder, Challenges, Leaderboard              | owner, operator, admin |

## Dev-Login & Toolbar

- Die API-Routen `/api/dev/login` und `/api/dev/logout` setzen bzw. löschen Cookies `tapem_role` und `tapem_email`.
- In Development & Preview blendet die Top-Navigation eine Dev-Toolbar ein. Damit können Rollen ohne Seitenwechsel gewechselt werden.
- In Production verweigern die API-Routen den Aufruf mit `403` (_dev login disabled in production_).

## Mock-Datenquelle

- Alle geschützten Routen verwenden statische Mock-Daten aus [`src/server/mocks/gym.ts`](src/server/mocks/gym.ts).
- Tabellen und Karten sind SSR gerendert, um das spätere Datenmodell zu skizzieren.

## Ausblick Firebase-Anbindung

- Firebase Auth ersetzt den Dev-Login; Rollen werden dann aus Custom Claims gelesen.
- Firestore Collections (`gyms`, `members`, `challenges`, `events`) liefern Echtzeitdaten in die SSR-Pages.
- Analytics/BigQuery füttert langfristig das Admin-Monitoring mit aggregierten Kennzahlen.

## Vercel Deploy

### A) Web-UI (empfohlen)

1. In Vercel auf **New Project** klicken und das GitHub-Repository auswählen.
2. Als *Root Directory* `website/` setzen (Monorepo-Aufbau beachten).
3. Vercel erkennt Next.js automatisch – die Standard-Build-Einstellungen können übernommen werden.
4. Deploy starten. Nach wenigen Minuten steht eine Preview-URL unter `*.vercel.app` bereit.
5. Sobald alles geprüft ist, kann über **Deploy to Production** ein Live-Release ausgelöst werden.

### B) CLI (Alternative)

```bash
cd website
npm i -g vercel
vercel login
vercel link       # Projekt anlegen/zuordnen, Root = website/
vercel            # Preview Deploy
vercel --prod     # Production Deploy (wenn bereit)
```

### Hinweise

- Keine Secrets committen. Sensible Variablen ausschließlich über das Vercel-Dashboard oder die CLI (`vercel env`) pflegen –
  getrennt für Preview- und Production-Umgebungen.
- Bei Monorepos immer `website/` als Projekt-Root auswählen, damit Next.js korrekt gebaut wird.
- Jede Pull-Request-Preview verlinken: Ideal für schnelle Reviews, Thesis-Screenshots und manuelle Checks der Pflichtseiten
  sowie des dynamischen OG-Bilds.
