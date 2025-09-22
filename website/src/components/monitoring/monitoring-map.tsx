'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';

import { buildAdminMonitoringDetailRoute } from '@/src/lib/routes';

type MapLibreModule = any;
type MapLibreMap = any;
type GeoJSONSource = any;
type Popup = any;

declare global {
  interface Window {
    maplibregl?: MapLibreModule;
  }
}

let mapLibreLoader: Promise<MapLibreModule> | null = null;

function ensureMapLibreStyle() {
  if (typeof document === 'undefined') {
    return;
  }
  if (document.querySelector('link[data-maplibre-style="true"]')) {
    return;
  }
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = 'https://unpkg.com/maplibre-gl@2.4.0/dist/maplibre-gl.css';
  link.setAttribute('data-maplibre-style', 'true');
  document.head.appendChild(link);
}

async function loadMapLibre(): Promise<MapLibreModule> {
  if (typeof window === 'undefined') {
    throw new Error('MapLibre benötigt eine Browser-Umgebung.');
  }
  ensureMapLibreStyle();
  if (window.maplibregl) {
    return window.maplibregl;
  }
  if (!mapLibreLoader) {
    mapLibreLoader = new Promise<MapLibreModule>((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://unpkg.com/maplibre-gl@2.4.0/dist/maplibre-gl.js';
      script.async = true;
      script.onload = () => {
        if (window.maplibregl) {
          resolve(window.maplibregl);
        } else {
          mapLibreLoader = null;
          reject(new Error('MapLibre konnte nicht initialisiert werden.'));
        }
      };
      script.onerror = () => {
        script.remove();
        mapLibreLoader = null;
        reject(new Error('MapLibre-Skript konnte nicht geladen werden.'));
      };
      document.head.appendChild(script);
    });
  }
  return mapLibreLoader;
}

type GymFeatureProperties = {
  id: string;
  name: string;
  slug: string;
  city: string | null;
  state: string | null;
  status: 'online' | 'offline' | 'degraded' | null;
  checkins24h: number | null;
  devicesOnline: number | null;
};

type MapFeature = {
  type: 'Feature';
  geometry: { type: 'Point'; coordinates: [number, number] };
  properties: GymFeatureProperties;
};

type MapResponse = {
  type: 'FeatureCollection';
  features: MapFeature[];
  meta?: {
    total?: number;
    missingLocation?: number;
  };
};

type ThemeMode = 'light' | 'dark';

const STYLE_URLS: Record<ThemeMode, string> = {
  light: 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
  dark: 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json',
};

const STATUS_COLORS: Record<'online' | 'offline' | 'degraded' | 'unknown', string> = {
  online: '#16a34a',
  degraded: '#f97316',
  offline: '#dc2626',
  unknown: '#64748b',
};

const DEFAULT_CENTER: [number, number] = [10.451526, 51.165691];
const DEFAULT_ZOOM = 4.8;

function useResolvedTheme(): ThemeMode {
  const [theme, setTheme] = useState<ThemeMode>('light');

  useEffect(() => {
    if (typeof document === 'undefined') {
      return;
    }
    const root = document.documentElement;
    const readTheme = () => {
      const attr = root.getAttribute('data-theme');
      setTheme(attr === 'dark' ? 'dark' : 'light');
    };
    readTheme();
    const observer = new MutationObserver(readTheme);
    observer.observe(root, { attributes: true, attributeFilter: ['data-theme'] });
    return () => observer.disconnect();
  }, []);

  return theme;
}

function formatStatusLabel(status: GymFeatureProperties['status']): string {
  if (status === 'online') return 'Online';
  if (status === 'degraded') return 'Eingeschränkt';
  if (status === 'offline') return 'Offline';
  return 'Unbekannt';
}

