'use client';

import { useCallback, useEffect, useMemo, useRef, useState, type FormEvent } from 'react';

import { AdminEventLogTable } from '@/src/components/admin/admin-event-log-table';
import type { ActivityEventStats, AdminActivityEvent, GymActivityResponse } from '@/src/types/admin-activity';

const numberFormatter = new Intl.NumberFormat('de-DE');
const dateTimeFormatter = new Intl.DateTimeFormat('de-DE', {
  dateStyle: 'medium',
  timeStyle: 'short',
});

const KNOWN_EVENT_TYPES = [
  'training.set_logged',
  'auth.login',
  'auth.register',
  'friend.request_sent',
  'friend.request_accepted',
  'challenge.joined',
  'challenge.completed',
  'device.status_changed',
  'device.offline_detected',
  'device.online_detected',
  'admin.adjustment',
  'backend.error_reported',
];

type AppliedFilters = {
  range: '24h' | '7d' | '30d' | 'custom';
  from?: string | null;
  to?: string | null;
  types: string[];
  severity: string[];
  userId?: string;
  deviceId?: string;
};

type Props = {
  gymId: string;
  initialEvents: AdminActivityEvent[];
  initialCursor: string | null;
  initialStats: ActivityEventStats;
  initialWarnings: string[];
};

function createDateInputValue(iso: string | undefined | null): string {
  if (!iso) {
    return '';
  }
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return '';
  }
  return date.toISOString().slice(0, 16);
}

function computeRangeDates(range: AppliedFilters['range'], customFrom?: string | null, customTo?: string | null) {
  const now = new Date();
  if (range === '24h') {
    return { from: new Date(now.getTime() - 24 * 60 * 60 * 1000), to: now };
  }
  if (range === '7d') {
    return { from: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000), to: now };
  }
  if (range === '30d') {
    return { from: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000), to: now };
  }
  if (customFrom) {
    const from = new Date(customFrom);
    const to = customTo ? new Date(customTo) : now;
    if (!Number.isNaN(from.getTime()) && !Number.isNaN(to.getTime())) {
      return { from, to };
    }
  }
  return { from: null, to: null };
}

function formatNumber(value: number) {
  return numberFormatter.format(value);
}

function parseEvents(items: AdminActivityEvent[]) {
  return items.map((item) => ({
    ...item,
    timestamp: new Date(item.timestamp),
  }));
}

