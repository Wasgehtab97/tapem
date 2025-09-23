'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';

import { buildAdminMonitoringDetailRoute } from '@/src/lib/routes';
import type { MonitoringGymListItem } from '@/src/types/monitoring';

const SEARCH_DEBOUNCE_MS = 200;

function sortGyms(gyms: MonitoringGymListItem[]): MonitoringGymListItem[] {
  return [...gyms].sort((a, b) => {
    const nameComparison = a.name.localeCompare(b.name, 'de', {
      sensitivity: 'base',
      numeric: true,
    });
    if (nameComparison !== 0) {
      return nameComparison;
    }
    return a.id.localeCompare(b.id, 'de', { sensitivity: 'base' });
  });
}

function filterGyms(gyms: MonitoringGymListItem[], query: string): MonitoringGymListItem[] {
  if (!query) {
    return gyms;
  }
  const normalized = query.toLowerCase();
  return gyms.filter((gym) => {
    if (gym.name.toLowerCase().includes(normalized)) {
      return true;
    }
    if (gym.code && gym.code.toLowerCase().includes(normalized)) {
      return true;
    }
    if (gym.slug.toLowerCase().includes(normalized)) {
      return true;
    }
    if (gym.countryCode && gym.countryCode.toLowerCase().includes(normalized)) {
      return true;
    }
    return false;
  });
}

type MonitoringGymListProps = {
  gyms: MonitoringGymListItem[];
  loading: boolean;
  error: string | null;
  onRetry: () => void;
  onFocusGym: (gym: MonitoringGymListItem) => void;
  focusedGymId: string | null;
};

const UPDATED_AT_FORMATTER = new Intl.DateTimeFormat('de-DE', {
  dateStyle: 'short',
  timeStyle: 'short',
});

