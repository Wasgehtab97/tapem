import AdminLoginForm from '@/src/components/admin/admin-login-form';
import Link from 'next/link';
import { MARKETING_ROUTES } from '@/src/lib/routes';

export const runtime = 'nodejs'; // page selbst ist RSC, ok
export const dynamic = 'force-dynamic';

export default async function Page() {
  // Optional: Health-Badge vom Server
  const r = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL ?? ''}/api/health/firebase-admin`, { cache: 'no-store' }).catch(()=>null);
  const info = r?.ok ? await r.json() : null;

  return (
    <div className="max-w-lg mx-auto py-10 grid gap-6">
      {info && (
        <div className="rounded-md bg-emerald-100/10 border border-emerald-400 p-3 text-emerald-200">
          Verbunden mit Projekt <b>{info.projectId}</b> · Modus <b>{info.mode}</b> · Service Account {info.usesServiceAccount ? 'aktiv' : 'inaktiv'}
        </div>
      )}
      <h1 className="text-2xl font-semibold">Anmeldung</h1>
      <AdminLoginForm />
      <p className="text-sm opacity-60">Bei Problemen: Core-Team kontaktieren.</p>
      <p className="text-xs opacity-40"><Link href={MARKETING_ROUTES.home.href}>Zurück</Link></p>
    </div>
  );
}
