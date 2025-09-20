import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

import AdminLoginForm from '@/src/components/admin/admin-login-form';
import { getDeploymentStage } from '@/src/config/sites';
import { getDevUserFromCookies } from '@/src/lib/auth/server';
import { ADMIN_ROUTES } from '@/src/lib/routes';
import { getAdminUserFromSession } from '@/src/server/auth/session';

export const dynamic = 'force-dynamic';

export const metadata: Metadata = {
  title: "Tap'em Admin – Anmeldung",
  robots: { index: false, follow: false },
};

export default async function AdminLoginPage() {
  const sessionUser = await getAdminUserFromSession();
  if (sessionUser) {
    redirect(ADMIN_ROUTES.dashboard.href);
  }

  const stage = getDeploymentStage();
  if (stage !== 'production') {
    const devUser = getDevUserFromCookies();
    if (devUser?.role === 'admin') {
      redirect(ADMIN_ROUTES.dashboard.href);
    }
  }

  return (
    <div className="mx-auto flex w-full max-w-md flex-col gap-8 px-6 py-16">
      <header className="space-y-2 text-center">
        <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
          Nur für Administrator:innen
        </p>
        <h1 className="text-3xl font-semibold text-slate-900">Anmeldung</h1>
        <p className="text-sm text-slate-600">
          Melde dich mit deiner Tap&apos;em Admin-E-Mail an. Nach erfolgreicher Authentifizierung wird ein sicheres
          Session-Cookie gesetzt.
        </p>
      </header>
      <AdminLoginForm />
      <p className="text-xs text-slate-500">
        Bei Problemen kontaktiere bitte das Core-Team. Die Anmeldung nutzt Firebase Authentication mit E-Mail und Passwort.
      </p>
    </div>
  );
}
