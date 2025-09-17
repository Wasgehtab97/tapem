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
