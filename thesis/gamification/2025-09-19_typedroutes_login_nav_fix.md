# typedroutes_login_nav_fix

## Prompt
```
Ziel:
Im Repo Wasgehtab97/tapem, Branch a_gpt5, den Web-Teil unter website/ so anpassen, dass npm run build lokal und vercel --prod in Vercel ohne TypeScript-Fehler durchlaufen.
Besonders: Next.js experimental.typedRoutes fehlerfrei machen (keine string-hrefs), Login-Redirect typisiert & sicher, OG-Bild kompatibles CSS, keine Binärdateien. Flutter-Ordner nicht ändern.

Rahmenbedingungen (bitte strikt einhalten)

Nur unter website/ arbeiten (außer README/Thesis).

Keine Änderungen in Flutter-Dateien (lib/, android/, ios/, functions/ etc.).

Keine Binärdateien (keine PNG/JPG/WebP/ICO).

Konventionelle Commits verwenden.

Thesis-Doku je PR in thesis/gamification/ anlegen (siehe unten).

Aufgaben – Schritt für Schritt
1) Zentrale, getypte Routen definieren (einmalig)

Datei: website/src/lib/routes.ts (neu)

import type { Route } from 'next';

export const ROUTES = {
  home: '/' as Route,
  gym: '/gym' as Route,
  gymMembers: '/gym/members' as Route,
  gymChallenges: '/gym/challenges' as Route,
  gymLeaderboard: '/gym/leaderboard' as Route,
  admin: '/admin' as Route,
  imprint: '/imprint' as Route,
  privacy: '/privacy' as Route,
} as const;

export type AppRoute = (typeof ROUTES)[keyof typeof ROUTES];

// Whitelist für Redirects nach Login:
export const ALLOWED_AFTER_LOGIN = [
  ROUTES.gym,
  ROUTES.gymMembers,
  ROUTES.gymChallenges,
  ROUTES.gymLeaderboard,
  ROUTES.admin,
] as const;

2) layout.tsx – Nav typedRoutes-sicher + Preview noindex (falls noch nicht)

Datei: website/src/app/layout.tsx

Route importieren: import type { Route } from 'next';

Nav liste typisieren oder ROUTES verwenden:

import { ROUTES } from '@/src/lib/routes';

const navLinks: Array<{ href: Route; label: string }> = [
  { href: ROUTES.home, label: 'Home' },
  { href: ROUTES.gym, label: 'Gym' },
  { href: ROUTES.admin, label: 'Admin' },
];


<Link href={link.href}> unverändert lassen (jetzt typ-sicher).

metadata.robots: In Preview/Dev noindex, in Prod index (falls noch nicht vorhanden: umsetzen).

3) Gym-Subnav typedRoutes-sicher

Datei: website/src/components/gym-subnav.tsx (ersetzen)

'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import type { Route } from 'next';
import { ROUTES } from '@/src/lib/routes';

const items = [
  { href: ROUTES.gym, label: 'Übersicht' },
  { href: ROUTES.gymMembers, label: 'Mitglieder' },
  { href: ROUTES.gymChallenges, label: 'Challenges' },
  { href: ROUTES.gymLeaderboard, label: 'Rangliste' },
] satisfies ReadonlyArray<{ href: Route; label: string }>;

export default function GymSubnav() {
  const pathname = usePathname();

  return (
    <nav aria-label="Gym-Untermenü" className="flex flex-wrap gap-2">
      {items.map((item) => {
        const isActive = pathname === item.href;
        return (
          <Link
            key={item.href}
            href={item.href}
            className={
              'rounded-full border px-4 py-2 transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900 ' +
              (isActive
                ? 'border-slate-900 bg-slate-900 text-white'
                : 'border-slate-300 text-slate-700 hover:bg-slate-100')
            }
            aria-current={isActive ? 'page' : undefined}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}

4) Login-Form: typed Redirect + Open-Redirect-Schutz

Datei: website/src/app/login/login-form.tsx (ersetzen)

'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import type { Route } from 'next';
import { useState } from 'react';
import { ALLOWED_AFTER_LOGIN } from '@/src/lib/routes';

type AllowedRoute = (typeof ALLOWED_AFTER_LOGIN)[number];
const DEFAULT_AFTER_LOGIN: AllowedRoute = ALLOWED_AFTER_LOGIN[0];

function isAllowedRoute(v: string | null): v is AllowedRoute {
  return !!v && (ALLOWED_AFTER_LOGIN as readonly string[]).includes(v);
}

export default function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(formData: FormData) {
    setError(null);
    setSubmitting(true);

    try {
      const email = (formData.get('email') as string | null) ?? '';
      const role = (formData.get('role') as string | null) ?? 'owner';

      const res = await fetch('/api/dev/login', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ email, role }),
      });
      if (!res.ok) throw new Error(`Login fehlgeschlagen (${res.status})`);

      const nextParam = searchParams.get('next');
      const target: Route = (isAllowedRoute(nextParam) ? nextParam : DEFAULT_AFTER_LOGIN) as Route;

      router.push(target);
      router.refresh();
    } catch (e: any) {
      setError(e?.message ?? 'Unbekannter Fehler beim Login.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form action={onSubmit} className="max-w-md space-y-4">
      <div className="rounded-md border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900">
        <strong>Dev-Login (Stub):</strong> Nur für Preview/Entwicklung. In Production deaktiviert.
      </div>

      <div className="space-y-1">
        <label htmlFor="email" className="block text-sm font-medium text-slate-700">E-Mail (optional)</label>
        <input id="email" name="email" type="email" placeholder="you@example.com"
          className="w-full rounded border border-slate-300 px-3 py-2 text-sm outline-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900" />
      </div>

      <div className="space-y-1">
        <label htmlFor="role" className="block text-sm font-medium text-slate-700">Rolle</label>
        <select id="role" name="role" defaultValue="owner"
          className="w-full rounded border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900">
          <option value="owner">owner</option>
          <option value="operator">operator</option>
          <option value="admin">admin</option>
        </select>
      </div>

      {error ? <p className="text-sm text-red-600">{error}</p> : null}

      <button type="submit" disabled={submitting}
        className="inline-flex items-center justify-center rounded bg-slate-900 px-4 py-2 text-sm font-medium text-white transition hover:bg-slate-800 disabled:opacity-50">
        {submitting ? 'Anmelden…' : 'Anmelden'}
      </button>
    </form>
  );
}

5) Login-Page: Prop entfernen

Datei: website/src/app/login/page.tsx (ersetzen)

import type { Metadata } from 'next';
import LoginForm from './login-form';

export const metadata: Metadata = {
  title: 'Login – Tap'em (Dev-Stub)',
  robots: { index: false, follow: false },
};

export default function Page() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">Anmelden (Dev-Stub)</h1>
      <p className="text-sm text-slate-600">
        Diese Anmeldung setzt Vorschau-Cookies und dient dem Testen der geschützten Bereiche.
        In Production ist der Dev-Login deaktiviert.
      </p>
      <LoginForm />
    </div>
  );
}

6) OG-Bild kompatibel (falls noch nicht)

Datei: website/src/app/opengraph-image.tsx

Sicherstellen: kein display: 'inline-flex', stattdessen display: 'flex'.

Nur einfache Inline-Styles verwenden (keine Tailwind-Klassen in @vercel/og).

7) Externe Links richtig verwenden

Suche und ersetze in website/src/**:

Für externe URLs (https://…) kein next/link, sondern <a href="…" target="_blank" rel="noreferrer noopener">…</a>.

Für interne Routen nur Route-typisierte Werte (aus ROUTES).

8) Dev-Login-API in Produktion sperren (Safety)

Dateien: website/src/app/api/dev/login/route.ts, .../logout/route.ts

Ganz oben:

if (process.env.VERCEL_ENV === 'production') {
  return new Response('dev login disabled in production', { status: 403 });
}


(Logout darf optional 204 zurückgeben ohne 403 – egal für Build, aber klarer.)

9) .env.example belassen/ergänzen (keine Secrets)

Datei: website/.env.example – nur Platzhalter (Firebase später).

10) Doku & Thesis

website/README.md: Abschnitt „typedRoutes & Login-Whitelist“ mit kurzen Prüfhinweisen.

thesis/gamification/YYYY-MM-DD_typedroutes_login_nav_fix.md (neu)
Inhalt: Prompt (dieser Text), Ziel, Kontext (Repo/Branch), Ergebnis (Dateiliste), Links/Screens (optional), Abweichungen.

11) Fallback (nur wenn nötig)

Falls trotz obiger Korrekturen noch einzelne Drittstellen Probleme machen:

In website/next.config.js vorübergehend:

experimental: { typedRoutes: false }


Nicht standardmäßig setzen – nur falls absolut nötig. Standard bleibt true.

Qualität / Checks

npm run build lokal: grün.

vercel --prod: grün.

Manuell testen:

Navbar Links + Gym-Subnav klicken.

/login → Login als owner → /gym.

/login?next=/admin → Login als admin → /admin.

/login?next=/falsch → Redirect auf /gym (Whitelist).

Commits (Beispiele)

fix(website): introduce typed route constants and safe internal links

fix(website): typedRoutes-safe login redirect with whitelist

fix(website): type-safe gym subnav

fix(website): vercel/og css compatibility

docs(website): add typedRoutes and verification notes

docs(thesis): add typedroutes_login_nav_fix log

PR

Titel: fix(website): make project vercel --prod ready (typedRoutes, login redirect, og)
Checkliste: Build/Deploy grün, interne Links typisiert, Login-Redirect whitelisted, OG-Route kompatibel, keine Binaries, Flutter unberührt, Thesis-MD vorhanden.
```

## Ziel
- Typed Routes konsolidieren, Login-Redirect absichern und Build-Kompatibilität für Next.js/Vercel sicherstellen.

## Kontext
- Repository: Wasgehtab97/tapem
- Branch: a_gpt5
- Fokus: `website/` (Next.js-App) und begleitende Thesis-Notiz

## Ergebnis
- `website/src/lib/routes.ts`
- `website/src/app/layout.tsx`
- `website/src/components/gym-subnav.tsx`
- `website/src/app/login/login-form.tsx`
- `website/src/app/login/page.tsx`
- `website/src/app/page.tsx`
- `website/src/app/api/dev/login/route.ts`
- `website/src/app/api/dev/logout/route.ts`
- `website/README.md`
- `thesis/gamification/2025-09-19_typedroutes_login_nav_fix.md`

## Links/Screens
- n/a

## Abweichungen
- Keine
