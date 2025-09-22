import type { Metadata } from 'next';

import { requireRole } from '@/src/lib/auth/server';
import { MonitoringMap } from '@/src/components/monitoring/monitoring-map';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

export const metadata: Metadata = {
  title: 'Monitoring',
  robots: {
    index: false,
    follow: false,
  },
};

export default async function MonitoringPage() {
  await requireRole(['admin', 'owner'], { failure: 'not-found', loginSite: 'admin' });

  return (
    <div className="mx-auto w-full max-w-6xl space-y-8 px-6 py-12">
      <header className="space-y-2">
        <p className="text-sm font-semibold uppercase tracking-wide text-muted">Monitoring</p>
        <h1 className="text-3xl font-semibold text-page">Standorte</h1>
        <p className="max-w-2xl text-sm text-muted">
          Interaktive Übersicht aller Tap&apos;em Studios mit gültigen Koordinaten. Klicke auf einen Marker, um die Detailansicht mit Statusdaten und
          Ereignissen zu öffnen.
        </p>
      </header>
      <MonitoringMap />
    </div>
  );
}
