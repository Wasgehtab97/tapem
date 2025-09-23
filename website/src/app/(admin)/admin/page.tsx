import type { Metadata } from 'next';

import { requireRole } from '@/lib/auth/server';
import { ADMIN_ROUTES } from '@/lib/routes';
import { fetchAdminDashboardData } from '@/server/admin/dashboard-data';
import { AdminEventLogTable } from '@/components/admin/admin-event-log-table';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

const numberFormatter = new Intl.NumberFormat('de-DE');
const dateTimeFormatter = new Intl.DateTimeFormat('de-DE', {
  dateStyle: 'medium',
  timeStyle: 'short',
});
const dayFormatter = new Intl.DateTimeFormat('de-DE', {
  day: '2-digit',
  month: '2-digit',
});

function formatNumber(value: number): string {
  return numberFormatter.format(value);
}

function formatDateTime(date: Date): string {
  return dateTimeFormatter.format(date);
}

function ActivityChart({
  points,
}: {
  points: Array<{ date: string; totalCheckIns: number }>;
}) {
  if (points.length === 0) {
    return (
      <div className="rounded-lg border border-dashed border-subtle bg-card p-6 text-sm text-muted">
        Keine Check-in-Daten für den ausgewählten Zeitraum vorhanden.
      </div>
    );
  }

  const max = Math.max(...points.map((point) => point.totalCheckIns), 1);
  const chartHeight = 180;
  const barWidth = 18;
  const gap = 10;
  const chartWidth = points.length * (barWidth + gap) + gap;

  return (
    <svg
      role="img"
      aria-label="Check-ins der letzten 14 Tage"
      viewBox={`0 0 ${chartWidth} ${chartHeight + 32}`}
      className="w-full"
    >
      <title>Check-ins der letzten 14 Tage</title>
      <desc>Visualisierung der täglichen Check-ins über zwei Wochen.</desc>
      <line x1={0} y1={chartHeight} x2={chartWidth} y2={chartHeight} stroke="var(--page-border)" strokeWidth={1} />
      {points.map((point, index) => {
        const value = point.totalCheckIns;
        const barHeight = max > 0 ? Math.round((value / max) * (chartHeight - 16)) : 0;
        const x = gap + index * (barWidth + gap);
        const y = chartHeight - barHeight;
        return (
          <g key={point.date}>
            <rect
              x={x}
              y={y}
              width={barWidth}
              height={barHeight}
              rx={4}
              className="fill-primary/70"
            />
            <text
              x={x + barWidth / 2}
              y={chartHeight + 16}
              textAnchor="middle"
              className="fill-[var(--page-muted)] text-[10px]"
            >
              {dayFormatter.format(new Date(point.date))}
            </text>
            <text
              x={x + barWidth / 2}
              y={y - 6}
              textAnchor="middle"
              className="fill-[var(--page-muted)] text-[10px]"
            >
              {value}
            </text>
          </g>
        );
      })}
    </svg>
  );
}

export const metadata: Metadata = {
  robots: {
    index: false,
    follow: false,
  },
};

