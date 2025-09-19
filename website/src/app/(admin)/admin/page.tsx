import type { Metadata } from 'next';

import { requireRole } from '@/src/lib/auth/server';

const adminKpis = [
  { label: 'Registrierte Nutzer:innen', value: '8.421', trend: '+5,8 % vs. Vormonat' },
  { label: 'Aktive Gyms', value: '38', trend: '+3 neue Studios' },
  { label: 'Tägliche Aktive Nutzer (DAU)', value: '2.940', trend: '+7,1 % Woche/Woche' },
  { label: 'Verarbeitete Check-ins', value: '124.580', trend: '+12 % im letzten Quartal' },
  { label: 'Gamification Events (24h)', value: '18.302', trend: '+640 vs. Vortag' },
  { label: 'Support Tickets offen', value: '5', trend: '-2 seit gestern' },
];

const adminEventLog = [
  {
    id: 'e-4001',
    timestamp: '2024-04-17 11:42',
    type: 'badge_unlocked',
    details: 'Badge "Morning Hero" automatisch an 134 Mitglieder verliehen.',
  },
  {
    id: 'e-4002',
    timestamp: '2024-04-17 10:58',
    type: 'config_update',
    details: 'Challenge "Spring into Action" um neue Studios ergänzt.',
  },
  {
    id: 'e-4003',
    timestamp: '2024-04-17 10:12',
    type: 'alert_resolved',
    details: 'Webhook-Verzögerung im Standort Hamburg behoben.',
  },
  {
    id: 'e-4004',
    timestamp: '2024-04-17 09:33',
    type: 'new_gym',
    details: 'Neues Studio "Pulse Factory Berlin" erfolgreich on-boarded.',
  },
  {
    id: 'e-4005',
    timestamp: '2024-04-17 08:50',
    type: 'analytics_snapshot',
    details: 'Quartalsreport Q2 Draft generiert.',
  },
];

export const metadata: Metadata = {
  robots: {
    index: false,
    follow: false,
  },
};

export default async function AdminPage() {
  const { user } = await requireRole(['admin'], { failure: 'not-found' });

  return (
    <div className="mx-auto w-full max-w-6xl space-y-12 px-6 py-16">
      <section className="space-y-3">
        <header>
          <p className="text-sm font-semibold uppercase tracking-wide text-slate-500">Admin Monitoring</p>
          <h1 className="mt-1 text-3xl font-semibold text-slate-900">Hallo {user.email}</h1>
          <p className="mt-2 max-w-3xl text-sm text-slate-600">
            Dieses Monitoring-Dashboard nutzt Mock-Daten und dient als Grundgerüst für die
            Firestore/Analytics-Anbindung. KPI-Karten und Event-Streams werden später durch echte
            Services gespeist.
          </p>
        </header>
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {adminKpis.map((kpi) => (
            <article
              key={kpi.label}
              className="rounded-lg border border-subtle bg-card p-5 shadow-sm"
            >
              <p className="text-sm font-medium text-slate-600">{kpi.label}</p>
              <p className="mt-2 text-2xl font-semibold text-slate-900">{kpi.value}</p>
              <p className="mt-1 text-xs text-emerald-600">{kpi.trend}</p>
            </article>
          ))}
        </div>
      </section>
      <section className="space-y-4 rounded-lg border border-subtle bg-card p-6 shadow-sm">
        <header className="space-y-1">
          <h2 className="text-xl font-semibold text-slate-900">Letzte Events</h2>
          <p className="text-sm text-slate-600">
            Auszug aus dem Aktivitätsstream. Die finale Lösung bindet Firestore und BigQuery-Exports
            an.
          </p>
        </header>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-card-muted">
              <tr>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Zeitstempel
                </th>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Event-Typ
                </th>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Details
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {adminEventLog.map((event) => (
                <tr key={event.id} className="hover:bg-card-muted">
                  <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">{event.timestamp}</td>
                  <td className="whitespace-nowrap px-4 py-3 text-sm font-medium text-slate-900">{event.type}</td>
                  <td className="px-4 py-3 text-sm text-slate-700">{event.details}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="rounded-md border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
          Diese Metriken sind Mock-Daten; später Firestore/Analytics anbinden.
        </div>
      </section>
    </div>
  );
}