export function MonitoringGymList({
  gyms,
  loading,
  error,
  onRetry,
  onFocusGym,
  focusedGymId,
}: MonitoringGymListProps) {
  const [query, setQuery] = useState('');
  const [debouncedQuery, setDebouncedQuery] = useState('');

  useEffect(() => {
    const timeoutId = window.setTimeout(() => {
      setDebouncedQuery(query.trim());
    }, SEARCH_DEBOUNCE_MS);
    return () => window.clearTimeout(timeoutId);
  }, [query]);

  const sortedGyms = useMemo(() => sortGyms(gyms), [gyms]);
  const filteredGyms = useMemo(() => filterGyms(sortedGyms, debouncedQuery), [sortedGyms, debouncedQuery]);

  const noGymsAvailable = !loading && !error && sortedGyms.length === 0;
  const noMatches = !loading && !error && sortedGyms.length > 0 && filteredGyms.length === 0;

  const showSkeleton = loading && sortedGyms.length === 0;

  const handleFocusGym = (gym: MonitoringGymListItem) => {
    if (!gym.location) {
      return;
    }
    onFocusGym(gym);
  };

  return (
    <section className="space-y-4">
      <div className="space-y-2">
        <label htmlFor="monitoring-gym-search" className="text-xs font-semibold uppercase tracking-wide text-muted">
          Suche
        </label>
        <input
          id="monitoring-gym-search"
          type="search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Studios suchen"
          className="w-full rounded-md border border-subtle bg-app px-3 py-2 text-sm text-page shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
          aria-label="Studios nach Namen, Code oder Land filtern"
        />
      </div>

      {loading && sortedGyms.length > 0 ? (
        <p className="text-xs text-muted">Aktualisiere Daten …</p>
      ) : null}

      {error ? (
        <div className="space-y-2 rounded-md border border-rose-200 bg-rose-50 p-4 text-sm text-rose-900 dark:border-rose-500/40 dark:bg-rose-500/10 dark:text-rose-100">
          <div>
            <p className="font-semibold">Standortliste konnte nicht geladen werden.</p>
            <p>{error}</p>
          </div>
          <button
            type="button"
            onClick={onRetry}
            className="inline-flex items-center justify-center rounded-md border border-primary bg-primary px-3 py-1.5 text-sm font-semibold text-white transition hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
          >
            Erneut versuchen
          </button>
        </div>
      ) : null}

      <div className="space-y-3">
        {showSkeleton ? (
          <ul className="space-y-2">
            {Array.from({ length: 4 }).map((_, index) => (
              <li
                key={index}
                className="animate-pulse rounded-lg border border-subtle bg-card px-4 py-5 text-sm text-muted"
              >
                Lade Standorte …
              </li>
            ))}
          </ul>
        ) : null}

        {!showSkeleton ? (
          <ul className="space-y-2">
            {filteredGyms.map((gym) => {
              const metaParts = [] as string[];
              if (gym.countryCode) {
                metaParts.push(gym.countryCode);
              }
              if (gym.code) {
                metaParts.push(`Code ${gym.code}`);
              }
              const updatedLabel = gym.statusUpdatedAt
                ? UPDATED_AT_FORMATTER.format(new Date(gym.statusUpdatedAt))
                : null;
              const detailHref = buildAdminMonitoringDetailRoute(gym.id);
              const isFocused = focusedGymId === gym.id;

              return (
                <li key={gym.id}>
                  <div
                    className={`overflow-hidden rounded-lg border bg-card shadow-sm transition ${
                      isFocused ? 'border-primary ring-1 ring-primary/40' : 'border-subtle'
                    }`}
                  >
                    <button
                      type="button"
                      onClick={() => handleFocusGym(gym)}
                      className={`flex w-full flex-col items-start gap-3 px-4 py-3 text-left transition ${
                        gym.location ? 'hover:bg-muted/20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary' : 'cursor-not-allowed opacity-60'
                      }`}
                      disabled={!gym.location}
                      title={gym.location ? `Marker für ${gym.name} fokussieren` : 'Keine Koordinate vorhanden'}
                    >
                      <div className="flex w-full flex-wrap items-center justify-between gap-3">
                        <div className="space-y-1">
                          <p className="text-sm font-semibold text-page">{gym.name}</p>
                          <p className="text-xs text-muted">
                            {metaParts.length > 0 ? metaParts.join(' · ') : '—'}
                          </p>
                        </div>
                        <span
                          className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold ${
                            gym.active
                              ? 'border border-emerald-300 bg-emerald-100 text-emerald-900 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-200'
                              : 'border border-amber-300 bg-amber-100 text-amber-900 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-200'
                          }`}
                        >
                          {gym.active ? 'Aktiv' : 'Inaktiv'}
                        </span>
                      </div>
                      <p className="text-xs text-muted">
                        {gym.location ? 'Koordinate vorhanden' : 'Keine Koordinate hinterlegt'}
                      </p>
                    </button>
                    <div className="flex items-center justify-between border-t border-subtle px-4 py-2 text-xs text-muted">
                      {updatedLabel ? <span>Aktualisiert: {updatedLabel}</span> : <span>Aktualisiert: —</span>}
                      <Link
                        href={detailHref}
                        className="text-sm font-semibold text-primary underline-offset-4 hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                      >
                        Details<span aria-hidden> →</span>
                      </Link>
                    </div>
                  </div>
                </li>
              );
            })}
          </ul>
        ) : null}
      </div>

      {noGymsAvailable ? (
        <div className="rounded-md border border-subtle bg-card px-4 py-6 text-center text-sm text-muted">
          <p className="font-semibold text-page">Keine Standorte gefunden</p>
          <p>Es sind aktuell keine Studios im DACH-Raum verfügbar.</p>
        </div>
      ) : null}

      {noMatches ? (
        <div className="rounded-md border border-subtle bg-card px-4 py-6 text-center text-sm text-muted">
          <p className="font-semibold text-page">Keine Treffer</p>
          <p>
            Kein Studio entspricht dem Filter
            {debouncedQuery ? ` „${debouncedQuery}“` : ''}.
          </p>
        </div>
      ) : null}
    </section>
  );
}