export function GymActivityFeed({ gymId, initialEvents, initialCursor, initialStats, initialWarnings }: Props) {
  const [events, setEvents] = useState<AdminActivityEvent[]>(initialEvents);
  const [cursor, setCursor] = useState<string | null>(initialCursor);
  const [stats, setStats] = useState<ActivityEventStats>(initialStats);
  const [warnings, setWarnings] = useState<string[]>(initialWarnings);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState<AppliedFilters>({
    range: '7d',
    types: [],
    severity: [],
  });
  const [customFrom, setCustomFrom] = useState<string>('');
  const [customTo, setCustomTo] = useState<string>('');
  const abortRef = useRef<AbortController | null>(null);
  const filtersRef = useRef<AppliedFilters>({
    range: '7d',
    types: [],
    severity: [],
  });

  useEffect(() => {
    if (filters.range === 'custom') {
      setCustomFrom(createDateInputValue(filters.from ?? null));
      setCustomTo(createDateInputValue(filters.to ?? null));
    }
  }, []);

  useEffect(() => {
    filtersRef.current = filters;
  }, [filters]);

  const fetchEvents = useCallback(
    async ({
      append,
      cursorOverride,
      overrideFilters,
    }: {
      append: boolean;
      cursorOverride?: string | null;
      overrideFilters?: AppliedFilters;
    }) => {
      const controller = new AbortController();
      if (abortRef.current) {
        abortRef.current.abort();
      }
      abortRef.current = controller;
      setLoading(true);
      setError(null);

      const activeFilters = overrideFilters ?? filtersRef.current;
      const { from, to } = computeRangeDates(activeFilters.range, activeFilters.from, activeFilters.to);
      const params = new URLSearchParams();
      params.set('limit', append ? '50' : '100');
      if (from instanceof Date && !Number.isNaN(from.getTime())) {
        params.set('from', from.toISOString());
      }
      if (to instanceof Date && !Number.isNaN(to.getTime())) {
        params.set('to', to.toISOString());
      }
      if (activeFilters.types.length > 0) {
        params.set('types', activeFilters.types.join(','));
      }
      if (activeFilters.severity.length > 0) {
        params.set('severity', activeFilters.severity.join(','));
      }
      if (activeFilters.userId?.trim()) {
        params.set('userId', activeFilters.userId.trim());
      }
      if (activeFilters.deviceId?.trim()) {
        params.set('deviceId', activeFilters.deviceId.trim());
      }
      if (cursorOverride) {
        params.set('cursor', cursorOverride);
      }

      try {
        const response = await fetch(`/api/admin/gyms/${encodeURIComponent(gymId)}/events?${params.toString()}`, {
          method: 'GET',
          headers: { Accept: 'application/json' },
          signal: controller.signal,
        });
        if (!response.ok) {
          const body = await response.json().catch(() => ({ error: 'unknown' }));
          setError('Aktivitäten konnten nicht geladen werden.');
          setWarnings((prev) => [...prev, body.error ?? 'http-error']);
          return;
        }
        const payload = (await response.json()) as GymActivityResponse;
        setCursor(payload.nextCursor ?? null);
        setStats(payload.stats);
        setWarnings(payload.warnings ?? []);
        setEvents((prev) => (append ? [...prev, ...payload.items] : payload.items));
      } catch (fetchError) {
        if ((fetchError as { name?: string }).name === 'AbortError') {
          return;
        }
        setError('Netzwerkfehler beim Laden des Aktivitätsstreams.');
      } finally {
        setLoading(false);
      }
    },
    [gymId]
  );

  const handleApplyFilters = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      const formData = new FormData(event.currentTarget);
      const range = (formData.get('range') as AppliedFilters['range']) ?? '7d';
      const selectedTypes = formData.getAll('eventTypes') as string[];
      const selectedSeverity = formData.getAll('severity') as string[];
      const nextFilters: AppliedFilters = {
        range,
        types: selectedTypes,
        severity: selectedSeverity,
        userId: (formData.get('userId') as string | null) ?? undefined,
        deviceId: (formData.get('deviceId') as string | null) ?? undefined,
      };
      if (range === 'custom') {
        const nextFrom = formData.get('customFrom') as string | null;
        const nextTo = formData.get('customTo') as string | null;
        nextFilters.from = nextFrom && nextFrom.trim().length > 0 ? new Date(nextFrom).toISOString() : null;
        nextFilters.to = nextTo && nextTo.trim().length > 0 ? new Date(nextTo).toISOString() : null;
        setCustomFrom(nextFrom ?? '');
        setCustomTo(nextTo ?? '');
      } else {
        setCustomFrom('');
        setCustomTo('');
        nextFilters.from = undefined;
        nextFilters.to = undefined;
      }
      setFilters(nextFilters);
      fetchEvents({ append: false, cursorOverride: null, overrideFilters: nextFilters });
    },
    [fetchEvents]
  );

  const handleLoadMore = useCallback(() => {
    if (!cursor) {
      return;
    }
    fetchEvents({ append: true, cursorOverride: cursor });
  }, [cursor, fetchEvents]);

  const handleReset = useCallback(() => {
    const defaults: AppliedFilters = { range: '7d', types: [], severity: [] };
    setFilters(defaults);
    setCustomFrom('');
    setCustomTo('');
    fetchEvents({ append: false, cursorOverride: null, overrideFilters: defaults });
  }, [fetchEvents]);

  const statsItems = [
    { label: 'Gesamt', value: stats.total },
    { label: 'Letzte 24 h', value: stats.last24h },
    { label: 'Letzte 7 Tage', value: stats.last7d },
    { label: 'Letzte 30 Tage', value: stats.last30d },
  ];

  const tableEntries = useMemo(() => parseEvents(events), [events]);

  return (
    <div className="space-y-6">
      <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {statsItems.map((item) => (
          <article key={item.label} className="rounded-lg border border-subtle bg-card p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">{item.label}</p>
            <p className="mt-2 text-2xl font-semibold text-page">{formatNumber(item.value)}</p>
          </article>
        ))}
      </section>

      <form
        key={JSON.stringify(filters)}
        onSubmit={handleApplyFilters}
        className="space-y-4 rounded-lg border border-subtle bg-card p-4 shadow-sm"
      >
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <label className="space-y-2 text-sm text-muted">
            <span className="block text-xs font-semibold uppercase tracking-wide">Zeitraum</span>
            <select name="range" defaultValue={filters.range} className="w-full rounded border border-subtle bg-card px-3 py-2 text-sm text-page">
              <option value="24h">Letzte 24 Stunden</option>
              <option value="7d">Letzte 7 Tage</option>
              <option value="30d">Letzte 30 Tage</option>
              <option value="custom">Benutzerdefiniert</option>
            </select>
          </label>

          {filters.range === 'custom' ? (
            <div className="space-y-4 md:col-span-2 lg:col-span-2">
              <label className="space-y-2 text-sm text-muted">
                <span className="block text-xs font-semibold uppercase tracking-wide">Von</span>
                <input
                  type="datetime-local"
                  name="customFrom"
                  defaultValue={customFrom}
                  className="w-full rounded border border-subtle bg-card px-3 py-2 text-sm text-page"
                  max={customTo || undefined}
                />
              </label>
              <label className="space-y-2 text-sm text-muted">
                <span className="block text-xs font-semibold uppercase tracking-wide">Bis</span>
                <input
                  type="datetime-local"
                  name="customTo"
                  defaultValue={customTo}
                  className="w-full rounded border border-subtle bg-card px-3 py-2 text-sm text-page"
                />
              </label>
            </div>
          ) : null}

          <label className="space-y-2 text-sm text-muted">
            <span className="block text-xs font-semibold uppercase tracking-wide">Event-Typen</span>
            <select
              name="eventTypes"
              multiple
              defaultValue={filters.types}
              className="h-32 w-full rounded border border-subtle bg-card px-3 py-2 text-sm text-page"
            >
              {KNOWN_EVENT_TYPES.map((type) => (
                <option key={type} value={type}>
                  {type}
                </option>
              ))}
            </select>
            <span className="block text-xs text-muted">Strg/Cmd gedrückt halten für Mehrfachauswahl.</span>
          </label>

          <fieldset className="space-y-2 text-sm text-muted">
            <legend className="text-xs font-semibold uppercase tracking-wide">Severity</legend>
            {['info', 'warning', 'error'].map((severity) => (
              <label key={severity} className="flex items-center gap-2">
                <input
                  type="checkbox"
                  name="severity"
                  value={severity}
                  defaultChecked={filters.severity.includes(severity)}
                  className="h-4 w-4 rounded border-subtle text-primary focus:ring-primary"
                />
                <span className="text-sm text-page">{severity}</span>
              </label>
            ))}
          </fieldset>

          <label className="space-y-2 text-sm text-muted">
            <span className="block text-xs font-semibold uppercase tracking-wide">User ID</span>
            <input
              type="text"
              name="userId"
              defaultValue={filters.userId ?? ''}
              className="w-full rounded border border-subtle bg-card px-3 py-2 text-sm text-page"
              placeholder="optional"
            />
          </label>

          <label className="space-y-2 text-sm text-muted">
            <span className="block text-xs font-semibold uppercase tracking-wide">Device ID</span>
            <input
              type="text"
              name="deviceId"
              defaultValue={filters.deviceId ?? ''}
              className="w-full rounded border border-subtle bg-card px-3 py-2 text-sm text-page"
              placeholder="optional"
            />
          </label>
        </div>

        <div className="flex justify-end gap-2">
          <button
            type="button"
            onClick={handleReset}
            className="rounded border border-subtle px-4 py-2 text-sm font-semibold text-muted hover:bg-card-muted"
          >
            Zurücksetzen
          </button>
          <button
            type="submit"
            className="rounded bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground shadow hover:bg-primary/90 disabled:opacity-70"
            disabled={loading}
          >
            {loading ? 'Lädt…' : 'Filter anwenden'}
          </button>
        </div>
      </form>

      {warnings.length > 0 ? (
        <div className="rounded-md border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 dark:border-amber-500/60 dark:bg-amber-500/10 dark:text-amber-200">
          {warnings.includes('index-required')
            ? 'Firestore Index wird erstellt oder fehlt. Ergebnisse können unvollständig sein.'
            : 'Für einige Kennzahlen konnten keine Zähler berechnet werden.'}
        </div>
      ) : null}

      {error ? (
        <div className="rounded-md border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800 dark:border-rose-500/60 dark:bg-rose-500/10 dark:text-rose-200">
          {error}
        </div>
      ) : null}

      <div className="space-y-4 rounded-lg border border-subtle bg-card p-4 shadow-sm">
        <header className="space-y-1">
          <h3 className="text-lg font-semibold text-page">Aktivitätsstream</h3>
          <p className="text-sm text-muted">
            Gefilterte Ereignisse für dieses Gym. Zeitzone basiert auf Browser-Einstellungen.
          </p>
        </header>
        <AdminEventLogTable
          entries={tableEntries.map((entry) => ({
            ...entry,
            timestamp: entry.timestamp instanceof Date ? entry.timestamp : new Date(entry.timestamp),
          }))}
          formatTimestamp={(date) => dateTimeFormatter.format(date)}
          emptyLabel="Keine Ereignisse gefunden."
          showGymColumn={false}
        />
        {cursor ? (
          <div className="text-right">
            <button
              type="button"
              onClick={handleLoadMore}
              disabled={loading}
              className="text-sm font-semibold text-primary underline-offset-4 hover:underline disabled:opacity-60"
            >
              {loading ? 'Lädt…' : 'Weitere Ereignisse laden'}
            </button>
          </div>
        ) : null}
      </div>
    </div>
  );
}