export default async function AdminPage() {
  const { user } = await requireRole(['admin', 'owner'], { failure: 'not-found', loginSite: 'admin' });
  const dashboard = await fetchAdminDashboardData();

  const metricHelpers: Record<string, string> = {
    gyms: 'Alle Studios (Collection gyms)',
    members: 'Registrierte Nutzer:innen (Collection users)',
    checkins24h: 'Verarbeitete Logs innerhalb der letzten 24 Stunden',
    checkins30d: 'Summe der Logs in den letzten 30 Tagen',
    activeChallenges: 'Offene Challenges (Collection challenges)',
    dau: 'Eindeutige Nutzer:innen (Logs 24h)',
  };

  return (
    <div className="mx-auto w-full max-w-6xl space-y-12 px-6 py-16">
      <section className="space-y-3">
        <header>
          <p className="text-sm font-semibold uppercase tracking-wide text-muted">Admin Monitoring</p>
          <h1 className="mt-1 text-3xl font-semibold text-page">Hallo {user.email}</h1>
          <p className="mt-2 max-w-3xl text-sm text-muted">
            Dieses Dashboard fasst Kernmetriken aus Firestore zusammen und zeigt einen aktuellen Ereignis-Stream.
            Alle Serverabfragen werden ausschließlich über das Firebase Admin SDK ausgeführt.
          </p>
        </header>
        {dashboard.metrics.error ? (
          <div className="rounded-md border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 dark:border-amber-500/60 dark:bg-amber-500/10 dark:text-amber-200">
            {dashboard.metrics.error}
          </div>
        ) : null}
        {dashboard.metrics.warnings.length > 0 ? (
          <div className="rounded-md border border-amber-200 bg-amber-50 px-4 py-3 text-xs text-amber-800 dark:border-amber-500/60 dark:bg-amber-500/10 dark:text-amber-200">
            <p className="font-semibold">Hinweis:</p>
            <ul className="mt-1 space-y-1">
              {dashboard.metrics.warnings.map((warning) => (
                <li key={warning.metricId}>
                  {warning.message}{' '}
                  {warning.indexUrl ? (
                    <a
                      href={warning.indexUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="underline"
                    >
                      Index öffnen
                    </a>
                  ) : null}
                </li>
              ))}
            </ul>
          </div>
        ) : null}
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {dashboard.metrics.items.map((metric) => (
            <article key={metric.id} className="rounded-lg border border-subtle bg-card p-5 shadow-sm">
              <p className="text-sm font-medium text-muted">{metric.label}</p>
              <p className="mt-2 text-2xl font-semibold text-page">{formatNumber(metric.value)}</p>
              <p className="mt-1 text-xs text-muted">{metricHelpers[metric.id] ?? ''}</p>
            </article>
          ))}
        </div>
        <p className="text-xs text-muted">
          Stand: {formatDateTime(dashboard.metrics.generatedAt)} · Datenquelle: Firestore (Tap&apos;em Projekt)
        </p>
      </section>

      <section className="space-y-4 rounded-lg border border-subtle bg-card p-6 shadow-sm">
        <header className="space-y-1">
          <h2 className="text-xl font-semibold text-page">Check-in Verlauf (14 Tage)</h2>
          <p className="text-sm text-muted">
            Zeigt die Anzahl verarbeiteter Check-ins über alle Gyms. Grundlage ist der Logs-CollectionGroup in Firestore.
          </p>
        </header>
        {dashboard.activity.error ? (
          <div className="rounded-md border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 dark:border-amber-500/60 dark:bg-amber-500/10 dark:text-amber-200">
            {dashboard.activity.error}
          </div>
        ) : null}
        <ActivityChart points={dashboard.activity.points} />
      </section>

      <section className="space-y-4 rounded-lg border border-subtle bg-card p-6 shadow-sm">
        <header className="space-y-1">
          <h2 className="text-xl font-semibold text-page">Letzte Ereignisse</h2>
          <p className="text-sm text-muted">
            Vereinheitlichter Aktivitäten-Stream pro Gym. Zeigt Quelle, Typ, Betroffene sowie Metadaten.
          </p>
        </header>
        {dashboard.events.error ? (
          <div className="rounded-md border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 dark:border-amber-500/60 dark:bg-amber-500/10 dark:text-amber-200">
            {dashboard.events.error}
          </div>
        ) : null}
        <AdminEventLogTable
          entries={dashboard.events.items}
          formatTimestamp={formatDateTime}
          emptyLabel="Keine aktuellen Ereignisse vorhanden."
          showGymColumn
        />
        <p className="text-xs text-muted">
          Quelle: Firestore collectionGroup('activity') · Zugriff nur mit Admin-Session
        </p>
      </section>

      <section className="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-5 text-sm text-emerald-900">
        Zugriffsschutz aktiv. Du kannst dich jederzeit über <a className="font-semibold underline" href={ADMIN_ROUTES.logout.href}>Abmelden</a>, um das Session-Cookie zu löschen.
      </section>
    </div>
  );
}