function buildPopupContent(feature: GymFeatureProperties): HTMLDivElement {
  const container = document.createElement('div');
  container.className = 'space-y-2 text-sm text-page';

  const title = document.createElement('h3');
  title.className = 'text-base font-semibold text-page';
  title.textContent = feature.name;
  container.appendChild(title);

  if (feature.city || feature.state) {
    const location = document.createElement('p');
    location.className = 'text-xs text-muted';
    location.textContent = [feature.city, feature.state].filter(Boolean).join(' · ');
    container.appendChild(location);
  }

  const status = document.createElement('p');
  status.className = 'text-xs text-muted';
  const statusLabel = formatStatusLabel(feature.status);
  const statusDetails: string[] = [statusLabel];
  if (typeof feature.devicesOnline === 'number') {
    statusDetails.push(`${feature.devicesOnline} Geräte aktiv`);
  }
  if (typeof feature.checkins24h === 'number') {
    statusDetails.push(`${feature.checkins24h} Check-ins (24h)`);
  }
  status.textContent = statusDetails.join(' · ');
  container.appendChild(status);

  const button = document.createElement('button');
  button.type = 'button';
  button.className =
    'w-full rounded-md border border-primary bg-primary px-3 py-2 text-sm font-semibold text-white transition hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary';
  button.textContent = 'Details ansehen';
  button.setAttribute('data-gym-id', feature.id);
  container.appendChild(button);

  return container;
}

