'use client';

import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from 'react';
import { useRouter } from 'next/navigation';

import { buildAdminMonitoringDetailRoute } from '@/src/lib/routes';
import type { MonitoringGymFeature, MonitoringGymFeatureProperties } from '@/src/types/monitoring';

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

function resolveEnvNumber(value: string | undefined, fallback: number): number {
  if (!value) {
    return fallback;
  }
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

type ThemeMode = 'light' | 'dark';

const DEFAULT_STYLE_LIGHT = 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';
const DEFAULT_STYLE_DARK = 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';
const ENV_STYLE_LIGHT = (process.env.NEXT_PUBLIC_MAP_STYLE_URL ?? '').trim();
const ENV_STYLE_DARK = (process.env.NEXT_PUBLIC_MAP_STYLE_URL_DARK ?? '').trim();

const STYLE_URLS: Record<ThemeMode, string> = {
  light: ENV_STYLE_LIGHT || DEFAULT_STYLE_LIGHT,
  dark: ENV_STYLE_DARK || ENV_STYLE_LIGHT || DEFAULT_STYLE_DARK,
};

const POINT_COLORS: Record<ThemeMode, string> = {
  light: '#2563eb',
  dark: '#38bdf8',
};

const POINT_STROKE_COLORS: Record<ThemeMode, string> = {
  light: '#ffffff',
  dark: '#0f172a',
};

const DEFAULT_CENTER: [number, number] = [10.447683, 51.163375];
const DEFAULT_ZOOM = 4.8;
const INITIAL_BOUNDS: [[number, number], [number, number]] = [
  [5.8663153, 45.817995],
  [15.0419319, 55.058347],
];

const CLUSTER_RADIUS = resolveEnvNumber(process.env.NEXT_PUBLIC_MAP_CLUSTER_RADIUS, 24);
const CLUSTER_MAX_ZOOM = resolveEnvNumber(process.env.NEXT_PUBLIC_MAP_CLUSTER_MAX_ZOOM, 7);

const POPUP_DATE_FORMATTER = new Intl.DateTimeFormat('de-DE', {
  dateStyle: 'medium',
  timeStyle: 'short',
});

function useResolvedTheme(): ThemeMode {
  const themeRef = useRef<ThemeMode>('light');
  const [, forceUpdate] = useState(0);

  useEffect(() => {
    if (typeof document === 'undefined') {
      return;
    }
    const root = document.documentElement;
    const readTheme = () => {
      const attr = root.getAttribute('data-theme');
      const next = attr === 'dark' ? 'dark' : 'light';
      if (themeRef.current !== next) {
        themeRef.current = next;
        forceUpdate((value) => value + 1);
      }
    };
    readTheme();
    const observer = new MutationObserver(readTheme);
    observer.observe(root, { attributes: true, attributeFilter: ['data-theme'] });
    return () => observer.disconnect();
  }, []);

  return themeRef.current;
}

function buildPopupContent(feature: MonitoringGymFeatureProperties): HTMLDivElement {
  const container = document.createElement('div');
  container.className = 'space-y-2 text-sm text-page';

  const title = document.createElement('h3');
  title.className = 'text-base font-semibold text-page';
  title.textContent = feature.name;
  container.appendChild(title);

  const metaLine = document.createElement('p');
  metaLine.className = 'text-xs text-muted';
  const metaParts: string[] = [`Slug: ${feature.slug}`];
  if (feature.code) {
    metaParts.push(`Code: ${feature.code}`);
  }
  metaLine.textContent = metaParts.join(' · ');
  container.appendChild(metaLine);

  const countryLine = document.createElement('p');
  countryLine.className = 'text-xs text-muted';
  countryLine.textContent = `Land: ${feature.countryCode}`;
  container.appendChild(countryLine);

  const activeLine = document.createElement('p');
  activeLine.className = 'text-xs text-muted';
  activeLine.textContent = feature.active ? 'Status: aktiv' : 'Status: inaktiv';
  container.appendChild(activeLine);

  if (feature.statusUpdatedAt) {
    const parsed = new Date(feature.statusUpdatedAt);
    if (!Number.isNaN(parsed.valueOf())) {
      const updatedLine = document.createElement('p');
      updatedLine.className = 'text-xs text-muted';
      updatedLine.textContent = `Letzte Aktualisierung: ${POPUP_DATE_FORMATTER.format(parsed)}`;
      container.appendChild(updatedLine);
    }
  }

  const button = document.createElement('button');
  button.type = 'button';
  button.className =
    'w-full rounded-md border border-primary bg-primary px-3 py-2 text-sm font-semibold text-white transition hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary';
  button.textContent = 'Details ansehen →';
  button.setAttribute('data-gym-id', String(feature.id));
  container.appendChild(button);

  return container;
}

export type MonitoringMapHandle = {
  flyToGym: (gymId: string, options?: { zoom?: number }) => boolean;
  fitToInitial: () => boolean;
};

type MonitoringMapProps = {
  features: MonitoringGymFeature[];
  loading: boolean;
  className?: string;
  onResetView?: () => void;
};

export const MonitoringMap = forwardRef<MonitoringMapHandle, MonitoringMapProps>(function MonitoringMap(
  { features, loading, className, onResetView },
  ref
) {
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
  const featureLookupRef = useRef<Map<string, [number, number]>>(new Map());
  const pendingCollectionRef = useRef({ type: 'FeatureCollection', features: [] as MonitoringGymFeature[] });

  const featureCollection = useMemo(
    () => ({ type: 'FeatureCollection', features }),
    [features]
  );

  useEffect(() => {
    featureLookupRef.current = new Map(
      features.map((feature) => [feature.properties.id, feature.geometry.coordinates as [number, number]])
    );
  }, [features]);

  const resetPopup = useCallback(() => {
    popupRef.current?.remove();
    popupRef.current = null;
  }, []);

  const fitBounds = useCallback(
    (map?: MapLibreMap, options?: { animate?: boolean }) => {
      const target = map ?? mapRef.current;
      if (!target) {
        return false;
      }
      target.fitBounds(INITIAL_BOUNDS, {
        padding: 72,
        maxZoom: 8,
        duration: options?.animate === false ? 0 : 700,
      });
      return true;
    },
    []
  );

  useImperativeHandle(
    ref,
    () => ({
      flyToGym: (gymId, options) => {
        const map = mapRef.current;
        if (!map) {
          return false;
        }
        const coordinates = featureLookupRef.current.get(gymId);
        if (!coordinates) {
          return false;
        }
        map.flyTo({
          center: coordinates,
          zoom: options?.zoom ?? 13,
          essential: true,
          duration: 700,
        });
        return true;
      },
      fitToInitial: () => fitBounds(),
    }),
    [fitBounds]
  );

  const attachInteractions = useCallback(
    (map: MapLibreMap, maplibre: MapLibreModule) => {
      const mapCanvas = map.getCanvas();
      mapCanvas.setAttribute('role', 'application');
      mapCanvas.setAttribute('tabindex', '0');
      mapCanvas.setAttribute('aria-label', 'Monitoring-Karte der Studios');

      if (handlersRef.current.clusterClick) {
        map.off('click', 'gym-clusters', handlersRef.current.clusterClick);
      }
      if (handlersRef.current.pointClick) {
        map.off('click', 'gym-points', handlersRef.current.pointClick);
      }
      if (handlersRef.current.pointEnter) {
        map.off('mouseenter', 'gym-points', handlersRef.current.pointEnter);
      }
      if (handlersRef.current.pointLeave) {
        map.off('mouseleave', 'gym-points', handlersRef.current.pointLeave);
      }

      const clusterClick = (event: any) => {
        const featuresAtPoint = map.queryRenderedFeatures(event.point, { layers: ['gym-clusters'] });
        const cluster = featuresAtPoint[0];
        const source = map.getSource('gyms') as GeoJSONSource | undefined;
        if (!cluster || !source) {
          return;
        }
        const clusterId = cluster.properties?.cluster_id as number | undefined;
        if (clusterId === undefined) {
          return;
        }
        source.getClusterExpansionZoom(clusterId, (error: unknown, zoom: number) => {
          if (error) {
            return;
          }
          map.easeTo({ center: (cluster.geometry as any).coordinates, zoom });
        });
      };

      const pointClick = (event: any) => {
        const [feature] = event.features ?? [];
        if (!feature || feature.geometry.type !== 'Point') {
          return;
        }
        const coordinates = feature.geometry.coordinates.slice() as [number, number];
        const properties = feature.properties as MonitoringGymFeatureProperties;
        const popupContent = buildPopupContent(properties);
        const button = popupContent.querySelector('button[data-gym-id]');
        if (button) {
          const gymId = String(properties.id);
          button.addEventListener('click', () => {
            resetPopup();
            router.push(buildAdminMonitoringDetailRoute(gymId));
          });
        }
        resetPopup();
        const popup = new maplibre.Popup({ closeButton: true, closeOnMove: false, offset: 12, focusAfterOpen: false })
          .setDOMContent(popupContent)
          .setLngLat(coordinates)
          .addTo(map);
        popupRef.current = popup;
      };

      const pointEnter = (event: any) => {
        map.getCanvas().style.cursor = 'pointer';
        const [feature] = event.features ?? [];
        if (feature) {
          const props = feature.properties as MonitoringGymFeatureProperties;
          const parts = [props.name];
          if (props.code) {
            parts.push(`Code ${props.code}`);
          }
          map.getCanvas().setAttribute('aria-label', `Marker: ${parts.join(' · ')}`);
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
    (map: MapLibreMap, maplibre: MapLibreModule, collection: { type: 'FeatureCollection'; features: MonitoringGymFeature[] }) => {
      const existingSource = map.getSource('gyms') as GeoJSONSource | undefined;
      if (!existingSource) {
        map.addSource('gyms', {
          type: 'geojson',
          data: collection,
          cluster: true,
          clusterRadius: CLUSTER_RADIUS,
          clusterMaxZoom: CLUSTER_MAX_ZOOM,
        });

        map.addLayer({
          id: 'gym-clusters',
          type: 'circle',
          source: 'gyms',
          filter: ['has', 'point_count'],
          paint: {
            'circle-color': '#2563eb',
            'circle-radius': ['step', ['get', 'point_count'], 18, 10, 24, 25, 30],
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
            'circle-color': POINT_COLORS[theme],
            'circle-radius': 9,
            'circle-stroke-width': 2,
            'circle-stroke-color': POINT_STROKE_COLORS[theme],
            'circle-opacity': 0.85,
          },
        });
      } else {
        existingSource.setData(collection);
      }

      if (map.getLayer('gym-points')) {
        map.setPaintProperty('gym-points', 'circle-color', POINT_COLORS[theme]);
        map.setPaintProperty('gym-points', 'circle-stroke-color', POINT_STROKE_COLORS[theme]);
      }

      attachInteractions(map, maplibre);
    },
    [attachInteractions, theme]
  );

  useEffect(() => {
    pendingCollectionRef.current = featureCollection;
    const map = mapRef.current;
    const maplibre = moduleRef.current;
    if (!map || !maplibre) {
      return;
    }
    if (!map.isStyleLoaded()) {
      return;
    }
    applyDataToMap(map, maplibre, featureCollection);
  }, [applyDataToMap, featureCollection]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      if (!mapContainerRef.current) {
        return;
      }
      try {
        if (!moduleRef.current) {
          moduleRef.current = await loadMapLibre();
        }
      } catch (error) {
        console.error('[admin-monitoring] map initialisation failed', error);
        return;
      }
      if (cancelled) {
        return;
      }
      const maplibre = moduleRef.current;
      if (!maplibre) {
        return;
      }
      if (!mapRef.current) {
        const map = new maplibre.Map({
          container: mapContainerRef.current,
          style: STYLE_URLS.light,
          center: DEFAULT_CENTER,
          zoom: DEFAULT_ZOOM,
          attributionControl: true,
        });
        mapRef.current = map;
        map.addControl(new maplibre.NavigationControl({ visualizePitch: false, showCompass: false }), 'top-right');
        map.on('load', () => {
          applyDataToMap(map, maplibre, pendingCollectionRef.current);
          fitBounds(map, { animate: false });
        });
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [applyDataToMap, fitBounds]);

  useEffect(() => {
    if (!mapRef.current || !moduleRef.current) {
      return;
    }
    const map = mapRef.current;
    const maplibre = moduleRef.current;
    const handleStyle = () => {
      applyDataToMap(map, maplibre, pendingCollectionRef.current);
    };
    map.once('styledata', handleStyle);
    map.setStyle(STYLE_URLS[theme]);
    return () => {
      map.off('styledata', handleStyle);
    };
  }, [applyDataToMap, theme]);

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

  const handleResetView = useCallback(() => {
    const success = fitBounds();
    if (success) {
      onResetView?.();
    }
  }, [fitBounds, onResetView]);

  return (
    <div className={`relative overflow-hidden rounded-xl border border-subtle bg-card ${className ?? ''}`}>
      <div className="pointer-events-none absolute left-4 top-4 z-10 flex gap-2">
        <button
          type="button"
          onClick={handleResetView}
          className="pointer-events-auto rounded-full border border-subtle bg-app/80 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-page shadow-sm transition hover:bg-app focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
        >
          DACH
        </button>
      </div>

      {loading ? (
        <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
          <div className="h-12 w-12 animate-spin rounded-full border-4 border-subtle border-t-primary" aria-label="Lade Karte" />
        </div>
      ) : null}

      {!loading && features.length === 0 ? (
        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center gap-2 text-sm text-muted">
          <p className="text-base font-semibold text-page">Keine Standorte mit Koordinaten</p>
          <p>Aktiviere Koordinaten in Firestore, um Marker auf der Karte zu sehen.</p>
        </div>
      ) : null}

      <div ref={mapContainerRef} className="h-full w-full" aria-hidden={loading} />
    </div>
  );
});
