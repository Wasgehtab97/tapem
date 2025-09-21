import { headers } from 'next/headers';
import Link from 'next/link';

import AdminLoginForm from '@/src/components/admin/admin-login-form';
import { MARKETING_ROUTES } from '@/src/lib/routes';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

type HealthSummary = {
  ok: boolean;
  projectId: string | null;
  mode: 'production' | 'emulator';
  usesServiceAccount: boolean;
};

async function fetchFirebaseAdminHealth(): Promise<HealthSummary | null> {
  const headerList = headers();
  const host = headerList.get('host');
  if (!host) {
    return null;
  }

  const forwardedProto = headerList.get('x-forwarded-proto');
  const protocol = forwardedProto ? forwardedProto.split(',')[0] : 'http';
  const url = `${protocol}://${host}/api/health/firebase-admin`;

  try {
    const response = await fetch(url, { cache: 'no-store' });
    if (!response.ok) {
      return null;
    }
    const data = (await response.json()) as HealthSummary;
    return data.ok ? data : null;
  } catch {
    return null;
  }
}

export default async function Page() {
  const info = await fetchFirebaseAdminHealth();

  return (
    <div className="mx-auto grid max-w-lg gap-6 py-10">
      {info && (
        <div className="rounded-md border border-emerald-400 bg-emerald-100/10 p-3 text-emerald-200">
          Verbunden mit Projekt <b>{info.projectId}</b> · Modus <b>{info.mode}</b> · Service Account{' '}
          {info.usesServiceAccount ? 'aktiv' : 'inaktiv'}
        </div>
      )}
      <h1 className="text-2xl font-semibold">Anmeldung</h1>
      <AdminLoginForm />
      <p className="text-sm opacity-60">Bei Problemen: Core-Team kontaktieren.</p>
      <p className="text-xs opacity-40">
        <Link href={MARKETING_ROUTES.home.href}>Zurück</Link>
      </p>
    </div>
  );
}
