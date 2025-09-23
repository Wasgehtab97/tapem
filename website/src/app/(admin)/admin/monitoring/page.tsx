import type { Metadata } from 'next';

import { requireRole } from '@/src/lib/auth/server';
import { MonitoringOverview } from '@/src/components/monitoring/monitoring-overview';

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
    <div className="mx-auto w-full max-w-6xl px-6 py-12">
      <MonitoringOverview />
    </div>
  );
}
