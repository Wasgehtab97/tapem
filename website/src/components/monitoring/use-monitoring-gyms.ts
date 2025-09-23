'use client';

import { useCallback, useEffect, useRef, useState } from 'react';

import type { MonitoringGymsFeatureCollection } from '@/src/types/monitoring';

const REQUEST_TIMEOUT_MS = 10000;
const FETCH_CACHE_MODE: RequestCache = process.env.NODE_ENV === 'development' ? 'no-store' : 'default';

type MonitoringGymsState = {
  data: MonitoringGymsFeatureCollection | null;
  loading: boolean;
  error: string | null;
  isInitialLoading: boolean;
  reload: () => void;
};

export function useMonitoringGyms(): MonitoringGymsState {
  const [data, setData] = useState<MonitoringGymsFeatureCollection | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const controllerRef = useRef<AbortController | null>(null);

  const load = useCallback(async () => {
    controllerRef.current?.abort();
    const controller = new AbortController();
    controllerRef.current = controller;

    const timeoutId = window.setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    let aborted = false;

    setLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/admin/gyms.geojson', {
        headers: { Accept: 'application/geo+json' },
        credentials: 'include',
        cache: FETCH_CACHE_MODE,
        signal: controller.signal,
      });

      if (response.status === 304) {
        return;
      }

      if (response.status === 401 || response.status === 403) {
        throw new Error('Zugriff verweigert. Bitte melde dich erneut als Admin an.');
      }

      if (!response.ok) {
        throw new Error('Standortdaten konnten nicht geladen werden.');
      }

      const json = (await response.json()) as MonitoringGymsFeatureCollection;
      setData(json);
    } catch (err) {
      if ((err as { name?: string }).name === 'AbortError') {
        aborted = true;
        return;
      }

      console.error('[admin-monitoring] gyms fetch failed', err);
      setError(err instanceof Error ? err.message : 'Unbekannter Fehler beim Laden der Standorte.');
    } finally {
      window.clearTimeout(timeoutId);
      if (controllerRef.current === controller) {
        controllerRef.current = null;
      }
      if (!aborted) {
        setLoading(false);
      }
    }
  }, []);

  useEffect(() => {
    load();
    return () => {
      controllerRef.current?.abort();
    };
  }, [load]);

  return {
    data,
    loading,
    error,
    isInitialLoading: loading && !data,
    reload: load,
  };
}
