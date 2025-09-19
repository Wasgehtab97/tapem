import type { Metadata } from 'next';
import { headers } from 'next/headers';
import { redirect } from 'next/navigation';
import { Suspense } from 'react';

import AdminLoginForm from '@/src/components/admin/admin-login-form';
import { findSiteByHost, getDeploymentStage, getSiteConfig, type SiteConfig } from '@/src/config/sites';
import { ADMIN_ROUTES } from '@/src/lib/routes';
import { getDevUserFromCookies } from '@/src/lib/auth/server';
import { getAdminUserFromSession } from '@/src/server/auth/session';

import LoginForm from './login-form';

type LoginSite = Extract<SiteConfig['key'], 'portal' | 'admin'>;

function resolveLoginSite(): LoginSite {
  const host = headers().get('host');
  const site = findSiteByHost(host) ?? getSiteConfig('portal');
  return site.key === 'admin' ? 'admin' : 'portal';
}

export const dynamic = 'force-dynamic';

export async function generateMetadata(): Promise<Metadata> {
  const site = resolveLoginSite();

  if (site === 'admin') {
    return {
      title: "Tap'em Admin – Anmeldung",
      robots: { index: false, follow: false },
    } satisfies Metadata;
  }

  return {
    title: "Login – Tap'em (Dev-Stub)",
    robots: { index: false, follow: false },
  } satisfies Metadata;
}

export default async function Page() {
  const site = resolveLoginSite();

  if (site === 'admin') {
    const sessionUser = await getAdminUserFromSession();
    if (sessionUser) {
      redirect(ADMIN_ROUTES.dashboard);
    }

    const stage = getDeploymentStage();
    if (stage !== 'production') {
      const devUser = getDevUserFromCookies();
      if (devUser?.role === 'admin') {
        redirect(ADMIN_ROUTES.dashboard);
      }
    }

    return (
      <div className="mx-auto flex w-full max-w-md flex-col gap-8 px-6 py-16">
        <header className="space-y-2 text-center">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Nur für Administrator:innen</p>
          <h1 className="text-3xl font-semibold text-slate-900">Anmeldung</h1>
          <p className="text-sm text-slate-600">
            Melde dich mit deiner Tap&apos;em Admin-E-Mail an. Nach erfolgreicher Authentifizierung wird ein
            sicheres Session-Cookie gesetzt.
          </p>
        </header>
        <AdminLoginForm />
        <p className="text-xs text-slate-500">
          Bei Problemen kontaktiere bitte das Core-Team. Die Anmeldung nutzt Firebase Authentication mit E-Mail und Passwort.
        </p>
      </div>
    );
  }

  return (
    <div className="mx-auto w-full max-w-xl space-y-6 px-6 py-16">
      <h1 className="text-2xl font-semibold">Anmelden (Dev-Stub)</h1>
      <p className="text-sm text-slate-600">
        Diese Anmeldung setzt Vorschau-Cookies und dient dem Testen der geschützten Bereiche. In Production ist der Dev-Login
        deaktiviert.
      </p>
      <Suspense
        fallback={
          <div className="rounded border border-subtle bg-card p-4 text-sm text-slate-500" aria-live="polite">
            Lade Login-Parameter…
          </div>
        }
      >
        <LoginForm />
      </Suspense>
    </div>
  );
}
