import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';

import { requireRole } from '@/src/lib/auth/server';
import { ADMIN_ROUTES } from '@/src/lib/routes';
import { GymActivityFeed } from '@/src/components/admin/gym-activity-feed';
import { fetchGymEventLogs, fetchGymMonitoringSummary } from '@/src/server/monitoring';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

const numberFormatter = new Intl.NumberFormat('de-DE');
const dateTimeFormatter = new Intl.DateTimeFormat('de-DE', {
  dateStyle: 'medium',
  timeStyle: 'short',
});

const STATUS_BADGES: Record<'online' | 'offline' | 'degraded' | 'unknown', string> = {
  online: 'bg-emerald-100 text-emerald-900 border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-200 dark:border-emerald-500/40',
  offline: 'bg-rose-100 text-rose-900 border-rose-200 dark:bg-rose-500/10 dark:text-rose-200 dark:border-rose-500/40',
  degraded: 'bg-amber-100 text-amber-900 border-amber-200 dark:bg-amber-500/10 dark:text-amber-200 dark:border-amber-500/40',
  unknown: 'bg-slate-200 text-slate-900 border-slate-300 dark:bg-slate-500/10 dark:text-slate-200 dark:border-slate-500/40',
};

export const metadata: Metadata = {
  title: 'Monitoring',
  robots: {
    index: false,
    follow: false,
  },
};

type PageProps = {
  params: { gymId: string };
  searchParams?: { cursor?: string };
};

function formatNumber(value: number | null | undefined): string {
  if (typeof value !== 'number') {
    return '—';
  }
  return numberFormatter.format(value);
}

function formatTimestamp(value: Date | null | undefined): string {
  if (!value) {
    return '—';
  }
  return dateTimeFormatter.format(value);
}

function resolveStatusBadge(status: 'online' | 'offline' | 'degraded' | null | undefined) {
  if (status === 'online') return STATUS_BADGES.online;
  if (status === 'offline') return STATUS_BADGES.offline;
  if (status === 'degraded') return STATUS_BADGES.degraded;
  return STATUS_BADGES.unknown;
}

function resolveStatusLabel(status: 'online' | 'offline' | 'degraded' | null | undefined) {
  if (status === 'online') return 'Online';
  if (status === 'offline') return 'Offline';
  if (status === 'degraded') return 'Eingeschränkt';
  return 'Unbekannt';
}

export default async function MonitoringDetailPage({ params, searchParams }: PageProps) {
  await requireRole(['admin', 'owner'], { failure: 'not-found', loginSite: 'admin' });

  const summary = await fetchGymMonitoringSummary(params.gymId);
  if (!summary) {
    notFound();
  }

  const events = await fetchGymEventLogs(params.gymId, {
    limit: 20,
    cursor: searchParams?.cursor ?? null,
  });

  const initialEvents = events.entries.map((entry) => ({
    id: entry.id,
    gymId: entry.gymId,
    timestamp: entry.timestamp.toISOString(),
    eventType: entry.eventType,
    severity: entry.severity ?? 'info',
    source: entry.source ?? 'system',
    summary: entry.summary ?? null,
    userId: entry.userId ?? null,
    deviceId: entry.deviceId ?? null,
    sessionId: entry.sessionId ?? null,
    actor: entry.actor ?? null,
    targets: entry.targets ?? [],
    data: entry.data ?? null,
  }));

  const status = summary.status?.status ?? null;
  const statusLabel = resolveStatusLabel(status);
  const statusUpdatedAtLabel = formatTimestamp(summary.statusUpdatedAt);

  const locationParts = [summary.city, summary.state].filter((part): part is string => Boolean(part));
  const locationLabel = locationParts.length > 0 ? locationParts.join(' · ') : 'Keine Ortsangabe';
  const coordinateLabel = summary.location
    ? `${summary.location.lat.toFixed(5)}, ${summary.location.lng.toFixed(5)}`
    : '—';
  const infoItems: { label: string; value: string }[] = [
    { label: 'Slug', value: summary.slug },
    { label: 'Code', value: summary.code ?? '—' },
    { label: 'Land', value: summary.countryCode ?? '—' },
    { label: 'Koordinaten', value: coordinateLabel },
    { label: 'Aktiv', value: summary.active ? 'Ja' : 'Nein' },
  ];

  return (
    <div className="mx-auto w-full max-w-5xl space-y-10 px-6 py-12">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold uppercase tracking-wide text-muted">Monitoring</p>
          <h1 className="mt-1 text-3xl font-semibold text-page">{summary.name}</h1>
          <p className="mt-2 text-sm text-muted">{locationLabel}</p>
          <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2 lg:grid-cols-3">
            {infoItems.map((item) => (
              <div key={item.label} className="space-y-1">
                <dt className="text-xs font-semibold uppercase tracking-wide text-muted">{item.label}</dt>
                <dd className="text-sm text-page">{item.value}</dd>
              </div>
            ))}
          </dl>
        </div>
        <div className="flex flex-col items-end gap-3 text-right">
          <span
            className={`inline-flex items-center gap-2 rounded-full border px-3 py-1 text-sm font-semibold ${resolveStatusBadge(status)}`}
          >
            <span className="inline-flex h-2 w-2 rounded-full bg-current opacity-80" aria-hidden />
            {statusLabel}
          </span>
          <Link
            href={ADMIN_ROUTES.monitoring.href}
            className="text-sm font-semibold text-primary underline-offset-4 hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
          >
            Zur Karte
          </Link>
        </div>
      </div>

      <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <article className="rounded-lg border border-subtle bg-card p-5 shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Check-ins (24h)</p>
          <p className="mt-2 text-2xl font-semibold text-page">{formatNumber(summary.status?.checkins24h)}</p>
        </article>
        <article className="rounded-lg border border-subtle bg-card p-5 shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Geräte online</p>
          <p className="mt-2 text-2xl font-semibold text-page">{formatNumber(summary.deviceCount)}</p>
        </article>
        <article className="rounded-lg border border-subtle bg-card p-5 shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Letztes Ereignis</p>
          <p className="mt-2 text-base font-semibold text-page">{formatTimestamp(summary.status?.lastEventAt ?? null)}</p>
        </article>
        <article className="rounded-lg border border-subtle bg-card p-5 shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Letzte Status-Aktualisierung</p>
          <p className="mt-2 text-base font-semibold text-page">{statusUpdatedAtLabel}</p>
        </article>
      </section>

      <GymActivityFeed
        gymId={params.gymId}
        initialEvents={initialEvents}
        initialCursor={events.nextCursor}
        initialStats={events.stats}
        initialWarnings={events.warnings}
      />
    </div>
  );
}
