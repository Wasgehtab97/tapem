import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { collection, doc, getDoc, getDocs, limit, query, updateDoc, setDoc, addDoc, serverTimestamp, orderBy, writeBatch, } from 'firebase/firestore';
import { db } from '../firebase';
import { useActiveGym } from '../hooks/useActiveGym';
import { Card } from '../components/Card';
import { defaultMuscleGroups } from '../data/defaultMuscleGroups';
export function GymDetail() {
    const { gymId } = useParams();
    const [devices, setDevices] = useState([]);
    const [muscleGroups, setMuscleGroups] = useState([]);
    const [gymName, setGymName] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [codes, setCodes] = useState([]);
    const [feedback, setFeedback] = useState([]);
    const [surveys, setSurveys] = useState([]);
    const [surveyTitle, setSurveyTitle] = useState('');
    const [surveyOptions, setSurveyOptions] = useState('');
    const [surveyResults, setSurveyResults] = useState({});
    const { activeGym } = useActiveGym();
    const [savingDevice, setSavingDevice] = useState(null);
    const [deviceError, setDeviceError] = useState(null);
    const [creatingCode, setCreatingCode] = useState(false);
    const [updatingCode, setUpdatingCode] = useState(null);
    const [creatingSurvey, setCreatingSurvey] = useState(false);
    const [closingSurvey, setClosingSurvey] = useState(null);
    const [editingDeviceId, setEditingDeviceId] = useState(null);
    const [deviceSort, setDeviceSort] = useState('name');
    const [fixingIds, setFixingIds] = useState(false);
    const [editingMuscleGroups, setEditingMuscleGroups] = useState(false);
    const [autoSeeded, setAutoSeeded] = useState(false);
    const [seedingGroups, setSeedingGroups] = useState(false);
    const [seedError, setSeedError] = useState(null);
    const [muscleGroupEdits, setMuscleGroupEdits] = useState({});
    const [editFields, setEditFields] = useState({
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
    const [createFields, setCreateFields] = useState({
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
        if (gymId == null)
            return;
        const gymIdSafe = gymId;
        async function load() {
            try {
                const gymSnap = await getDoc(doc(db, 'gyms', gymIdSafe));
                setGymName(gymSnap.data()?.name || gymIdSafe);
                const q = query(collection(db, 'gyms', gymIdSafe, 'devices'), limit(100));
                const snap = await getDocs(q);
                const items = snap.docs.map((d) => {
                    const data = d.data();
                    const { id: dataId, ...rest } = data || {};
                    return { ...rest, id: d.id, dataId };
                });
                setDevices(items);
                const mgSnap = await getDocs(query(collection(db, 'gyms', gymIdSafe, 'muscleGroups'), limit(200)));
                const mgItems = mgSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
                setMuscleGroups(mgItems);
                setMuscleGroupEdits((prev) => {
                    if (Object.keys(prev).length)
                        return prev;
                    const next = {};
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
                setCodes(codeSnap.docs.map((d) => ({ id: d.id, ...d.data() })));
                const fbSnap = await getDocs(query(collection(db, 'gyms', gymIdSafe, 'feedback'), limit(50)));
                setFeedback(fbSnap.docs.map((d) => ({ id: d.id, ...d.data() })));
                const surveySnap = await getDocs(query(collection(db, 'gyms', gymIdSafe, 'surveys'), orderBy('createdAt', 'desc'), limit(50)));
                setSurveys(surveySnap.docs.map((d) => ({ id: d.id, ...d.data() })));
            }
            catch (err) {
                setError(err?.message || 'Konnte Gym laden');
            }
            finally {
                setLoading(false);
            }
        }
        load();
    }, [resolvedGymId]);
    async function toggleDeviceActive(id, current) {
        if (!resolvedGymId)
            return;
        setSavingDevice(id);
        try {
            const gymId = String(resolvedGymId);
            const deviceId = String(id);
            await updateDoc(doc(db, 'gyms', gymId, 'devices', deviceId), { active: current === false ? true : false });
            setDevices((prev) => prev.map((d) => (d.id === id ? { ...d, active: current === false ? true : false } : d)));
        }
        catch (err) {
            console.error(err);
            const message = `${err?.code ? `[${err.code}] ` : ''}${err?.message || err}`;
            setDeviceError(message);
            alert(`Konnte Gerät nicht speichern: ${message}`);
        }
        finally {
            setSavingDevice(null);
        }
    }
    function generateCode() {
        const chars = 'ABCDEFGHJKLMNPQRTUVWXY3468';
        let code = '';
        for (let i = 0; i < 6; i++)
            code += chars.charAt(Math.floor(Math.random() * chars.length));
        return code;
    }
    async function createGymCode() {
        if (!resolvedGymId)
            return;
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
        }
        catch (err) {
            console.error(err);
            alert('Konnte Code nicht anlegen.');
        }
        finally {
            setCreatingCode(false);
        }
    }
    async function deactivateGymCode(codeId) {
        if (!resolvedGymId)
            return;
        setUpdatingCode(codeId);
        try {
            await updateDoc(doc(db, 'gym_codes', resolvedGymId, 'codes', codeId), { isActive: false });
            setCodes((prev) => prev.map((c) => (c.id === codeId ? { ...c, isActive: false } : c)));
        }
        catch (err) {
            console.error(err);
            alert('Konnte Code nicht deaktivieren.');
        }
        finally {
            setUpdatingCode(null);
        }
    }
    async function rotateGymCode(codeId) {
        await deactivateGymCode(codeId);
        await createGymCode();
    }
    function parseList(val) {
        if (!val)
            return [];
        if (Array.isArray(val))
            return val.filter(Boolean);
        return val
            .split(',')
            .map((v) => v.trim())
            .filter(Boolean);
    }
    function normalizeText(val) {
        if (val === null || val === undefined)
            return '';
        return String(val);
    }
    function normalizeList(val) {
        if (!val)
            return [];
        if (Array.isArray(val))
            return val.map((v) => String(v)).filter(Boolean);
        if (typeof val === 'string')
            return parseList(val);
        if (typeof val === 'object')
            return Object.values(val).map((v) => String(v)).filter(Boolean);
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
            .filter((n) => Number.isFinite(n));
        const maxId = numericIds.length ? Math.max(...numericIds) : 0;
        return maxId + 1;
    }
    function uniq(list) {
        return Array.from(new Set(list.filter(Boolean)));
    }
    function nameForGroup(id) {
        const found = muscleGroups.find((g) => g.id === id);
        return found?.name || id;
    }
    function renderGroupPicker(selected, onToggle, label) {
        return (_jsxs("div", { className: "muscle-picker", children: [_jsx("div", { className: "muscle-picker-header", children: label }), _jsxs("div", { className: "muscle-picker-list", children: [muscleGroups.map((g) => {
                            const active = selected.includes(g.id);
                            return (_jsx("button", { type: "button", className: `muscle-pill ${active ? 'active' : ''}`, onClick: () => onToggle(g.id), title: g.region ? `${g.name || g.id} • ${g.region}` : g.name || g.id, children: g.name || g.id }, g.id));
                        }), muscleGroups.length === 0 && _jsx("span", { className: "muted", children: "Keine Muskelgruppen gefunden." })] })] }));
    }
    function toDisplay(val) {
        if (!val || !val.length)
            return '';
        return val.join(', ');
    }
    function startEdit(d) {
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
        if (!resolvedGymId || !editingDeviceId)
            return;
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
            setDevices((prev) => prev.map((d) => d.id === editingDeviceId
                ? {
                    ...d,
                    ...normalized,
                }
                : d));
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
        }
        catch (err) {
            console.error(err);
            const message = `${err?.code ? `[${err.code}] ` : ''}${err?.message || err}`;
            setDeviceError(message);
            alert(`Konnte Gerät nicht speichern: ${message}`);
        }
        finally {
            setSavingDevice(null);
        }
    }
    async function createDevice() {
        if (!resolvedGymId || !createFields.name?.trim())
            return;
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
        }
        catch (err) {
            console.error(err);
            const message = `${err?.code ? `[${err.code}] ` : ''}${err?.message || err}`;
            setDeviceError(message);
            alert(`Konnte Gerät nicht anlegen: ${message}`);
        }
        finally {
            setCreatingDevice(false);
        }
    }
    async function seedDefaultMuscleGroups() {
        if (!resolvedGymId)
            return;
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
                    if (!(g.id in next))
                        next[g.id] = g.name;
                });
                return next;
            });
        }
        catch (err) {
            console.error(err);
            const message = `${err?.code ? `[${err.code}] ` : ''}${err?.message || err}`;
            setSeedError(message);
            alert(`Konnte Standard-Muskelgruppen nicht anlegen: ${message}`);
        }
        finally {
            setSeedingGroups(false);
        }
    }
    async function createSurvey() {
        if (!resolvedGymId)
            return;
        const title = surveyTitle.trim();
        if (!title)
            return;
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
        }
        catch (err) {
            console.error(err);
            alert('Konnte Umfrage nicht anlegen.');
        }
        finally {
            setCreatingSurvey(false);
        }
    }
    async function closeSurvey(surveyId) {
        if (!resolvedGymId)
            return;
        setClosingSurvey(surveyId);
        try {
            await updateDoc(doc(db, 'gyms', resolvedGymId, 'surveys', surveyId), { status: 'abgeschlossen' });
            setSurveys((prev) => prev.map((s) => (s.id === surveyId ? { ...s, status: 'abgeschlossen' } : s)));
        }
        catch (err) {
            console.error(err);
            alert('Konnte Umfrage nicht schließen.');
        }
        finally {
            setClosingSurvey(null);
        }
    }
    async function loadSurveyResults(surveyId, options) {
        if (!resolvedGymId)
            return;
        try {
            const snap = await getDocs(collection(db, 'gyms', resolvedGymId, 'surveys', surveyId, 'answers'));
            const counts = {};
            options.forEach((o) => (counts[o] = 0));
            snap.docs.forEach((d) => {
                const opt = d.data()?.selectedOption;
                if (opt && counts[opt] !== undefined)
                    counts[opt] += 1;
            });
            setSurveyResults((prev) => ({ ...prev, [surveyId]: counts }));
        }
        catch (err) {
            console.error(err);
            alert('Konnte Ergebnisse nicht laden.');
        }
    }
    async function repairMissingDeviceIds() {
        if (!resolvedGymId)
            return;
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
            const updates = {};
            for (const d of missing) {
                updates[d.id] = nextId++;
            }
            await Promise.all(Object.entries(updates).map(([docId, idValue]) => updateDoc(doc(db, 'gyms', gymId, 'devices', docId), { id: idValue })));
            setDevices((prev) => prev.map((d) => (updates[d.id] ? { ...d, dataId: updates[d.id] } : d)));
        }
        catch (err) {
            console.error(err);
            alert('Konnte Geräte-IDs nicht reparieren.');
        }
        finally {
            setFixingIds(false);
        }
    }
    async function saveMuscleGroupName(groupId) {
        if (!resolvedGymId)
            return;
        const name = (muscleGroupEdits[groupId] || '').trim();
        try {
            await updateDoc(doc(db, 'gyms', String(resolvedGymId), 'muscleGroups', groupId), { name });
            setMuscleGroups((prev) => prev.map((g) => (g.id === groupId ? { ...g, name } : g)));
        }
        catch (err) {
            console.error(err);
            alert('Konnte Muskelgruppen-Name nicht speichern.');
        }
    }
    return (_jsxs("div", { className: "page", children: [_jsx("h1", { children: gymName || resolvedGymId || 'Gym' }), loading && _jsx("p", { className: "muted", children: "Lade\u2026" }), error && _jsx("p", { className: "error", children: error }), !loading && !error && (_jsxs("div", { style: { display: 'grid', gap: '1rem' }, children: [_jsxs(Card, { title: "Ger\u00E4te", children: [muscleGroups.length === 0 && (_jsxs("div", { style: { display: 'flex', gap: '0.6rem', alignItems: 'center', flexWrap: 'wrap', marginBottom: '0.6rem' }, children: [_jsx("span", { className: "muted", children: "Keine Muskelgruppen gefunden." }), _jsx("button", { className: "ghost btn-small", onClick: seedDefaultMuscleGroups, disabled: seedingGroups, children: seedingGroups ? 'Anlegen…' : 'Standard-Muskelgruppen anlegen' })] })), seedError && _jsxs("p", { className: "error", children: ["Muskelgruppen-Seed: ", seedError] }), deviceError && _jsxs("p", { className: "error", children: ["Ger\u00E4te-Fehler: ", deviceError] }), _jsxs("div", { className: "device-form", children: [_jsxs("div", { className: "device-grid", children: [_jsxs("label", { children: ["Name", _jsx("input", { className: "input", placeholder: "Ger\u00E4tename", value: createFields.name || '', onChange: (e) => setCreateFields((p) => ({ ...p, name: e.target.value })) })] }), _jsxs("label", { children: ["Description", _jsx("input", { className: "input", placeholder: "Beschreibung", value: createFields.description || '', onChange: (e) => setCreateFields((p) => ({ ...p, description: e.target.value })) })] }), _jsxs("label", { children: ["NFC-Code", _jsxs("div", { style: { display: 'flex', gap: '0.5rem' }, children: [_jsx("input", { className: "input", placeholder: "NFC Code", value: createFields.nfcCode || '', onChange: (e) => setCreateFields((p) => ({ ...p, nfcCode: e.target.value })) }), _jsx("button", { type: "button", className: "ghost btn-small", onClick: () => setCreateFields((p) => ({ ...p, nfcCode: generateNfcCode() })), children: "NFC auto" })] })] }), _jsxs("label", { className: "inline-check", children: [_jsx("input", { type: "checkbox", checked: !!createFields.isMulti, onChange: (e) => setCreateFields((p) => ({ ...p, isMulti: e.target.checked })) }), "multi"] }), _jsxs("div", { className: "muscle-selectors", children: [renderGroupPicker(createFields.primaryMuscleGroups || [], (id) => setCreateFields((p) => {
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
                                                    }), 'Primärgruppen'), renderGroupPicker(createFields.secondaryMuscleGroups || [], (id) => setCreateFields((p) => {
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
                                                    }), 'Sekundärgruppen'), _jsxs("div", { className: "muscle-summary", children: ["Ausgew\u00E4hlt:", ' ', uniq([
                                                                ...(createFields.primaryMuscleGroups || []),
                                                                ...(createFields.secondaryMuscleGroups || []),
                                                            ])
                                                                .map((id) => nameForGroup(id))
                                                                .join(', ') || '–'] })] })] }), _jsx("div", { style: { display: 'flex', gap: '0.5rem' }, children: _jsx("button", { className: "ghost btn-small", disabled: creatingDevice, onClick: createDevice, children: creatingDevice ? 'Erstelle…' : 'Gerät anlegen' }) })] }), _jsxs("div", { style: { display: 'flex', gap: '0.6rem', alignItems: 'center', marginBottom: '0.4rem' }, children: [_jsx("span", { className: "muted small", children: "Sortierung:" }), _jsx("button", { className: `ghost btn-small ${deviceSort === 'name' ? 'active' : ''}`, onClick: () => setDeviceSort('name'), children: "Name (A\u2013Z)" }), _jsx("button", { className: `ghost btn-small ${deviceSort === 'id' ? 'active' : ''}`, onClick: () => setDeviceSort('id'), children: "ID (1\u2013\u221E)" }), _jsx("button", { className: "ghost btn-small", disabled: fixingIds, onClick: repairMissingDeviceIds, children: fixingIds ? 'Repariere IDs…' : 'IDs reparieren' })] }), _jsx("div", { className: "device-list", children: devices
                                    .slice()
                                    .sort((a, b) => {
                                    if (deviceSort === 'id') {
                                        const aId = typeof a.dataId === 'number' ? a.dataId : Number(a.dataId);
                                        const bId = typeof b.dataId === 'number' ? b.dataId : Number(b.dataId);
                                        if (Number.isFinite(aId) && Number.isFinite(bId))
                                            return aId - bId;
                                        if (Number.isFinite(aId))
                                            return -1;
                                        if (Number.isFinite(bId))
                                            return 1;
                                        return 0;
                                    }
                                    const aName = (a.name || '').toLowerCase();
                                    const bName = (b.name || '').toLowerCase();
                                    return aName.localeCompare(bName);
                                })
                                    .map((d) => {
                                    const isEditing = editingDeviceId === d.id;
                                    return (_jsxs("div", { className: "device-row", children: [_jsxs("div", { className: "device-row-main", children: [_jsxs("div", { children: [_jsx("strong", { children: d.name || d.id }), d.description ? (_jsxs("span", { className: "muted small", style: { marginLeft: '0.45rem' }, children: ["\u2022 ", d.description] })) : null, _jsxs("div", { className: "muted small", children: [d.active === false ? 'Deaktiviert' : 'Aktiv', " ", d.isMulti ? '• multi' : '', ' ', d.muscleGroups?.length
                                                                        ? `• ${d.muscleGroups.map((id) => nameForGroup(id)).join(', ')}`
                                                                        : '', ' ', _jsxs("span", { className: "mono", children: ["\u2022 Doc-ID: ", d.id] }), d.dataId !== undefined && d.dataId !== null && d.dataId !== '' ? (_jsxs("span", { className: "mono", children: [" \u2022 Daten-ID: ", String(d.dataId)] })) : null] })] }), _jsxs("div", { className: "device-actions", children: [_jsx("button", { className: "ghost btn-small", disabled: !!savingDevice, onClick: () => startEdit(d), children: "Bearbeiten" }), _jsx("button", { className: "ghost btn-small", disabled: !!savingDevice, onClick: () => toggleDeviceActive(d.id, d.active), children: d.active === false ? 'Aktivieren' : 'Deaktivieren' })] })] }), isEditing && (_jsxs("div", { className: "device-edit-grid", children: [_jsxs("label", { children: ["Name", _jsx("input", { className: "input", value: editFields.name || '', onChange: (e) => setEditFields((p) => ({ ...p, name: e.target.value })) })] }), _jsxs("label", { children: ["Description", _jsx("input", { className: "input", value: editFields.description || '', onChange: (e) => setEditFields((p) => ({ ...p, description: e.target.value })) })] }), _jsxs("label", { children: ["NFC-Code", _jsxs("div", { style: { display: 'flex', gap: '0.5rem' }, children: [_jsx("input", { className: "input", value: editFields.nfcCode || '', onChange: (e) => setEditFields((p) => ({ ...p, nfcCode: e.target.value })) }), _jsx("button", { type: "button", className: "ghost btn-small", onClick: () => setEditFields((p) => ({ ...p, nfcCode: generateNfcCode() })), children: "NFC neu" })] })] }), _jsxs("label", { className: "inline-check", children: [_jsx("input", { type: "checkbox", checked: !!editFields.isMulti, onChange: (e) => setEditFields((p) => ({ ...p, isMulti: e.target.checked })) }), "multi"] }), _jsxs("div", { className: "muscle-selectors", children: [renderGroupPicker(editFields.primaryMuscleGroups || [], (id) => setEditFields((p) => {
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
                                                            }), 'Primärgruppen'), renderGroupPicker(editFields.secondaryMuscleGroups || [], (id) => setEditFields((p) => {
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
                                                            }), 'Sekundärgruppen'), _jsxs("div", { className: "muscle-summary", children: ["Ausgew\u00E4hlt:", ' ', uniq([
                                                                        ...(editFields.primaryMuscleGroups || []),
                                                                        ...(editFields.secondaryMuscleGroups || []),
                                                                    ])
                                                                        .map((id) => nameForGroup(id))
                                                                        .join(', ') || '–'] })] }), _jsxs("div", { className: "device-actions", children: [_jsx("button", { className: "ghost btn-small", disabled: !!savingDevice, onClick: saveEdit, children: "Speichern" }), _jsx("button", { className: "ghost btn-small", onClick: () => setEditingDeviceId(null), children: "Abbrechen" })] })] }))] }, d.id));
                                }) })] }), _jsxs(Card, { title: "Muskelgruppen", children: [_jsxs("div", { style: { display: 'flex', justifyContent: 'space-between', gap: '0.6rem', flexWrap: 'wrap' }, children: [_jsxs("span", { className: "muted small", children: [muscleGroups.length, " Gruppen \u00B7 ", muscleGroups.filter((g) => !g.name).length, " ohne Namen"] }), _jsxs("div", { style: { display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }, children: [_jsx("button", { className: "ghost btn-small", onClick: seedDefaultMuscleGroups, disabled: muscleGroups.length > 0 || seedingGroups, children: seedingGroups ? 'Anlegen…' : 'Standard anlegen' }), _jsx("button", { className: "ghost btn-small", onClick: () => setEditingMuscleGroups((v) => !v), children: editingMuscleGroups ? 'Schließen' : 'Bearbeiten' })] })] }), editingMuscleGroups && (_jsx("div", { className: "mg-list", children: muscleGroups
                                    .slice()
                                    .sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id))
                                    .map((g) => (_jsxs("div", { className: "mg-row", children: [_jsx("div", { className: "mono", children: g.id }), _jsx("input", { className: "input", placeholder: "Name anzeigen", value: muscleGroupEdits[g.id] ?? '', onChange: (e) => setMuscleGroupEdits((prev) => ({ ...prev, [g.id]: e.target.value })) }), _jsx("button", { className: "ghost btn-small", onClick: () => saveMuscleGroupName(g.id), children: "Speichern" })] }, g.id))) }))] }), _jsxs(Card, { title: "Gym Codes", children: [_jsx("div", { style: { display: 'flex', justifyContent: 'flex-end', marginBottom: '0.6rem' }, children: _jsx("button", { className: "ghost btn-small", disabled: creatingCode, onClick: createGymCode, children: creatingCode ? 'Erstelle…' : 'Neuen Code erstellen' }) }), codes.length === 0 && _jsx("p", { className: "muted", children: "Keine Codes gefunden." }), codes.length > 0 && (_jsxs("table", { className: "table", children: [_jsx("thead", { children: _jsxs("tr", { children: [_jsx("th", { children: "Code" }), _jsx("th", { children: "Aktiv" }), _jsx("th", { children: "Expires" }), _jsx("th", { children: "CreatedBy" }), _jsx("th", { children: "Aktionen" })] }) }), _jsx("tbody", { children: codes.map((c) => (_jsxs("tr", { children: [_jsx("td", { className: "mono", children: c.code || c.id }), _jsx("td", { children: c.isActive ? 'Ja' : 'Nein' }), _jsx("td", { children: c.expiresAt ? formatDate(c.expiresAt) : '–' }), _jsx("td", { children: c?.createdBy || '–' }), _jsx("td", { children: c.isActive ? (_jsxs("div", { style: { display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }, children: [_jsx("button", { className: "ghost btn-small", disabled: updatingCode === c.id, onClick: () => deactivateGymCode(c.id), children: "Deaktivieren" }), _jsx("button", { className: "ghost btn-small", disabled: updatingCode === c.id, onClick: () => rotateGymCode(c.id), children: "Rotieren" })] })) : ('–') })] }, c.id))) })] }))] }), _jsxs(Card, { title: "Umfragen", children: [_jsxs("div", { className: "form", style: { marginBottom: '1rem' }, children: [_jsxs("label", { children: ["Titel", _jsx("input", { className: "input", placeholder: "z.B. Welche Ger\u00E4te sollen wir erg\u00E4nzen?", value: surveyTitle, onChange: (e) => setSurveyTitle(e.target.value) })] }), _jsxs("label", { children: ["Optionen (kommagetrennt)", _jsx("input", { className: "input", placeholder: "Ger\u00E4t A, Ger\u00E4t B, Ger\u00E4t C", value: surveyOptions, onChange: (e) => setSurveyOptions(e.target.value) })] }), _jsx("div", { children: _jsx("button", { className: "ghost btn-small", disabled: creatingSurvey, onClick: createSurvey, children: creatingSurvey ? 'Erstelle…' : 'Umfrage anlegen' }) })] }), surveys.length === 0 && _jsx("p", { className: "muted", children: "Keine Umfragen gefunden." }), surveys.length > 0 && (_jsxs("table", { className: "table", children: [_jsx("thead", { children: _jsxs("tr", { children: [_jsx("th", { children: "Titel" }), _jsx("th", { children: "Status" }), _jsx("th", { children: "Optionen" }), _jsx("th", { children: "Aktionen" })] }) }), _jsx("tbody", { children: surveys.map((s) => (_jsxs("tr", { children: [_jsx("td", { children: s.title || '–' }), _jsx("td", { children: s.status || '–' }), _jsx("td", { children: s.options?.join(', ') || '–' }), _jsxs("td", { children: [_jsxs("div", { style: { display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }, children: [_jsx("button", { className: "ghost btn-small", onClick: () => loadSurveyResults(s.id, s.options || []), children: "Ergebnisse" }), s.status !== 'abgeschlossen' && (_jsx("button", { className: "ghost btn-small", disabled: closingSurvey === s.id, onClick: () => closeSurvey(s.id), children: "Schlie\u00DFen" }))] }), surveyResults[s.id] && (_jsx("div", { className: "muted small", style: { marginTop: '0.4rem' }, children: Object.entries(surveyResults[s.id])
                                                                .map(([opt, count]) => `${opt}: ${count}`)
                                                                .join(' · ') }))] })] }, s.id))) })] }))] }), _jsxs(Card, { title: "Feedback (letzte 50)", children: [feedback.length === 0 && _jsx("p", { className: "muted", children: "Kein Feedback gefunden." }), feedback.length > 0 && (_jsxs("table", { className: "table", children: [_jsx("thead", { children: _jsxs("tr", { children: [_jsx("th", { children: "User" }), _jsx("th", { children: "Message" }), _jsx("th", { children: "Created" })] }) }), _jsx("tbody", { children: feedback.map((f) => (_jsxs("tr", { children: [_jsx("td", { className: "mono", children: f.userId || '–' }), _jsx("td", { children: f.message || '–' }), _jsx("td", { children: f.createdAt ? formatDate(f.createdAt) : '–' })] }, f.id))) })] }))] })] }))] }));
}
function formatDate(val) {
    if (!val)
        return '';
    if (typeof val === 'string')
        return new Date(val).toLocaleString();
    if (val.toDate)
        return val.toDate().toLocaleString();
    return '';
}