export function MonitoringMap() {
  const router = useRouter();
  const theme = useResolvedTheme();
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<MapLibreMap | null>(null);
  const moduleRef = useRef<MapLibreModule | null>(null);
  const popupRef = useRef<Popup | null>(null);
  const handlersRef = useRef<{
    clusterClick?: (event: any) => void;
    pointClick?: (event: any) => void;
    pointEnter?: (event: any) => void;
    pointLeave?: (event: any) => void;
  }>({});
  const hasFitBoundsRef = useRef(false);

  const [data, setData] = useState<MapResponse | null>(null);
  const [meta, setMeta] = useState<{ total: number; missing: number }>({ total: 0, missing: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const withLocation = data?.features.length ?? 0;
  const withoutLocation = meta.missing;
  const totalGyms = meta.total;

  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch('/api/admin/gyms.geojson', {
        headers: { Accept: 'application/geo+json' },
      });
      if (response.status === 401 || response.status === 403) {
        throw new Error('Zugriff verweigert. Bitte melde dich erneut als Admin an.');
      }
      if (!response.ok) {
        throw new Error('Standortdaten konnten nicht geladen werden.');
      }
      const json = (await response.json()) as MapResponse;
      setData(json);
      hasFitBoundsRef.current = false;
      setMeta({
        total: typeof json.meta?.total === 'number' ? json.meta.total : json.features.length,
        missing: typeof json.meta?.missingLocation === 'number' ? json.meta.missingLocation : 0,
      });
    } catch (err) {
      console.error('[admin-monitoring] map data load failed', err);
      setError(err instanceof Error ? err.message : 'Unbekannter Fehler beim Laden der Karte.');
      setData(null);
      setMeta({ total: 0, missing: 0 });
    } finally {
      setLoading(false);
    }
  }, []);

  const resetPopup = useCallback(() => {
    popupRef.current?.remove();
    popupRef.current = null;
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  useEffect(() => {
    const handler = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        resetPopup();
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [resetPopup]);

  useEffect(() => {
    return () => {
      resetPopup();
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, [resetPopup]);

  const attachInteractions = useCallback(
    (map: MapLibreMap, module: MapLibreModule) => {
      const mapCanvas = map.getCanvas();
      mapCanvas.setAttribute('role', 'application');
      mapCanvas.setAttribute('tabindex', '0');
      mapCanvas.setAttribute('aria-label', 'Monitoring-Karte der Studios');

      if (handlersRef.current?.clusterClick) {
        map.off('click', 'gym-clusters', handlersRef.current.clusterClick);
      }
      if (handlersRef.current?.pointClick) {
        map.off('click', 'gym-points', handlersRef.current.pointClick);
      }
      if (handlersRef.current?.pointEnter) {
        map.off('mouseenter', 'gym-points', handlersRef.current.pointEnter);
      }
      if (handlersRef.current?.pointLeave) {
        map.off('mouseleave', 'gym-points', handlersRef.current.pointLeave);
      }

      const clusterClick = (event: any) => {
        const features = map.queryRenderedFeatures(event.point, { layers: ['gym-clusters'] });
        const cluster = features[0];
        const source = map.getSource('gyms') as GeoJSONSource | undefined;
        if (cluster && source) {
          const clusterId = cluster.properties?.cluster_id as number | undefined;
          if (clusterId !== undefined) {
            source.getClusterExpansionZoom(clusterId, (err, zoom) => {
              if (err) {
                return;
              }
              map.easeTo({ center: (cluster.geometry as any).coordinates, zoom });
            });
          }
        }
      };

      const pointClick = (event: any) => {
        const [feature] = event.features ?? [];
        if (!feature || feature.geometry.type !== 'Point') {
          return;
        }
        const coordinates = feature.geometry.coordinates.slice() as [number, number];
        const properties = feature.properties as GymFeatureProperties;
        const popupContent = buildPopupContent(properties);
        const button = popupContent.querySelector('button[data-gym-id]');
        if (button) {
          button.addEventListener('click', () => {
            resetPopup();
            router.push(buildAdminMonitoringDetailRoute(properties.id));
          });
        }
        resetPopup();
        const popup = new module.Popup({ closeButton: true, closeOnMove: false, offset: 12, focusAfterOpen: false })
          .setDOMContent(popupContent)
          .setLngLat(coordinates)
          .addTo(map);
        popupRef.current = popup;
      };

      const pointEnter = (event: any) => {
        map.getCanvas().style.cursor = 'pointer';
        const [feature] = event.features ?? [];
        if (feature) {
          const props = feature.properties as GymFeatureProperties;
          map.getCanvas().setAttribute(
            'aria-label',
            `Marker: ${props.name}${props.city ? `, ${props.city}` : ''} (${formatStatusLabel(props.status)})`
          );
        }
      };

      const pointLeave = () => {
        map.getCanvas().style.cursor = '';
        map.getCanvas().setAttribute('aria-label', 'Monitoring-Karte der Studios');
      };

      map.on('click', 'gym-clusters', clusterClick);
      map.on('click', 'gym-points', pointClick);
      map.on('mouseenter', 'gym-points', pointEnter);
      map.on('mouseleave', 'gym-points', pointLeave);

      handlersRef.current = { clusterClick, pointClick, pointEnter, pointLeave };
    },
    [resetPopup, router]
  );

  const applyDataToMap = useCallback(
    (map: MapLibreMap, module: MapLibreModule, collection: MapResponse) => {
      if (map.getLayer('gym-clusters')) {
        map.removeLayer('gym-clusters');
      }
      if (map.getLayer('gym-cluster-count')) {
        map.removeLayer('gym-cluster-count');
      }
      if (map.getLayer('gym-points')) {
        map.removeLayer('gym-points');
      }
      if (map.getSource('gyms')) {
        map.removeSource('gyms');
      }

      map.addSource('gyms', {
        type: 'geojson',
        data: collection,
        cluster: true,
        clusterRadius: 60,
        clusterMaxZoom: 12,
      });

      map.addLayer({
        id: 'gym-clusters',
        type: 'circle',
        source: 'gyms',
        filter: ['has', 'point_count'],
        paint: {
          'circle-color': '#2563eb',
          'circle-radius': ['step', ['get', 'point_count'], 16, 10, 22, 25, 30],
          'circle-opacity': 0.8,
        },
      });

      map.addLayer({
        id: 'gym-cluster-count',
        type: 'symbol',
        source: 'gyms',
        filter: ['has', 'point_count'],
        layout: {
          'text-field': ['to-string', ['get', 'point_count']],
          'text-font': ['Open Sans Semibold'],
          'text-size': 12,
        },
        paint: {
          'text-color': '#ffffff',
        },
      });

      map.addLayer({
        id: 'gym-points',
        type: 'circle',
        source: 'gyms',
        filter: ['!', ['has', 'point_count']],
        paint: {
          'circle-color': [
            'match',
            ['get', 'status'],
            'online',
            STATUS_COLORS.online,
            'degraded',
            STATUS_COLORS.degraded,
            'offline',
            STATUS_COLORS.offline,
            STATUS_COLORS.unknown,
          ],
          'circle-radius': 9,
          'circle-stroke-width': 2,
          'circle-stroke-color': theme === 'dark' ? '#0f172a' : '#ffffff',
        },
      });

      attachInteractions(map, module);

      if (!hasFitBoundsRef.current) {
        if (collection.features.length > 0) {
          const bounds = collection.features.reduce(
            (acc, feature) => {
              const [lng, lat] = feature.geometry.coordinates;
              acc[0][0] = Math.min(acc[0][0], lng);
              acc[0][1] = Math.min(acc[0][1], lat);
              acc[1][0] = Math.max(acc[1][0], lng);
              acc[1][1] = Math.max(acc[1][1], lat);
              return acc;
            },
            [
              [collection.features[0].geometry.coordinates[0], collection.features[0].geometry.coordinates[1]],
              [collection.features[0].geometry.coordinates[0], collection.features[0].geometry.coordinates[1]],
            ] as [[number, number], [number, number]]
          );
          map.fitBounds(bounds, { padding: 60, maxZoom: 12, duration: 700 });
        } else {
          map.setCenter(DEFAULT_CENTER);
          map.setZoom(DEFAULT_ZOOM);
        }
        hasFitBoundsRef.current = true;
      }
    },
    [attachInteractions, theme]
  );

  const initializeMap = useCallback(
    async (collection: MapResponse) => {
      if (!mapContainerRef.current) {
        return;
      }
      if (!moduleRef.current) {
        moduleRef.current = await loadMapLibre();
      }
      const module = moduleRef.current;
      if (!module) {
        return;
      }
      if (!mapRef.current) {
        const map = new module.Map({
          container: mapContainerRef.current,
          style: STYLE_URLS[theme],
          center: DEFAULT_CENTER,
          zoom: DEFAULT_ZOOM,
          attributionControl: true,
        });
        mapRef.current = map;
        map.addControl(new module.NavigationControl({ visualizePitch: false, showCompass: false }), 'top-right');
        map.on('load', () => {
          applyDataToMap(map, module, collection);
        });
      } else {
        applyDataToMap(mapRef.current, module, collection);
      }
    },
    [applyDataToMap, theme]
  );

  useEffect(() => {
    if (!data) {
      return;
    }
    initializeMap(data);
  }, [data, initializeMap]);

  useEffect(() => {
    if (!data || !mapRef.current || !moduleRef.current) {
      return;
    }
    const map = mapRef.current;
    const module = moduleRef.current;
    const onStyleData = () => {
      if (map.isStyleLoaded()) {
        applyDataToMap(map, module, data);
      }
    };
    map.once('styledata', onStyleData);
    map.setStyle(STYLE_URLS[theme]);
    return () => {
      map.off('styledata', onStyleData);
    };
  }, [theme, data, applyDataToMap]);

  const infoBoxes = useMemo(() => {
    const boxes = [
      {
        label: 'Mit Koordinate',
        value: loading ? '–' : withLocation.toString(),
      },
      {
        label: 'Ohne Koordinate',
        value: loading ? '–' : withoutLocation.toString(),
      },
      {
        label: 'Gesamt',
        value: loading ? '–' : totalGyms.toString(),
      },
    ];
    return boxes;
  }, [loading, totalGyms, withLocation, withoutLocation]);

  return (
    <section className="space-y-5">
      <div className="flex flex-wrap gap-3">
        {infoBoxes.map((box) => (
          <div key={box.label} className="rounded-lg border border-subtle bg-card px-4 py-3 text-sm">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">{box.label}</p>
            <p className="mt-1 text-base font-semibold text-page">{box.value}</p>
          </div>
        ))}
      </div>

      {error ? (
        <div className="space-y-3 rounded-lg border border-rose-200 bg-rose-50 p-6 text-sm text-rose-900 dark:border-rose-500/50 dark:bg-rose-500/10 dark:text-rose-100">
          <p className="font-semibold">Karte konnte nicht geladen werden.</p>
          <p>{error}</p>
          <button
            type="button"
            onClick={() => loadData()}
            className="rounded-md border border-primary bg-primary px-3 py-2 text-sm font-semibold text-white transition hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
          >
            Erneut versuchen
          </button>
        </div>
      ) : null}

      {!error ? (
        <div className="relative min-h-[480px] overflow-hidden rounded-xl border border-subtle bg-card">
          {loading ? (
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="h-12 w-12 animate-spin rounded-full border-4 border-subtle border-t-primary" aria-label="Lade Karte" />
            </div>
          ) : null}
          {!loading && data && data.features.length === 0 ? (
            <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 text-sm text-muted">
              <p className="font-semibold text-page">Keine Standorte mit Koordinaten</p>
              <p>Bitte trage Geopunkte in Firestore ein, um die Karte zu befüllen.</p>
            </div>
          ) : null}
          <div ref={mapContainerRef} className="h-[520px] w-full" aria-hidden={loading || Boolean(error)} />
        </div>
      ) : null}
    </section>
  );
}
