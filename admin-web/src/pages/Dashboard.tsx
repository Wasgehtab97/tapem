import { useEffect, useState } from 'react';
import { GeoPoint, collection, doc, getDoc, getDocs, limit, query, where, writeBatch } from 'firebase/firestore';
import { db } from '../firebase';
import { useActiveGym } from '../hooks/useActiveGym';
import { Card } from '../components/Card';
import { Link } from 'react-router-dom';
import { germanyBounds, germanyOutline } from '../data/germanyOutline';
import { defaultMuscleGroups } from '../data/defaultMuscleGroups';

interface GymSummary {
  id: string;
  name?: string;
  region?: string;
  countryCode?: string;
  lat?: number;
  lng?: number;
  location?: { lat?: number; lng?: number; latitude?: number; longitude?: number };
  geo?: { lat?: number; lng?: number; latitude?: number; longitude?: number };
  coords?: { lat?: number; lng?: number };
}

export function Dashboard() {
  const { activeGym, setActiveGym } = useActiveGym();
  const [gyms, setGyms] = useState<GymSummary[]>([]);
  const [mapGyms, setMapGyms] = useState<GymSummary[]>([]);
  const [selectedGroup, setSelectedGroup] = useState<GymSummary[] | null>(null);
  const [createFields, setCreateFields] = useState({
    id: '',
    name: '',
    region: '',
    countryCode: 'DE',
    status: 'active',
    active: true,
    lat: '',
    lng: '',
    initialCode: '',
    logoUrl: '',
    primaryColor: '',
    accentColor: '',
    seedMuscleGroups: true,
    selectAfterCreate: true,
  });
  const [creatingGym, setCreatingGym] = useState(false);
  const [createGymError, setCreateGymError] = useState<string | null>(null);
  const [createGymSuccess, setCreateGymSuccess] = useState<string | null>(null);
  const [slugTouched, setSlugTouched] = useState(false);
  const [userCount, setUserCount] = useState<number | null>(null);
  const [deviceCount, setDeviceCount] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function loadMap() {
      try {
        const snap = await getDocs(query(collection(db, 'gyms'), limit(200)));
        const items: GymSummary[] = snap.docs.map((doc) => ({
          id: doc.id,
          ...(doc.data() as any),
        }));
        setMapGyms(items);
      } catch (err) {
        console.warn('Gym map load failed', err);
      }
    }
    loadMap();
  }, []);

  useEffect(() => {
    async function load() {
      try {
        if (activeGym?.id) {
          const snap = await getDoc(doc(db, 'gyms', activeGym.id));
          if (snap.exists()) {
            setGyms([{ id: snap.id, ...(snap.data() as any) }]);
          } else {
            setGyms([]);
          }
          // Count devices (simple, capped to 500 fetch)
          const devSnap = await getDocs(query(collection(db, 'gyms', activeGym.id, 'devices'), limit(500)));
          setDeviceCount(devSnap.size);
          // Count users in gym (simple, capped to 500 fetch)
          const userSnap = await getDocs(
            query(collection(db, 'users'), where('gymCodes', 'array-contains', activeGym.id), limit(500))
          );
          setUserCount(userSnap.size);
        } else {
          const q = query(collection(db, 'gyms'), limit(10));
          const snap = await getDocs(q);
          const items: GymSummary[] = snap.docs.map((doc) => ({
            id: doc.id,
            ...(doc.data() as any),
          }));
          setGyms(items);
          setDeviceCount(null);
          setUserCount(null);
        }
      } catch (err: any) {
        setError(err?.message || 'Konnte Gyms nicht laden');
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [activeGym?.id]);

  const fallbackCoords: Record<string, { lat: number; lng: number }> = {
    lifthouse_koblenz: { lat: 50.3569, lng: 7.5889 },
    stahlwerk_koblenz: { lat: 50.3569, lng: 7.5889 },
    bodypower_weissenthurm: { lat: 50.4158, lng: 7.4613 },
    evoland_koeln: { lat: 50.9375, lng: 6.9603 },
    club_aktiv: { lat: 47.6779, lng: 9.1732 },
    gym_frankfurt: { lat: 50.1109, lng: 8.6821 },
    gym_frnakfurt: { lat: 50.1109, lng: 8.6821 },
    unigym_essen: { lat: 51.4556, lng: 7.0116 },
    medifitness_ruesselsheim: { lat: 49.9896, lng: 8.4225 },
    mcfitt_baelau: { lat: 53.5636, lng: 9.9658 },
    fitseveneleven_schwalbach: { lat: 50.1503, lng: 8.5444 },
    fitseveneleven_schwalbachamtaunus: { lat: 50.1503, lng: 8.5444 },
    fitseveneleven_schwalbach_am_taunus: { lat: 50.1503, lng: 8.5444 },
    fitnessfirst_myzeil: { lat: 50.1144, lng: 8.6836 },
    studentgym_london: { lat: 51.5072, lng: -0.1276 },
  };
  const fallbackByName: Array<{ match: string; coords: { lat: number; lng: number } }> = [
    { match: 'schwalbach', coords: { lat: 50.1503, lng: 8.5444 } },
  ];

  function extractCoords(gym: GymSummary) {
    const direct = (v?: number) => (typeof v === 'number' && Number.isFinite(v) ? v : null);
    const fromGeoLike = (value: any) => {
      const lat = direct(value?.lat ?? value?.latitude ?? value?._lat);
      const lng = direct(value?.lng ?? value?.longitude ?? value?._long);
      return lat && lng ? { lat, lng } : null;
    };
    const fromArray = (value: any) => {
      if (!Array.isArray(value) || value.length < 2) return null;
      const first = direct(value[0]);
      const second = direct(value[1]);
      if (!first || !second) return null;
      const inBounds = (lat: number, lng: number) =>
        lat >= MAP_BOUNDS.minLat &&
        lat <= MAP_BOUNDS.maxLat &&
        lng >= MAP_BOUNDS.minLng &&
        lng <= MAP_BOUNDS.maxLng;
      if (inBounds(first, second)) return { lat: first, lng: second };
      if (inBounds(second, first)) return { lat: second, lng: first };
      return { lat: first, lng: second };
    };
    const fromString = (value: any) => {
      if (typeof value !== 'string') return null;
      const cleaned = value.replace(/[()]/g, '').trim();
      const directional = /([0-9]+(?:\\.[0-9]+)?)\\s*°?\\s*([NS])[,\\s]+([0-9]+(?:\\.[0-9]+)?)\\s*°?\\s*([EW])/i;
      const match = cleaned.match(directional);
      if (match) {
        const lat = direct(Number(match[1]));
        const lng = direct(Number(match[3]));
        if (!lat || !lng) return null;
        const latSign = match[2].toUpperCase() === 'S' ? -1 : 1;
        const lngSign = match[4].toUpperCase() === 'W' ? -1 : 1;
        return { lat: lat * latSign, lng: lng * lngSign };
      }
      const parts = cleaned.split(/[\\s,]+/).filter(Boolean);
      if (parts.length >= 2) {
        const first = direct(Number(parts[0]));
        const second = direct(Number(parts[1]));
        if (first && second) return { lat: first, lng: second };
      }
      return null;
    };
    const lat =
      direct(gym.lat) ||
      direct(gym.location?.lat) ||
      direct(gym.location?.latitude) ||
      direct(gym.geo?.lat) ||
      direct(gym.geo?.latitude) ||
      direct(gym.coords?.lat) ||
      direct((gym as any)?.location?.latitude) ||
      direct((gym as any)?.location?.lat) ||
      direct((gym as any)?.geoPoint?.latitude);
    const lng =
      direct(gym.lng) ||
      direct(gym.location?.lng) ||
      direct(gym.location?.longitude) ||
      direct(gym.geo?.lng) ||
      direct(gym.geo?.longitude) ||
      direct(gym.coords?.lng) ||
      direct((gym as any)?.location?.longitude) ||
      direct((gym as any)?.location?.lng) ||
      direct((gym as any)?.geoPoint?.longitude);
    if (lat && lng) return { lat, lng };
    const geoLike = fromGeoLike((gym as any)?.location) || fromGeoLike((gym as any)?.geo) || fromGeoLike((gym as any)?.geoPoint);
    if (geoLike) return geoLike;
    const arrayLike =
      fromArray((gym as any)?.location) ||
      fromArray((gym as any)?.coords) ||
      fromArray((gym as any)?.geo) ||
      fromArray((gym as any)?.geoPoint);
    if (arrayLike) return arrayLike;
    const stringLike = fromString((gym as any)?.location) || fromString((gym as any)?.coords);
    if (stringLike) return stringLike;
    const fallback = fallbackCoords[gym.id];
    if (fallback) return { ...fallback };
    const name = (gym.name || '').toLowerCase().replace(/[^a-z0-9]+/g, '');
    const named = fallbackByName.find((item) => name.includes(item.match));
    return named ? { ...named.coords } : undefined;
  }

  const MAP_BOUNDS = {
    ...germanyBounds,
    width: 980,
    height: 1120,
    padding: 36,
  };

  function project(lat: number, lng: number) {
    const x =
      MAP_BOUNDS.padding +
      ((lng - MAP_BOUNDS.minLng) / (MAP_BOUNDS.maxLng - MAP_BOUNDS.minLng)) *
        (MAP_BOUNDS.width - MAP_BOUNDS.padding * 2);
    const y =
      MAP_BOUNDS.padding +
      (1 - (lat - MAP_BOUNDS.minLat) / (MAP_BOUNDS.maxLat - MAP_BOUNDS.minLat)) *
        (MAP_BOUNDS.height - MAP_BOUNDS.padding * 2);
    return { x, y };
  }

  type LngLat = readonly [number, number];
  type Ring = readonly LngLat[];
  type MultiRing = readonly Ring[];

  function pathFor(coords: Ring) {
    const points = coords.map(([lng, lat]) => project(lat, lng));
    const d = points
      .map((p, idx) => `${idx === 0 ? 'M' : 'L'} ${p.x.toFixed(1)} ${p.y.toFixed(1)}`)
      .join(' ');
    return `${d} Z`;
  }

  function pathForMulti(polys: MultiRing) {
    return polys.map((poly) => pathFor(poly)).join(' ');
  }

  function slugify(value: string) {
    return value
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '');
  }

  function generateGymCode() {
    const chars = 'ABCDEFGHJKLMNPQRTUVWXY3468';
    let code = '';
    for (let i = 0; i < 6; i++) code += chars.charAt(Math.floor(Math.random() * chars.length));
    return code;
  }

  async function createGym() {
    if (creatingGym) return;
    setCreateGymError(null);
    setCreateGymSuccess(null);
    const name = createFields.name.trim();
    const id = (createFields.id.trim() || slugify(name)).toLowerCase();
    if (!name) {
      setCreateGymError('Bitte einen Gym-Namen angeben.');
      return;
    }
    if (!id) {
      setCreateGymError('Bitte eine Gym-ID angeben.');
      return;
    }
    const latRaw = createFields.lat.trim();
    const lngRaw = createFields.lng.trim();
    const hasLat = latRaw.length > 0;
    const hasLng = lngRaw.length > 0;
    if (hasLat !== hasLng) {
      setCreateGymError('Bitte Latitude und Longitude gemeinsam angeben.');
      return;
    }
    const lat = hasLat ? Number(latRaw) : null;
    const lng = hasLng ? Number(lngRaw) : null;
    if (hasLat && (!Number.isFinite(lat) || !Number.isFinite(lng))) {
      setCreateGymError('Latitude/Longitude sind nicht gültig.');
      return;
    }
    const code = (createFields.initialCode.trim() || generateGymCode()).toUpperCase();
    if (code.length !== 6) {
      setCreateGymError('Der Gym-Code muss 6 Zeichen haben.');
      return;
    }
    setCreatingGym(true);
    try {
      const gymRef = doc(db, 'gyms', id);
      const existing = await getDoc(gymRef);
      if (existing.exists()) {
        setCreateGymError(`Gym-ID "${id}" existiert bereits.`);
        return;
      }
      const now = new Date();
      const expires = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 30);
      const payload: Record<string, any> = {
        name,
        slug: id,
        active: createFields.active,
        status: createFields.status.trim() || 'active',
        countryCode: createFields.countryCode.trim() || 'DE',
        memberNumberCounter: 0,
        code,
        createdAt: now,
        createdBy: 'admin-web',
      };
      const region = createFields.region.trim();
      if (region) payload.region = region;
      const logoUrl = createFields.logoUrl.trim();
      if (logoUrl) payload.logoUrl = logoUrl;
      const primaryColor = createFields.primaryColor.trim();
      if (primaryColor) payload.primaryColor = primaryColor;
      const accentColor = createFields.accentColor.trim();
      if (accentColor) payload.accentColor = accentColor;
      if (lat !== null && lng !== null) {
        payload.location = new GeoPoint(lat, lng);
      }

      const batch = writeBatch(db);
      batch.set(gymRef, payload);
      batch.set(doc(db, 'gym_codes', id, 'codes', code), {
        code,
        gymId: id,
        createdAt: now,
        expiresAt: expires,
        isActive: true,
        createdBy: 'admin-web',
      });
      if (createFields.seedMuscleGroups) {
        defaultMuscleGroups.forEach((group) => {
          batch.set(doc(db, 'gyms', id, 'muscleGroups', group.id), {
            name: group.name,
            region: group.region,
            majorCategory: group.majorCategory,
          });
        });
      }
      await batch.commit();

      setGyms((prev) => [{ id, ...payload }, ...prev]);
      setMapGyms((prev) => [{ id, ...payload }, ...prev]);
      window.dispatchEvent(new CustomEvent('gym-created', { detail: { id, name } }));
      if (createFields.selectAfterCreate) {
        setActiveGym({ id, name });
      }
      setCreateFields((prev) => ({
        ...prev,
        id: '',
        name: '',
        region: '',
        lat: '',
        lng: '',
        initialCode: '',
        logoUrl: '',
        primaryColor: '',
        accentColor: '',
      }));
      setSlugTouched(false);
      setCreateGymSuccess(`Gym "${name}" wurde angelegt. Code: ${code}`);
    } catch (err: any) {
      setCreateGymError(err?.message || 'Gym konnte nicht angelegt werden.');
    } finally {
      setCreatingGym(false);
    }
  }

  const mappedGyms = mapGyms.map((g) => {
    const coords = extractCoords(g);
    return { ...g, coords };
  });
  function hasCoords(gym: GymSummary): gym is GymSummary & { coords: { lat: number; lng: number } } {
    return (
      !!gym.coords &&
      typeof gym.coords.lat === 'number' &&
      Number.isFinite(gym.coords.lat) &&
      typeof gym.coords.lng === 'number' &&
      Number.isFinite(gym.coords.lng)
    );
  }

  type MappedGym = GymSummary & { coords: { lat: number; lng: number } };
  type GymCluster = { gyms: MappedGym[]; center: { lat: number; lng: number } };

  const mappedInBounds: MappedGym[] = mappedGyms
    .filter(hasCoords)
    .filter(
      (g) =>
        g.coords.lat >= MAP_BOUNDS.minLat &&
        g.coords.lat <= MAP_BOUNDS.maxLat &&
        g.coords.lng >= MAP_BOUNDS.minLng &&
        g.coords.lng <= MAP_BOUNDS.maxLng
    );
  const mappedMissing = mappedGyms.filter((g) => !g.coords);
  const CLUSTER_RADIUS_KM = 12;
  const degToRad = (deg: number) => (deg * Math.PI) / 180;
  const distanceKm = (a: { lat: number; lng: number }, b: { lat: number; lng: number }) => {
    const dLat = degToRad(b.lat - a.lat);
    const dLng = degToRad(b.lng - a.lng);
    const lat1 = degToRad(a.lat);
    const lat2 = degToRad(b.lat);
    const h =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
    return 2 * 6371 * Math.asin(Math.sqrt(h));
  };
  const clusters = mappedInBounds.reduce<GymCluster[]>((acc, gym) => {
    const match = acc.find((cluster) => distanceKm(cluster.center, gym.coords) <= CLUSTER_RADIUS_KM);
    if (!match) {
      acc.push({ gyms: [gym], center: { ...gym.coords } });
      return acc;
    }
    match.gyms.push(gym);
    const count = match.gyms.length;
    match.center.lat = (match.center.lat * (count - 1) + gym.coords.lat) / count;
    match.center.lng = (match.center.lng * (count - 1) + gym.coords.lng) / count;
    return acc;
  }, []);

  function selectGym(gym: GymSummary) {
    setActiveGym({ id: gym.id, name: gym.name || null });
  }

  return (
    <div className="page">
      <h1>Dashboard</h1>
      {activeGym?.id && <p className="muted">Aktives Gym: {activeGym.name || activeGym.id}</p>}
      {loading && <p className="muted">Lade…</p>}
      {error && <p className="error">{error}</p>}
      {!loading && !error && (
        <>
          <Card title="Gym-Map (Deutschland)">
            <div className="map-shell">
              <div className="map-panel">
                <svg
                  className="map-svg"
                  viewBox={`0 0 ${MAP_BOUNDS.width} ${MAP_BOUNDS.height}`}
                  role="img"
                  aria-label="Deutschland Gym Map"
                >
                  <defs>
                    <linearGradient id="mapGlow" x1="0" y1="0" x2="1" y2="1">
                      <stop offset="0%" stopColor="rgba(45, 212, 191, 0.25)" />
                      <stop offset="100%" stopColor="rgba(245, 165, 36, 0.18)" />
                    </linearGradient>
                  </defs>
                  <rect width="100%" height="100%" fill="url(#mapGlow)" opacity="0.7" />
                  <path className="map-country map-country-de" d={pathForMulti(germanyOutline)} />
                  <text className="map-label" x={project(52.52, 13.405).x} y={project(52.52, 13.405).y}>
                    DE
                  </text>
                  {clusters.map((cluster) => {
                    const first = cluster.gyms[0];
                    const point = project(cluster.center.lat, cluster.center.lng);
                    const isActive = cluster.gyms.some((g) => activeGym?.id === g.id);
                    const label = cluster.gyms.length > 1 ? `${cluster.gyms.length} Gyms` : first.name || first.id;
                    const openGroup = () => {
                      setSelectedGroup(cluster.gyms);
                      if (cluster.gyms.length === 1) selectGym(first);
                    };
                    return (
                      <g
                        key={`${first.id}-${cluster.gyms.length}`}
                        className={`map-marker ${isActive ? 'active' : ''}`}
                        onClick={openGroup}
                        role="button"
                        tabIndex={0}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter' || e.key === ' ') openGroup();
                        }}
                      >
                        <circle cx={point.x} cy={point.y} r={10} />
                        <circle cx={point.x} cy={point.y} r={22} className="map-marker-ring" />
                        <title>{label}</title>
                      </g>
                    );
                  })}
                </svg>
              </div>
              <div className="map-meta">
                <div>
                  <div className="map-title">Gyms im Netzwerk</div>
                  <div className="map-count">{mappedInBounds.length} markiert</div>
                </div>
                {mappedMissing.length > 0 && (
                  <div className="map-missing">
                    <div className="map-missing-title">Ohne Koordinaten</div>
                    <div className="map-missing-list">
                      {mappedMissing.map((g) => (
                        <button key={g.id} className="ghost btn-small" onClick={() => selectGym(g)}>
                          {g.name || g.id}
                        </button>
                      ))}
                    </div>
                  </div>
                )}
                {selectedGroup && (
                  <div className="map-missing">
                    <div className="map-missing-title">Gyms an diesem Ort</div>
                    <div className="map-missing-list">
                      {selectedGroup.map((g) => (
                        <button key={g.id} className="ghost btn-small" onClick={() => selectGym(g)}>
                          {g.name || g.id}
                        </button>
                      ))}
                    </div>
                  </div>
                )}
                <div className="map-legend">
                  <span className="map-legend-dot" />
                  Aktiv ausgewähltes Gym
                </div>
              </div>
            </div>
          </Card>
          <Card title="Gyms (Firestore)">
            <ul>
              {gyms.map((g) => (
                <li key={g.id}>
                  {g.name || g.id} {g.region ? `– ${g.region}` : ''}
                </li>
              ))}
            </ul>
          </Card>
          <Card title="Neues Gym anlegen">
            <div className="form">
              <div className="device-grid">
                <label>
                  Name
                  <input
                    className="input"
                    placeholder="z.B. Fitseveneleven Schwalbach"
                    value={createFields.name}
                    onChange={(e) => {
                      const name = e.target.value;
                      setCreateFields((prev) => ({
                        ...prev,
                        name,
                        id: slugTouched ? prev.id : slugify(name),
                      }));
                    }}
                  />
                </label>
                <label>
                  Gym-ID (slug)
                  <div style={{ display: 'flex', gap: '0.5rem' }}>
                    <input
                      className="input"
                      placeholder="fitseveneleven_schwalbach"
                      value={createFields.id}
                      onChange={(e) => {
                        setSlugTouched(true);
                        setCreateFields((prev) => ({ ...prev, id: e.target.value }));
                      }}
                    />
                    <button
                      type="button"
                      className="ghost btn-small"
                      onClick={() => {
                        setSlugTouched(false);
                        setCreateFields((prev) => ({ ...prev, id: slugify(prev.name) }));
                      }}
                    >
                      Auto
                    </button>
                  </div>
                </label>
                <label>
                  Region
                  <input
                    className="input"
                    placeholder="z.B. Rheinland-Pfalz"
                    value={createFields.region}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, region: e.target.value }))}
                  />
                </label>
                <label>
                  Country Code
                  <input
                    className="input"
                    placeholder="DE"
                    value={createFields.countryCode}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, countryCode: e.target.value }))}
                  />
                </label>
                <label>
                  Latitude
                  <input
                    className="input"
                    placeholder="50.1503"
                    value={createFields.lat}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, lat: e.target.value }))}
                  />
                </label>
                <label>
                  Longitude
                  <input
                    className="input"
                    placeholder="8.5444"
                    value={createFields.lng}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, lng: e.target.value }))}
                  />
                </label>
                <label>
                  Status
                  <input
                    className="input"
                    placeholder="active"
                    value={createFields.status}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, status: e.target.value }))}
                  />
                </label>
                <label className="inline-check">
                  <input
                    type="checkbox"
                    checked={createFields.active}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, active: e.target.checked }))}
                  />
                  aktiv
                </label>
                <label>
                  Initialer Gym-Code
                  <div style={{ display: 'flex', gap: '0.5rem' }}>
                    <input
                      className="input"
                      placeholder="6 Zeichen"
                      value={createFields.initialCode}
                      onChange={(e) => setCreateFields((prev) => ({ ...prev, initialCode: e.target.value }))}
                    />
                    <button
                      type="button"
                      className="ghost btn-small"
                      onClick={() => setCreateFields((prev) => ({ ...prev, initialCode: generateGymCode() }))}
                    >
                      Auto
                    </button>
                  </div>
                </label>
                <label>
                  Logo URL (optional)
                  <input
                    className="input"
                    placeholder="https://..."
                    value={createFields.logoUrl}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, logoUrl: e.target.value }))}
                  />
                </label>
                <label>
                  Primary Color (Hex, optional)
                  <input
                    className="input"
                    placeholder="#2DD4BF"
                    value={createFields.primaryColor}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, primaryColor: e.target.value }))}
                  />
                </label>
                <label>
                  Accent Color (Hex, optional)
                  <input
                    className="input"
                    placeholder="#F5A524"
                    value={createFields.accentColor}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, accentColor: e.target.value }))}
                  />
                </label>
                <label className="inline-check">
                  <input
                    type="checkbox"
                    checked={createFields.selectAfterCreate}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, selectAfterCreate: e.target.checked }))}
                  />
                  Nach dem Anlegen auswählen
                </label>
                <label className="inline-check">
                  <input
                    type="checkbox"
                    checked={createFields.seedMuscleGroups}
                    onChange={(e) => setCreateFields((prev) => ({ ...prev, seedMuscleGroups: e.target.checked }))}
                  />
                  Standard-Muskelgruppen anlegen
                </label>
              </div>
              {createGymError && <p className="error">{createGymError}</p>}
              {createGymSuccess && <p className="muted">{createGymSuccess}</p>}
              <div style={{ display: 'flex', gap: '0.6rem', flexWrap: 'wrap' }}>
                <button className="ghost btn-small" type="button" disabled={creatingGym} onClick={createGym}>
                  {creatingGym ? 'Erstelle…' : 'Gym anlegen'}
                </button>
              </div>
            </div>
          </Card>
          {activeGym?.id && (
            <div style={{ marginTop: '0.5rem' }}>
              <Link className="ghost btn-small" to={`/gyms/${activeGym.id}`}>
                Geräte & Codes verwalten
              </Link>
            </div>
          )}
          {activeGym?.id && (
            <div style={{ display: 'grid', gap: '0.75rem', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))' }}>
              <Card title="User im Gym">
                <p style={{ fontSize: '2rem', margin: '0.2rem 0' }}>{userCount ?? '–'}</p>
                <p className="muted">gezählt (bis 500)</p>
              </Card>
              <Card title="Geräte im Gym">
                <p style={{ fontSize: '2rem', margin: '0.2rem 0' }}>{deviceCount ?? '–'}</p>
                <p className="muted">gezählt (bis 500)</p>
              </Card>
            </div>
          )}
        </>
      )}
    </div>
  );
}
