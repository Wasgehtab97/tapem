'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

import { MonitoringGymList } from '@/src/components/monitoring/monitoring-gym-list';
import { MonitoringMap, type MonitoringMapHandle } from '@/src/components/monitoring/monitoring-map';
import { useMonitoringGyms } from '@/src/components/monitoring/use-monitoring-gyms';
import type { MonitoringGymListItem } from '@/src/types/monitoring';

const FOCUS_ZOOM = 13;

export function MonitoringOverview() {
  const { data, loading, error, isInitialLoading, reload } = useMonitoringGyms();
  const mapRef = useRef<MonitoringMapHandle | null>(null);
  const [focusedGymId, setFocusedGymId] = useState<string | null>(null);

  const aggregates = data?.aggregates ?? { total: 0, withCoords: 0, withoutCoords: 0 };
  const gyms = data?.gyms ?? [];
  const features = data?.features ?? [];

  const showPlaceholderCounts = isInitialLoading || (!data && Boolean(error));
  const countItems = useMemo(
    () => [
      { label: 'Mit Koordinate', value: showPlaceholderCounts ? '–' : aggregates.withCoords.toString() },
      { label: 'Ohne Koordinate', value: showPlaceholderCounts ? '–' : aggregates.withoutCoords.toString() },
      { label: 'Gesamt', value: showPlaceholderCounts ? '–' : aggregates.total.toString() },
    ],
    [aggregates.total, aggregates.withCoords, aggregates.withoutCoords, showPlaceholderCounts]
  );

  useEffect(() => {
    if (!focusedGymId) {
      return;
    }
    if (!gyms.some((gym) => gym.id === focusedGymId)) {
      setFocusedGymId(null);
    }
  }, [gyms, focusedGymId]);

  const handleFocusGym = useCallback(
    (gym: MonitoringGymListItem) => {
      if (!gym.location) {
        return;
      }
      const success = mapRef.current?.flyToGym(gym.id, { zoom: FOCUS_ZOOM }) ?? false;
      if (success) {
        setFocusedGymId(gym.id);
      }
    },
    []
  );

  const handleResetView = useCallback(() => {
    const success = mapRef.current?.fitToInitial() ?? false;
    if (success) {
      setFocusedGymId(null);
    }
  }, []);

  const handleMapReset = useCallback(() => {
    setFocusedGymId(null);
  }, []);

  return (
    <div className="space-y-10">
      <header className="space-y-4">
        <div className="space-y-2">
          <p className="text-sm font-semibold uppercase tracking-wide text-muted">Monitoring</p>
          <h1 className="text-3xl font-semibold text-page">Standorte</h1>
          <p className="max-w-2xl text-sm text-muted">
            Interaktive Übersicht aller Tap&apos;em Studios mit gültigen Koordinaten im DACH-Raum. Nutze Karte und Liste, um
            einzelne Standorte zu prüfen und Details aufzurufen.
          </p>
        </div>
        <dl className="grid gap-3 text-sm sm:grid-cols-3">
          {countItems.map((item) => (
            <div key={item.label} className="rounded-lg border border-subtle bg-card px-4 py-3">
              <dt className="text-xs font-semibold uppercase tracking-wide text-muted">{item.label}</dt>
              <dd className="mt-1 text-base font-semibold text-page">{item.value}</dd>
            </div>
          ))}
        </dl>
      </header>

      <div className="grid gap-8 md:grid-cols-[minmax(0,1.05fr)_minmax(0,0.95fr)]">
        <div className="md:sticky md:top-28">
          <div className="space-y-3">
            <MonitoringMap
              ref={mapRef}
              features={features}
              loading={isInitialLoading}
              className="h-[420px] md:h-[calc(100vh-280px)]"
              onResetView={handleMapReset}
            />
            <div className="flex justify-end">
              <button
                type="button"
                onClick={handleResetView}
                className="rounded-full border border-subtle bg-app px-3 py-1 text-xs font-semibold uppercase tracking-wide text-page shadow-sm transition hover:bg-app/80 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
              >
                Ansicht zurücksetzen
              </button>
            </div>
          </div>
        </div>
        <div className="md:max-h-[calc(100vh-280px)] md:overflow-y-auto md:pr-1">
          <MonitoringGymList
            gyms={gyms}
            loading={loading}
            error={error}
            onRetry={reload}
            onFocusGym={handleFocusGym}
            focusedGymId={focusedGymId}
          />
        </div>
      </div>
    </div>
  );
}
