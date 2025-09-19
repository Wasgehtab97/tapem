# typedroutes_login_nav_fix

## Prompt

Ziel: Im Repo Wasgehtab97/tapem, Branch a_gpt5, die Next.js-Webapp unter website/ so fixen, dass vercel --prod ohne TypeScript-Fehler baut.
Fehlerbilder:

layout.tsx: typedRoutes verlangt Route für href, bisher werden Strings gereicht.

login-form.tsx: router.push(nextPath || '/gym') → nextPath ist generischer String; bei typedRoutes muss es ein Route sein.

login/page.tsx: <LoginForm nextPath={...} /> → LoginForm hat keinen solchen Prop.
Nebenbedingung: Keine Flutter-Files ändern; keine Binärdateien; konventionelle Commits; Thesis-.md anlegen.

Anforderungen (bitte exakt umsetzen)

Navigation typisieren (typedRoutes-safe)

Datei: website/src/app/layout.tsx

Import ergänzen: import type { Route } from 'next';

Navigationsliste strikt typisieren:

const navLinks: Array<{ href: Route; label: string }> = [
  { href: '/', label: 'Home' },
  { href: '/gym', label: 'Gym' },
  { href: '/admin', label: 'Admin' },
];


Link-Rendering unverändert lassen (jetzt fehlerfrei, weil href vom Typ Route ist).

Bonus (beibehalten): robots abhängig von process.env.VERCEL_ENV (Preview = noindex, Prod = index). Falls das schon implementiert ist, nicht anfassen.

Login-Redirect typed & sicher (Whitelist)

Datei: website/src/app/login/login-form.tsx

Ohne Props arbeiten (kein nextPath Prop). Die Komponente liest next selbst via useSearchParams.

Oben ergänzen:

import type { Route } from 'next';

const ALLOWED_AFTER_LOGIN = [
  '/gym',
  '/gym/members',
  '/gym/challenges',
  '/gym/leaderboard',
  '/admin',
] as const;
type AllowedRoute = (typeof ALLOWED_AFTER_LOGIN)[number];
const DEFAULT_AFTER_LOGIN: AllowedRoute = '/gym';

function isAllowedRoute(v: string | null): v is AllowedRoute {
  return !!v && (ALLOWED_AFTER_LOGIN as readonly string[]).includes(v);
}


Beim Redirect:

const nextParam = searchParams.get('next');
const target: Route = (isAllowedRoute(nextParam) ? nextParam : DEFAULT_AFTER_LOGIN) as Route;
router.push(target);
router.refresh();


Keine Prop-Definition für LoginForm hinzufügen (reinlesen via useSearchParams).

Login-Page Prop entfernen

Datei: website/src/app/login/page.tsx

Kein nextPath mehr berechnen/weiterreichen.

<LoginForm /> ohne Props rendern.

Beispiel (wenn eine schlanke Page gebraucht wird):

import type { Metadata } from 'next';
import LoginForm from './login-form';

export const metadata: Metadata = {
  title: 'Login – Tap’em (Dev-Stub)',
  robots: { index: false, follow: false },
};

export default function Page() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">Anmelden (Dev-Stub)</h1>
      <p className="text-sm text-slate-600">
        Diese Anmeldung setzt nur Vorschau-Cookies und dient dem Testen der geschützten Bereiche.
        In Production ist der Dev-Login deaktiviert.
      </p>
      <LoginForm />
    </div>
  );
}


(Nur falls vorhanden) OG-Bild CSS konsistent halten

Datei: website/src/app/opengraph-image.tsx

Stelle sicher, dass kein display: inline-flex verwendet wird. Nur erlaubte Werte wie display: 'flex'.

Falls bereits korrigiert: nicht ändern.

tsconfig / next.config

website/next.config.js: experimental.typedRoutes bleibt aktiv (nicht entfernen).

website/tsconfig.json: nichts ändern, außer es ist nötig, um die obigen Typen zu erkennen (meist nicht notwendig).

Docs & Thesis

README.md (Root oder website/README.md) – kurzer Abschnitt „typedRoutes Fix“:

Warum Route nötig ist,

Whitelist-Konzept nach Login,

QA-Schritte (siehe unten).

Thesis-Markdown anlegen:
Datei: thesis/gamification/YYYY-MM-DD_typedroutes_login_nav_fix.md
Inhalt: Prompt (dieser Text), Ziel, Kontext (Repo/Branch), Ergebnis (Dateiliste), Screens/Links (optional), Abweichungen/Nacharbeiten.

Git & PR

Konventionelle Commits (Beispiel unten).

PR-Titel: fix(website): typedRoutes-safe nav and login redirect (no binaries)

PR-Checkliste:

Build lokal und auf Vercel grün,

layout.tsx nutzt Route-typisierte Nav,

login-form.tsx nutzt Whitelist + Route Redirect,

login/page.tsx ohne nextPath Prop,

Keine Flutter-Änderungen, keine Binärdateien, Thesis-.md vorhanden.

Erwartete Commits (Beispiele)

fix(website): type-safe nav links for Next.js typedRoutes

fix(website): typedRoutes-safe login redirect with allowed route whitelist

fix(website): remove invalid LoginForm prop usage

docs(website): explain typedRoutes and login whitelist

docs(thesis): add typedroutes_login_nav_fix log

Tests / Abnahme

npm run build lokal ohne Fehler.

vercel --prod erfolgreich (Production URL liefert Seite).

Manuell prüfen:

Navbar-Links funktionieren.

/login → Login als owner → Redirect /gym.

/login?next=/admin → als admin → Redirect /admin.

/login?next=/oops → Redirect /gym (Whitelist greift).

(Falls OG-Route existiert) /opengraph-image rendert ohne CSS-Fehler.

Wichtig (Masterarbeit/Gamification): Erstelle im PR zwingend die Datei thesis/gamification/YYYY-MM-DD_typedroutes_login_nav_fix.md mit Prompt, Ziel, Kontext, Ergebnis. Keine Binärdateien in den PR aufnehmen.

## Ziel

- typedRoutes-Fehler in Navigation und Login beseitigen.
- Redirect nach Dev-Login über Whitelist absichern.
- Dokumentation & Thesis-Eintrag ergänzen.

## Kontext

- Repository: Wasgehtab97/tapem
- Branch: a_gpt5

## Ergebnis

- website/src/app/login/page.tsx
- website/src/app/login/login-form.tsx
- README.md
- thesis/gamification/2025-09-19_typedroutes_login_nav_fix.md

## Screens/Links

- n/a

## Abweichungen/Nacharbeiten

- Keine.
