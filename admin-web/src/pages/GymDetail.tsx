import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  updateDoc,
  setDoc,
  addDoc,
  serverTimestamp,
  orderBy,
  writeBatch,
} from 'firebase/firestore';
import { db } from '../firebase';
import { useActiveGym } from '../hooks/useActiveGym';
import { Card } from '../components/Card';
import { defaultMuscleGroups } from '../data/defaultMuscleGroups';

interface Device {
  id: string;
  dataId?: string | number;
  name?: string;
  isMulti?: boolean;
  active?: boolean;
  description?: string;
  nfcCode?: string;
  muscleGroupIds?: string[];
  muscleGroups?: string[];
  primaryMuscleGroups?: string[];
  secondaryMuscleGroups?: string[];
}

interface MuscleGroup {
  id: string;
  name?: string;
  region?: string;
}

interface Code {
  id: string;
  code?: string;
  isActive?: boolean;
  expiresAt?: any;
}

interface FeedbackEntry {
  id: string;
  message?: string;
  createdAt?: any;
  userId?: string;
}

interface Survey {
  id: string;
  title?: string;
  options?: string[];
  status?: string;
  createdAt?: any;
}

export function GymDetail() {
  const { gymId } = useParams();
  const [devices, setDevices] = useState<Device[]>([]);
  const [muscleGroups, setMuscleGroups] = useState<MuscleGroup[]>([]);
  const [gymName, setGymName] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [codes, setCodes] = useState<Code[]>([]);
  const [feedback, setFeedback] = useState<FeedbackEntry[]>([]);
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [surveyTitle, setSurveyTitle] = useState('');
  const [surveyOptions, setSurveyOptions] = useState('');
  const [surveyResults, setSurveyResults] = useState<Record<string, Record<string, number>>>({});
  const { activeGym } = useActiveGym();
  const [savingDevice, setSavingDevice] = useState<string | null>(null);
  const [deviceError, setDeviceError] = useState<string | null>(null);
  const [creatingCode, setCreatingCode] = useState(false);
  const [updatingCode, setUpdatingCode] = useState<string | null>(null);
  const [creatingSurvey, setCreatingSurvey] = useState(false);
  const [closingSurvey, setClosingSurvey] = useState<string | null>(null);
  const [editingDeviceId, setEditingDeviceId] = useState<string | null>(null);
  const [deviceSort, setDeviceSort] = useState<'name' | 'id'>('name');
  const [fixingIds, setFixingIds] = useState(false);
  const [editingMuscleGroups, setEditingMuscleGroups] = useState(false);
  const [autoSeeded, setAutoSeeded] = useState(false);
  const [seedingGroups, setSeedingGroups] = useState(false);
  const [seedError, setSeedError] = useState<string | null>(null);
  const [muscleGroupEdits, setMuscleGroupEdits] = useState<Record<string, string>>({});
  const [editFields, setEditFields] = useState<Device>({
    id: '',
    name: '',
    description: '',
    isMulti: false,
    nfcCode: '',
    muscleGroupIds: [],
    muscleGroups: [],
    primaryMuscleGroups: [],
    secondaryMuscleGroups: [],
  });
  const [createFields, setCreateFields] = useState<Device>({
    id: '',
    name: '',
    description: '',
    isMulti: false,
    nfcCode: '',
    muscleGroupIds: [],
    muscleGroups: [],
    primaryMuscleGroups: [],
    secondaryMuscleGroups: [],
  });
  const [creatingDevice, setCreatingDevice] = useState(false);

  const resolvedGymId = gymId || activeGym?.id || null;

  useEffect(() => {
    const gymId = resolvedGymId;
    if (gymId == null) return;
    const gymIdSafe: string = gymId;
    async function load() {
      try {
        const gymSnap = await getDoc(doc(db, 'gyms', gymIdSafe));
        setGymName((gymSnap.data() as any)?.name || gymIdSafe);
        const q = query(collection(db, 'gyms', gymIdSafe, 'devices'), limit(100));
        const snap = await getDocs(q);
        const items = snap.docs.map((d) => {
          const data = d.data() as any;
          const { id: dataId, ...rest } = data || {};
          return { ...rest, id: d.id, dataId };
        });
        setDevices(items);

        const mgSnap = await getDocs(query(collection(db, 'gyms', gymIdSafe, 'muscleGroups'), limit(200)));
        const mgItems = mgSnap.docs.map((d) => ({ id: d.id, ...(d.data() as any) }));
        setMuscleGroups(mgItems);
        setMuscleGroupEdits((prev) => {
          if (Object.keys(prev).length) return prev;
          const next: Record<string, string> = {};
          mgItems.forEach((g) => {
            next[g.id] = g.name || '';
          });
          return next;
        });
        if (mgItems.length === 0 && !autoSeeded) {
          setAutoSeeded(true);
          await seedDefaultMuscleGroups();
        }

        const codeSnap = await getDocs(query(collection(db, 'gym_codes', gymIdSafe, 'codes'), limit(50)));
        setCodes(codeSnap.docs.map((d) => ({ id: d.id, ...(d.data() as any) })));

        const fbSnap = await getDocs(query(collection(db, 'gyms', gymIdSafe, 'feedback'), limit(50)));
        setFeedback(fbSnap.docs.map((d) => ({ id: d.id, ...(d.data() as any) })));

        const surveySnap = await getDocs(
          query(collection(db, 'gyms', gymIdSafe, 'surveys'), orderBy('createdAt', 'desc'), limit(50))
        );
        setSurveys(surveySnap.docs.map((d) => ({ id: d.id, ...(d.data() as any) })));
      } catch (err: any) {
        setError(err?.message || 'Konnte Gym laden');
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [resolvedGymId]);

  async function toggleDeviceActive(id: string, current: boolean | undefined) {
    if (!resolvedGymId) return;
    setSavingDevice(id);
    try {
      const gymId = String(resolvedGymId);
      const deviceId = String(id);
      await updateDoc(doc(db, 'gyms', gymId, 'devices', deviceId), { active: current === false ? true : false });
      setDevices((prev) =>
        prev.map((d) => (d.id === id ? { ...d, active: current === false ? true : false } : d))
      );
    } catch (err) {
      console.error(err);
      const message = `${(err as any)?.code ? `[${(err as any).code}] ` : ''}${(err as any)?.message || err}`;
      setDeviceError(message);
      alert(`Konnte Gerät nicht speichern: ${message}`);
    } finally {
      setSavingDevice(null);
    }
  }

  function generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRTUVWXY3468';
    let code = '';
    for (let i = 0; i < 6; i++) code += chars.charAt(Math.floor(Math.random() * chars.length));
    return code;
  }

  async function createGymCode() {
    if (!resolvedGymId) return;
    setCreatingCode(true);
    try {
      const code = generateCode();
      const now = new Date();
      const expires = new Date(now);
      expires.setDate(expires.getDate() + 30);
      await setDoc(doc(db, 'gym_codes', resolvedGymId, 'codes', code), {
        code,
        gymId: resolvedGymId,
        isActive: true,
        createdAt: now,
        expiresAt: expires,
        createdBy: 'admin-web',
      });
      setCodes((prev) => [{ id: code, code, isActive: true, expiresAt: expires, createdBy: 'admin-web' }, ...prev]);
    } catch (err) {
      console.error(err);
      alert('Konnte Code nicht anlegen.');
    } finally {
      setCreatingCode(false);
    }
  }

  async function deactivateGymCode(codeId: string) {
    if (!resolvedGymId) return;
    setUpdatingCode(codeId);
    try {
      await updateDoc(doc(db, 'gym_codes', resolvedGymId, 'codes', codeId), { isActive: false });
      setCodes((prev) => prev.map((c) => (c.id === codeId ? { ...c, isActive: false } : c)));
    } catch (err) {
      console.error(err);
      alert('Konnte Code nicht deaktivieren.');
    } finally {
      setUpdatingCode(null);
    }
  }

  async function rotateGymCode(codeId: string) {
    await deactivateGymCode(codeId);
    await createGymCode();
  }

  function parseList(val?: string | string[]) {
    if (!val) return [];
    if (Array.isArray(val)) return val.filter(Boolean);
    return val
      .split(',')
      .map((v) => v.trim())
      .filter(Boolean);
  }

  function normalizeText(val: any) {
    if (val === null || val === undefined) return '';
    return String(val);
  }

  function normalizeList(val: any) {
    if (!val) return [];
    if (Array.isArray(val)) return val.map((v) => String(v)).filter(Boolean);
    if (typeof val === 'string') return parseList(val);
    if (typeof val === 'object') return Object.values(val).map((v) => String(v)).filter(Boolean);
    return [];
  }

  function generateNfcCode() {
    const bytes = new Uint8Array(8);
    crypto.getRandomValues(bytes);
    return Array.from(bytes)
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('')
      .toUpperCase();
  }

  function getNextDeviceId() {
    const numericIds = devices
      .map((d) => (typeof d.dataId === 'number' ? d.dataId : Number(d.dataId)))
      .filter((n) => Number.isFinite(n)) as number[];
    const maxId = numericIds.length ? Math.max(...numericIds) : 0;
    return maxId + 1;
  }

  function uniq(list: string[]) {
    return Array.from(new Set(list.filter(Boolean)));
  }

  function nameForGroup(id: string) {
    const found = muscleGroups.find((g) => g.id === id);
    return found?.name || id;
  }

  function renderGroupPicker(
    selected: string[],
    onToggle: (id: string) => void,
    label: string
  ) {
    return (
      <div className="muscle-picker">
        <div className="muscle-picker-header">{label}</div>
        <div className="muscle-picker-list">
          {muscleGroups.map((g) => {
            const active = selected.includes(g.id);
            return (
              <button
                type="button"
                key={g.id}
                className={`muscle-pill ${active ? 'active' : ''}`}
                onClick={() => onToggle(g.id)}
                title={g.region ? `${g.name || g.id} • ${g.region}` : g.name || g.id}
              >
                {g.name || g.id}
              </button>
            );
          })}
          {muscleGroups.length === 0 && <span className="muted">Keine Muskelgruppen gefunden.</span>}
        </div>
      </div>
    );
  }

  function toDisplay(val?: string[]) {
    if (!val || !val.length) return '';
    return val.join(', ');
  }

  function startEdit(d: Device) {
    if (editingDeviceId === d.id) {
      setEditingDeviceId(null);
      return;
    }
    const primaryFallback = normalizeList(d.primaryMuscleGroups);
    const secondaryFallback = normalizeList(d.secondaryMuscleGroups);
    const fallbackAll = normalizeList(d.muscleGroupIds);
    const primaryResolved = primaryFallback.length ? primaryFallback : fallbackAll;
    const secondaryResolved = secondaryFallback.length ? secondaryFallback : [];
    setEditingDeviceId(d.id);
    setEditFields({
      ...d,
      id: d.id,
      name: normalizeText(d.name),
      description: normalizeText(d.description),
      nfcCode: normalizeText(d.nfcCode),
      isMulti: !!d.isMulti,
      muscleGroupIds: uniq(fallbackAll),
      muscleGroups: uniq(normalizeList(d.muscleGroups)),
      primaryMuscleGroups: uniq(primaryResolved),
      secondaryMuscleGroups: uniq(secondaryResolved),
    });
  }

  async function saveEdit() {
    if (!resolvedGymId || !editingDeviceId) return;
    setDeviceError(null);
    setSavingDevice(editingDeviceId);
    try {
      const gymId = String(resolvedGymId);
      const deviceId = String(editingDeviceId);
      const normalizedName = normalizeText(editFields.name).trim();
      const nextNfcCode = normalizeText(editFields.nfcCode) || generateNfcCode();
      const primary = uniq(normalizeList(editFields.primaryMuscleGroups));
      const secondary = uniq(normalizeList(editFields.secondaryMuscleGroups));
      if (!editFields.isMulti && primary.length === 0) {
        setDeviceError('Bitte mindestens eine Primärgruppe auswählen.');
        return;
      }
      const allGroups = uniq([...primary, ...secondary]);
      const normalized = {
        name: normalizedName || editingDeviceId,
        description: normalizeText(editFields.description),
        isMulti: !!editFields.isMulti,
        nfcCode: nextNfcCode,
        muscleGroupIds: allGroups,
        muscleGroups: allGroups,
        primaryMuscleGroups: primary,
        secondaryMuscleGroups: secondary,
      };
      await updateDoc(doc(db, 'gyms', gymId, 'devices', deviceId), {
        ...normalized,
      });
      setDevices((prev) =>
        prev.map((d) =>
          d.id === editingDeviceId
            ? {
                ...d,
                ...normalized,
              }
            : d
        )
      );
      setEditingDeviceId(null);
      setEditFields({
        id: '',
        name: '',
        description: '',
        isMulti: false,
        nfcCode: '',
        muscleGroupIds: [],
        muscleGroups: [],
        primaryMuscleGroups: [],
        secondaryMuscleGroups: [],
      });
    } catch (err) {
      console.error(err);
      const message = `${(err as any)?.code ? `[${(err as any).code}] ` : ''}${(err as any)?.message || err}`;
      setDeviceError(message);
      alert(`Konnte Gerät nicht speichern: ${message}`);
    } finally {
      setSavingDevice(null);
    }
  }

  async function createDevice() {
    if (!resolvedGymId || !createFields.name?.trim()) return;
    setDeviceError(null);
    setCreatingDevice(true);
    try {
      const gymId = String(resolvedGymId);
      const col = collection(db, 'gyms', gymId, 'devices');
      const normalizedName = normalizeText(createFields.name).trim();
      const nextNfcCode = normalizeText(createFields.nfcCode) || generateNfcCode();
      const nextId = getNextDeviceId();
      const primary = uniq(normalizeList(createFields.primaryMuscleGroups));
      const secondary = uniq(normalizeList(createFields.secondaryMuscleGroups));
      if (!createFields.isMulti && primary.length === 0) {
        setDeviceError('Bitte mindestens eine Primärgruppe auswählen.');
        return;
      }
      const allGroups = uniq([...primary, ...secondary]);
      const normalized = {
        name: normalizedName,
        description: normalizeText(createFields.description),
        isMulti: !!createFields.isMulti,
        nfcCode: nextNfcCode,
        muscleGroupIds: allGroups,
        muscleGroups: allGroups,
        primaryMuscleGroups: primary,
        secondaryMuscleGroups: secondary,
      };
      const docRef = await addDoc(col, {
        id: nextId,
        ...normalized,
        active: true,
        createdAt: serverTimestamp(),
      });
      setDevices((prev) => [
        {
          id: docRef.id,
          dataId: nextId,
          ...normalized,
          active: true,
        },
        ...prev,
      ]);
      setCreateFields({
        id: '',
        name: '',
        description: '',
        isMulti: false,
        nfcCode: '',
        muscleGroupIds: [],
        muscleGroups: [],
        primaryMuscleGroups: [],
        secondaryMuscleGroups: [],
      });
    } catch (err) {
      console.error(err);
      const message = `${(err as any)?.code ? `[${(err as any).code}] ` : ''}${(err as any)?.message || err}`;
      setDeviceError(message);
      alert(`Konnte Gerät nicht anlegen: ${message}`);
    } finally {
      setCreatingDevice(false);
    }
  }

  async function seedDefaultMuscleGroups() {
    if (!resolvedGymId) return;
    setSeedError(null);
    setSeedingGroups(true);
    try {
      const gymId = String(resolvedGymId);
      const batch = writeBatch(db);
      defaultMuscleGroups.forEach((group) => {
        batch.set(doc(db, 'gyms', gymId, 'muscleGroups', group.id), {
          name: group.name,
          region: group.region,
          majorCategory: group.majorCategory,
        });
      });
      await batch.commit();
      setMuscleGroups(defaultMuscleGroups.map((g) => ({ id: g.id, name: g.name, region: g.region })));
      setMuscleGroupEdits((prev) => {
        const next = { ...prev };
        defaultMuscleGroups.forEach((g) => {
          if (!(g.id in next)) next[g.id] = g.name;
        });
        return next;
      });
    } catch (err) {
      console.error(err);
      const message = `${(err as any)?.code ? `[${(err as any).code}] ` : ''}${(err as any)?.message || err}`;
      setSeedError(message);
      alert(`Konnte Standard-Muskelgruppen nicht anlegen: ${message}`);
    } finally {
      setSeedingGroups(false);
    }
  }

  async function createSurvey() {
    if (!resolvedGymId) return;
    const title = surveyTitle.trim();
    if (!title) return;
    const options = parseList(surveyOptions);
    if (options.length < 2) {
      alert('Bitte mindestens 2 Antwortoptionen angeben.');
      return;
    }
    setCreatingSurvey(true);
    try {
      const ref = await addDoc(collection(db, 'gyms', resolvedGymId, 'surveys'), {
        title,
        options,
        status: 'open',
        createdAt: serverTimestamp(),
      });
      setSurveys((prev) => [{ id: ref.id, title, options, status: 'open', createdAt: new Date() }, ...prev]);
      setSurveyTitle('');
      setSurveyOptions('');
    } catch (err) {
      console.error(err);
      alert('Konnte Umfrage nicht anlegen.');
    } finally {
      setCreatingSurvey(false);
    }
  }

  async function closeSurvey(surveyId: string) {
    if (!resolvedGymId) return;
    setClosingSurvey(surveyId);
    try {
      await updateDoc(doc(db, 'gyms', resolvedGymId, 'surveys', surveyId), { status: 'abgeschlossen' });
      setSurveys((prev) => prev.map((s) => (s.id === surveyId ? { ...s, status: 'abgeschlossen' } : s)));
    } catch (err) {
      console.error(err);
      alert('Konnte Umfrage nicht schließen.');
    } finally {
      setClosingSurvey(null);
    }
  }

  async function loadSurveyResults(surveyId: string, options: string[]) {
    if (!resolvedGymId) return;
    try {
      const snap = await getDocs(collection(db, 'gyms', resolvedGymId, 'surveys', surveyId, 'answers'));
      const counts: Record<string, number> = {};
      options.forEach((o) => (counts[o] = 0));
      snap.docs.forEach((d) => {
        const opt = (d.data() as any)?.selectedOption;
        if (opt && counts[opt] !== undefined) counts[opt] += 1;
      });
      setSurveyResults((prev) => ({ ...prev, [surveyId]: counts }));
    } catch (err) {
      console.error(err);
      alert('Konnte Ergebnisse nicht laden.');
    }
  }

  async function repairMissingDeviceIds() {
    if (!resolvedGymId) return;
    const missing = devices.filter((d) => !Number.isFinite(Number(d.dataId)));
    if (missing.length === 0) {
      alert('Keine Geräte ohne ID gefunden.');
      return;
    }
    if (!confirm(`IDs fehlen bei ${missing.length} Geräten. Jetzt automatisch vergeben?`)) {
      return;
    }
    setFixingIds(true);
    try {
      let nextId = getNextDeviceId();
      const gymId = String(resolvedGymId);
      const updates: Record<string, number> = {};
      for (const d of missing) {
        updates[d.id] = nextId++;
      }
      await Promise.all(
        Object.entries(updates).map(([docId, idValue]) =>
          updateDoc(doc(db, 'gyms', gymId, 'devices', docId), { id: idValue })
        )
      );
      setDevices((prev) =>
        prev.map((d) => (updates[d.id] ? { ...d, dataId: updates[d.id] } : d))
      );
    } catch (err) {
      console.error(err);
      alert('Konnte Geräte-IDs nicht reparieren.');
    } finally {
      setFixingIds(false);
    }
  }

  async function saveMuscleGroupName(groupId: string) {
    if (!resolvedGymId) return;
    const name = (muscleGroupEdits[groupId] || '').trim();
    try {
      await updateDoc(doc(db, 'gyms', String(resolvedGymId), 'muscleGroups', groupId), { name });
      setMuscleGroups((prev) => prev.map((g) => (g.id === groupId ? { ...g, name } : g)));
    } catch (err) {
      console.error(err);
      alert('Konnte Muskelgruppen-Name nicht speichern.');
    }
  }

  return (
    <div className="page">
      <h1>{gymName || resolvedGymId || 'Gym'}</h1>
      {loading && <p className="muted">Lade…</p>}
      {error && <p className="error">{error}</p>}
      {!loading && !error && (
        <div style={{ display: 'grid', gap: '1rem' }}>
          <Card title="Geräte">
            {muscleGroups.length === 0 && (
              <div style={{ display: 'flex', gap: '0.6rem', alignItems: 'center', flexWrap: 'wrap', marginBottom: '0.6rem' }}>
                <span className="muted">Keine Muskelgruppen gefunden.</span>
                <button className="ghost btn-small" onClick={seedDefaultMuscleGroups} disabled={seedingGroups}>
                  {seedingGroups ? 'Anlegen…' : 'Standard-Muskelgruppen anlegen'}
                </button>
              </div>
            )}
            {seedError && <p className="error">Muskelgruppen-Seed: {seedError}</p>}
            {deviceError && <p className="error">Geräte-Fehler: {deviceError}</p>}
            <div className="device-form">
              <div className="device-grid">
                <label>
                  Name
                  <input
                    className="input"
                    placeholder="Gerätename"
                    value={createFields.name || ''}
                    onChange={(e) => setCreateFields((p) => ({ ...p, name: e.target.value }))}
                  />
                </label>
                <label>
                  Description
                  <input
                    className="input"
                    placeholder="Beschreibung"
                    value={createFields.description || ''}
                    onChange={(e) => setCreateFields((p) => ({ ...p, description: e.target.value }))}
                  />
                </label>
                <label>
                  NFC-Code
                  <div style={{ display: 'flex', gap: '0.5rem' }}>
                    <input
                      className="input"
                      placeholder="NFC Code"
                      value={createFields.nfcCode || ''}
                      onChange={(e) => setCreateFields((p) => ({ ...p, nfcCode: e.target.value }))}
                    />
                    <button
                      type="button"
                      className="ghost btn-small"
                      onClick={() => setCreateFields((p) => ({ ...p, nfcCode: generateNfcCode() }))}
                    >
                      NFC auto
                    </button>
                  </div>
                </label>
                <label className="inline-check">
                  <input
                    type="checkbox"
                    checked={!!createFields.isMulti}
                    onChange={(e) => setCreateFields((p) => ({ ...p, isMulti: e.target.checked }))}
                  />
                  multi
                </label>
                <div className="muscle-selectors">
                  {renderGroupPicker(
                    createFields.primaryMuscleGroups || [],
                    (id) =>
                      setCreateFields((p) => {
                        const current = new Set(p.primaryMuscleGroups || []);
                        if (current.has(id)) {
                          current.delete(id);
                          return { ...p, primaryMuscleGroups: Array.from(current) };
                        }
                        const nextSecondary = (p.secondaryMuscleGroups || []).filter((g) => g !== id);
                        current.add(id);
                        return {
                          ...p,
                          primaryMuscleGroups: Array.from(current),
                          secondaryMuscleGroups: nextSecondary,
                        };
                      }),
                    'Primärgruppen'
                  )}
                  {renderGroupPicker(
                    createFields.secondaryMuscleGroups || [],
                    (id) =>
                      setCreateFields((p) => {
                        const current = new Set(p.secondaryMuscleGroups || []);
                        if (current.has(id)) {
                          current.delete(id);
                          return { ...p, secondaryMuscleGroups: Array.from(current) };
                        }
                        const nextPrimary = (p.primaryMuscleGroups || []).filter((g) => g !== id);
                        current.add(id);
                        return {
                          ...p,
                          secondaryMuscleGroups: Array.from(current),
                          primaryMuscleGroups: nextPrimary,
                        };
                      }),
                    'Sekundärgruppen'
                  )}
                  <div className="muscle-summary">
                    Ausgewählt:{' '}
                    {uniq([
                      ...(createFields.primaryMuscleGroups || []),
                      ...(createFields.secondaryMuscleGroups || []),
                    ])
                      .map((id) => nameForGroup(id))
                      .join(', ') || '–'}
                  </div>
                </div>
              </div>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button className="ghost btn-small" disabled={creatingDevice} onClick={createDevice}>
                  {creatingDevice ? 'Erstelle…' : 'Gerät anlegen'}
                </button>
              </div>
            </div>
            <div style={{ display: 'flex', gap: '0.6rem', alignItems: 'center', marginBottom: '0.4rem' }}>
              <span className="muted small">Sortierung:</span>
              <button
                className={`ghost btn-small ${deviceSort === 'name' ? 'active' : ''}`}
                onClick={() => setDeviceSort('name')}
              >
                Name (A–Z)
              </button>
              <button
                className={`ghost btn-small ${deviceSort === 'id' ? 'active' : ''}`}
                onClick={() => setDeviceSort('id')}
              >
                ID (1–∞)
              </button>
              <button className="ghost btn-small" disabled={fixingIds} onClick={repairMissingDeviceIds}>
                {fixingIds ? 'Repariere IDs…' : 'IDs reparieren'}
              </button>
            </div>

            <div className="device-list">
              {devices
                .slice()
                .sort((a, b) => {
                  if (deviceSort === 'id') {
                    const aId = typeof a.dataId === 'number' ? a.dataId : Number(a.dataId);
                    const bId = typeof b.dataId === 'number' ? b.dataId : Number(b.dataId);
                    if (Number.isFinite(aId) && Number.isFinite(bId)) return aId - bId;
                    if (Number.isFinite(aId)) return -1;
                    if (Number.isFinite(bId)) return 1;
                    return 0;
                  }
                  const aName = (a.name || '').toLowerCase();
                  const bName = (b.name || '').toLowerCase();
                  return aName.localeCompare(bName);
                })
                .map((d) => {
                const isEditing = editingDeviceId === d.id;
                return (
                  <div key={d.id} className="device-row">
                    <div className="device-row-main">
                      <div>
                        <strong>{d.name || d.id}</strong>
                        {d.description ? (
                          <span className="muted small" style={{ marginLeft: '0.45rem' }}>
                            • {d.description}
                          </span>
                        ) : null}
                        <div className="muted small">
                          {d.active === false ? 'Deaktiviert' : 'Aktiv'} {d.isMulti ? '• multi' : ''}{' '}
                          {d.muscleGroups?.length
                            ? `• ${d.muscleGroups.map((id) => nameForGroup(id)).join(', ')}`
                            : ''}{' '}
                          <span className="mono">• Doc-ID: {d.id}</span>
                          {d.dataId !== undefined && d.dataId !== null && d.dataId !== '' ? (
                            <span className="mono"> • Daten-ID: {String(d.dataId)}</span>
                          ) : null}
                        </div>
                      </div>
                      <div className="device-actions">
                        <button className="ghost btn-small" disabled={!!savingDevice} onClick={() => startEdit(d)}>
                          Bearbeiten
                        </button>
                        <button
                          className="ghost btn-small"
                          disabled={!!savingDevice}
                          onClick={() => toggleDeviceActive(d.id, d.active)}
                        >
                          {d.active === false ? 'Aktivieren' : 'Deaktivieren'}
                        </button>
                      </div>
                    </div>
                    {isEditing && (
                      <div className="device-edit-grid">
                        <label>
                          Name
                          <input
                            className="input"
                            value={editFields.name || ''}
                            onChange={(e) => setEditFields((p) => ({ ...p, name: e.target.value }))}
                          />
                        </label>
                        <label>
                          Description
                          <input
                            className="input"
                            value={editFields.description || ''}
                            onChange={(e) => setEditFields((p) => ({ ...p, description: e.target.value }))}
                          />
                        </label>
                        <label>
                          NFC-Code
                          <div style={{ display: 'flex', gap: '0.5rem' }}>
                            <input
                              className="input"
                              value={editFields.nfcCode || ''}
                              onChange={(e) => setEditFields((p) => ({ ...p, nfcCode: e.target.value }))}
                            />
                            <button
                              type="button"
                              className="ghost btn-small"
                              onClick={() => setEditFields((p) => ({ ...p, nfcCode: generateNfcCode() }))}
                            >
                              NFC neu
                            </button>
                          </div>
                        </label>
                        <label className="inline-check">
                          <input
                            type="checkbox"
                            checked={!!editFields.isMulti}
                            onChange={(e) => setEditFields((p) => ({ ...p, isMulti: e.target.checked }))}
                          />
                          multi
                        </label>
                        <div className="muscle-selectors">
                          {renderGroupPicker(
                            editFields.primaryMuscleGroups || [],
                            (id) =>
                              setEditFields((p) => {
                                const current = new Set(p.primaryMuscleGroups || []);
                                if (current.has(id)) {
                                  current.delete(id);
                                  return { ...p, primaryMuscleGroups: Array.from(current) };
                                }
                                const nextSecondary = (p.secondaryMuscleGroups || []).filter((g) => g !== id);
                                current.add(id);
                                return {
                                  ...p,
                                  primaryMuscleGroups: Array.from(current),
                                  secondaryMuscleGroups: nextSecondary,
                                };
                              }),
                            'Primärgruppen'
                          )}
                          {renderGroupPicker(
                            editFields.secondaryMuscleGroups || [],
                            (id) =>
                              setEditFields((p) => {
                                const current = new Set(p.secondaryMuscleGroups || []);
                                if (current.has(id)) {
                                  current.delete(id);
                                  return { ...p, secondaryMuscleGroups: Array.from(current) };
                                }
                                const nextPrimary = (p.primaryMuscleGroups || []).filter((g) => g !== id);
                                current.add(id);
                                return {
                                  ...p,
                                  secondaryMuscleGroups: Array.from(current),
                                  primaryMuscleGroups: nextPrimary,
                                };
                              }),
                            'Sekundärgruppen'
                          )}
                          <div className="muscle-summary">
                            Ausgewählt:{' '}
                            {uniq([
                              ...(editFields.primaryMuscleGroups || []),
                              ...(editFields.secondaryMuscleGroups || []),
                            ])
                              .map((id) => nameForGroup(id))
                              .join(', ') || '–'}
                          </div>
                        </div>
                        <div className="device-actions">
                          <button className="ghost btn-small" disabled={!!savingDevice} onClick={saveEdit}>
                            Speichern
                          </button>
                          <button className="ghost btn-small" onClick={() => setEditingDeviceId(null)}>
                            Abbrechen
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </Card>

          <Card title="Muskelgruppen">
            <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.6rem', flexWrap: 'wrap' }}>
              <span className="muted small">
                {muscleGroups.length} Gruppen · {muscleGroups.filter((g) => !g.name).length} ohne Namen
              </span>
              <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                <button
                  className="ghost btn-small"
                  onClick={seedDefaultMuscleGroups}
                  disabled={muscleGroups.length > 0 || seedingGroups}
                >
                  {seedingGroups ? 'Anlegen…' : 'Standard anlegen'}
                </button>
                <button className="ghost btn-small" onClick={() => setEditingMuscleGroups((v) => !v)}>
                  {editingMuscleGroups ? 'Schließen' : 'Bearbeiten'}
                </button>
              </div>
            </div>
            {editingMuscleGroups && (
              <div className="mg-list">
                {muscleGroups
                  .slice()
                  .sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id))
                  .map((g) => (
                    <div key={g.id} className="mg-row">
                      <div className="mono">{g.id}</div>
                      <input
                        className="input"
                        placeholder="Name anzeigen"
                        value={muscleGroupEdits[g.id] ?? ''}
                        onChange={(e) =>
                          setMuscleGroupEdits((prev) => ({ ...prev, [g.id]: e.target.value }))
                        }
                      />
                      <button className="ghost btn-small" onClick={() => saveMuscleGroupName(g.id)}>
                        Speichern
                      </button>
                    </div>
                  ))}
              </div>
            )}
          </Card>

          <Card title="Gym Codes">
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '0.6rem' }}>
              <button className="ghost btn-small" disabled={creatingCode} onClick={createGymCode}>
                {creatingCode ? 'Erstelle…' : 'Neuen Code erstellen'}
              </button>
            </div>
            {codes.length === 0 && <p className="muted">Keine Codes gefunden.</p>}
            {codes.length > 0 && (
              <table className="table">
                <thead>
                  <tr>
                    <th>Code</th>
                    <th>Aktiv</th>
                    <th>Expires</th>
                    <th>CreatedBy</th>
                    <th>Aktionen</th>
                  </tr>
                </thead>
                <tbody>
                  {codes.map((c) => (
                    <tr key={c.id}>
                      <td className="mono">{c.code || c.id}</td>
                      <td>{c.isActive ? 'Ja' : 'Nein'}</td>
                      <td>{c.expiresAt ? formatDate(c.expiresAt) : '–'}</td>
                      <td>{(c as any)?.createdBy || '–'}</td>
                      <td>
                        {c.isActive ? (
                          <div style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }}>
                            <button
                              className="ghost btn-small"
                              disabled={updatingCode === c.id}
                              onClick={() => deactivateGymCode(c.id)}
                            >
                              Deaktivieren
                            </button>
                            <button
                              className="ghost btn-small"
                              disabled={updatingCode === c.id}
                              onClick={() => rotateGymCode(c.id)}
                            >
                              Rotieren
                            </button>
                          </div>
                        ) : (
                          '–'
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </Card>

          <Card title="Umfragen">
            <div className="form" style={{ marginBottom: '1rem' }}>
              <label>
                Titel
                <input
                  className="input"
                  placeholder="z.B. Welche Geräte sollen wir ergänzen?"
                  value={surveyTitle}
                  onChange={(e) => setSurveyTitle(e.target.value)}
                />
              </label>
              <label>
                Optionen (kommagetrennt)
                <input
                  className="input"
                  placeholder="Gerät A, Gerät B, Gerät C"
                  value={surveyOptions}
                  onChange={(e) => setSurveyOptions(e.target.value)}
                />
              </label>
              <div>
                <button className="ghost btn-small" disabled={creatingSurvey} onClick={createSurvey}>
                  {creatingSurvey ? 'Erstelle…' : 'Umfrage anlegen'}
                </button>
              </div>
            </div>
            {surveys.length === 0 && <p className="muted">Keine Umfragen gefunden.</p>}
            {surveys.length > 0 && (
              <table className="table">
                <thead>
                  <tr>
                    <th>Titel</th>
                    <th>Status</th>
                    <th>Optionen</th>
                    <th>Aktionen</th>
                  </tr>
                </thead>
                <tbody>
                  {surveys.map((s) => (
                    <tr key={s.id}>
                      <td>{s.title || '–'}</td>
                      <td>{s.status || '–'}</td>
                      <td>{s.options?.join(', ') || '–'}</td>
                      <td>
                        <div style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }}>
                          <button
                            className="ghost btn-small"
                            onClick={() => loadSurveyResults(s.id, s.options || [])}
                          >
                            Ergebnisse
                          </button>
                          {s.status !== 'abgeschlossen' && (
                            <button
                              className="ghost btn-small"
                              disabled={closingSurvey === s.id}
                              onClick={() => closeSurvey(s.id)}
                            >
                              Schließen
                            </button>
                          )}
                        </div>
                        {surveyResults[s.id] && (
                          <div className="muted small" style={{ marginTop: '0.4rem' }}>
                            {Object.entries(surveyResults[s.id])
                              .map(([opt, count]) => `${opt}: ${count}`)
                              .join(' · ')}
                          </div>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </Card>

          <Card title="Feedback (letzte 50)">
            {feedback.length === 0 && <p className="muted">Kein Feedback gefunden.</p>}
            {feedback.length > 0 && (
              <table className="table">
                <thead>
                  <tr>
                    <th>User</th>
                    <th>Message</th>
                    <th>Created</th>
                  </tr>
                </thead>
                <tbody>
                  {feedback.map((f) => (
                    <tr key={f.id}>
                      <td className="mono">{f.userId || '–'}</td>
                      <td>{f.message || '–'}</td>
                      <td>{f.createdAt ? formatDate(f.createdAt) : '–'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </Card>
        </div>
      )}
    </div>
  );
}

function formatDate(val: any) {
  if (!val) return '';
  if (typeof val === 'string') return new Date(val).toLocaleString();
  if (val.toDate) return val.toDate().toLocaleString();
  return '';
}
