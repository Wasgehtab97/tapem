import { jsx as _jsx, jsxs as _jsxs, Fragment as _Fragment } from "react/jsx-runtime";
import { useEffect, useMemo, useState } from 'react';
import { collection, getDocs, limit, query, where, updateDoc, doc, getDoc, setDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { getDownloadURL, getStorage, ref as storageRef } from 'firebase/storage';
import { db, auth } from '../firebase';
import { sendPasswordResetEmail } from 'firebase/auth';
import { useActiveGym } from '../hooks/useActiveGym';
export function Users() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const { activeGym } = useActiveGym();
    const [search, setSearch] = useState('');
    const [roleFilter, setRoleFilter] = useState('');
    const [saving, setSaving] = useState(null);
    const [extraUser, setExtraUser] = useState(null);
    const [resetting, setResetting] = useState(null);
    const [avatarUser, setAvatarUser] = useState(null);
    const [avatarCatalog, setAvatarCatalog] = useState([]);
    const [avatarOwned, setAvatarOwned] = useState(new Set());
    const [avatarUrls, setAvatarUrls] = useState({});
    const [avatarLoading, setAvatarLoading] = useState(false);
    const [avatarError, setAvatarError] = useState(null);
    const [avatarFailed, setAvatarFailed] = useState(new Set());
    useEffect(() => {
        async function load() {
            try {
                if (activeGym?.id) {
                    const [gymSnap, globalSnap, membershipSnap] = await Promise.all([
                        getDocs(query(collection(db, 'users'), where('gymCodes', 'array-contains', activeGym.id), limit(50))),
                        getDocs(query(collection(db, 'users'), where('role', '==', 'global_admin'), limit(50))),
                        getDocs(query(collection(db, 'gyms', activeGym.id, 'users'), limit(200))),
                    ]);
                    const membershipRoles = new Map();
                    membershipSnap.docs.forEach((doc) => {
                        const role = doc.data()?.role;
                        if (typeof role === 'string' && role) {
                            membershipRoles.set(doc.id, role);
                        }
                    });
                    const gymItems = gymSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
                    const globalItems = globalSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
                    const merged = new Map();
                    gymItems.forEach((u) => merged.set(u.id, { ...u, gymRole: membershipRoles.get(u.id) }));
                    globalItems.forEach((u) => {
                        const existing = merged.get(u.id);
                        if (existing) {
                            merged.set(u.id, { ...existing, ...u, gymRole: membershipRoles.get(u.id) || existing.gymRole });
                            return;
                        }
                        merged.set(u.id, { ...u, gymRole: membershipRoles.get(u.id) });
                    });
                    setUsers(Array.from(merged.values()));
                }
                else {
                    const snap = await getDocs(query(collection(db, 'users'), limit(50)));
                    const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
                    setUsers(items);
                }
            }
            catch (err) {
                setError(err?.message || 'Konnte User nicht laden');
            }
            finally {
                setLoading(false);
            }
        }
        load();
    }, [activeGym?.id]);
    useEffect(() => {
        const term = search.trim();
        if (!term) {
            setExtraUser(null);
            return;
        }
        getDoc(doc(db, 'users', term))
            .then((snap) => {
            if (snap.exists()) {
                setExtraUser({ id: snap.id, ...snap.data() });
            }
            else {
                setExtraUser(null);
            }
        })
            .catch(() => setExtraUser(null));
    }, [search]);
    const filtered = useMemo(() => {
        const term = search.toLowerCase();
        const base = users.filter((u) => {
            if (!activeGym?.id)
                return false;
            const effectiveRole = u.role === 'global_admin' || u.role === 'gym_admin' ? u.role : u.gymRole || u.role || 'member';
            const matchesGym = (u.gymCodes || []).includes(activeGym.id);
            const matchesTerm = !term ||
                u.id.toLowerCase().includes(term) ||
                (u.email || '').toLowerCase().includes(term) ||
                (u.username || '').toLowerCase().includes(term);
            const matchesRole = !roleFilter || effectiveRole.toLowerCase() === roleFilter;
            return matchesGym && matchesTerm && matchesRole;
        });
        if (extraUser) {
            const matchesGym = !!activeGym?.id && (extraUser.gymCodes || []).includes(activeGym.id);
            const extraEffectiveRole = extraUser.role === 'global_admin' || extraUser.role === 'gym_admin'
                ? extraUser.role
                : extraUser.gymRole || extraUser.role || 'member';
            const matchesRole = !roleFilter || extraEffectiveRole.toLowerCase() === roleFilter;
            if (matchesGym && matchesRole && !base.find((u) => u.id === extraUser.id)) {
                return [...base, extraUser];
            }
        }
        return base;
    }, [users, search, roleFilter, extraUser, activeGym?.id]);
    async function handleRoleChange(uid, nextRole) {
        if (!activeGym?.id)
            return;
        setSaving(uid);
        try {
            await updateDoc(doc(db, 'gyms', activeGym.id, 'users', uid), { role: nextRole });
            setUsers((prev) => prev.map((u) => (u.id === uid ? { ...u, gymRole: nextRole } : u)));
            setExtraUser((prev) => (prev && prev.id === uid ? { ...prev, gymRole: nextRole } : prev));
        }
        catch (err) {
            setError(err?.message || 'Konnte Rolle nicht setzen');
        }
        finally {
            setSaving(null);
        }
    }
    async function handlePasswordReset(email) {
        if (!email)
            return;
        setResetting(email);
        try {
            await sendPasswordResetEmail(auth, email);
            alert(`Passwort-Reset-Link gesendet an ${email}`);
        }
        catch (err) {
            alert(err?.message || 'Konnte Reset-Link nicht senden');
        }
        finally {
            setResetting(null);
        }
    }
    function normalizeAvatarKey(key, gymId) {
        if (!key)
            return key;
        if (key.includes('/'))
            return key;
        if (!gymId)
            return `global/${key}`;
        return `${gymId}/${key}`;
    }
    function localAvatarPath(key) {
        return `/avatars/${key}.png`;
    }
    function inventoryDocId(key) {
        return key.replaceAll('/', '__');
    }
    async function loadAvatarCatalog() {
        if (!activeGym?.id)
            return;
        setAvatarLoading(true);
        setAvatarError(null);
        try {
            const manifestRes = await fetch('/avatars/manifest.json');
            if (manifestRes.ok) {
                const manifest = await manifestRes.json();
                const gymId = activeGym.id;
                const items = [];
                (manifest.global || []).forEach((name) => {
                    items.push({
                        id: `global/${name}`,
                        name,
                        scope: 'global',
                        isActive: true,
                    });
                });
                (manifest.gyms?.[gymId] || []).forEach((name) => {
                    items.push({
                        id: `${gymId}/${name}`,
                        name,
                        scope: 'gym',
                        isActive: true,
                    });
                });
                items.sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id));
                setAvatarCatalog(items);
                setAvatarLoading(false);
                return;
            }
            const [globalSnap, gymSnap] = await Promise.all([
                getDocs(query(collection(db, 'catalogAvatarsGlobal'), where('isActive', '==', true), limit(200))),
                getDocs(query(collection(db, 'gyms', activeGym.id, 'avatarCatalog'), where('isActive', '==', true), limit(200))),
            ]);
            const items = [
                ...globalSnap.docs.map((d) => ({ id: d.id, ...d.data(), scope: 'global' })),
                ...gymSnap.docs.map((d) => ({ id: d.id, ...d.data(), scope: 'gym' })),
            ];
            items.sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id));
            setAvatarCatalog(items);
            const storage = getStorage();
            const urls = {};
            await Promise.all(items.map(async (item) => {
                if (item.assetUrl) {
                    urls[item.id] = item.assetUrl;
                    return;
                }
                if (item.assetStoragePath) {
                    try {
                        urls[item.id] = await getDownloadURL(storageRef(storage, item.assetStoragePath));
                    }
                    catch (e) {
                        // ignore missing assets
                    }
                }
            }));
            setAvatarUrls(urls);
        }
        catch (err) {
            setAvatarError(err?.message || 'Konnte Avatar-Katalog nicht laden');
        }
        finally {
            setAvatarLoading(false);
        }
    }
    async function loadUserInventory(uid) {
        if (!uid)
            return;
        try {
            const snap = await getDocs(query(collection(db, 'users', uid, 'avatarInventory'), limit(400)));
            const keys = snap.docs.map((d) => {
                const data = d.data();
                const raw = data?.key || d.id.replaceAll('__', '/');
                return normalizeAvatarKey(raw, activeGym?.id);
            });
            setAvatarOwned(new Set(keys));
        }
        catch (err) {
            setAvatarError(err?.message || 'Konnte Inventar nicht laden');
        }
    }
    async function openAvatarModal(user) {
        if (!activeGym?.id)
            return;
        setAvatarUser(user);
        setAvatarError(null);
        await Promise.all([loadAvatarCatalog(), loadUserInventory(user.id)]);
    }
    async function assignAvatar(userId, key, scope) {
        if (!activeGym?.id)
            return;
        const normalized = normalizeAvatarKey(key, scope === 'gym' ? activeGym.id : null);
        const ref = doc(db, 'users', userId, 'avatarInventory', inventoryDocId(normalized));
        await setDoc(ref, {
            key: normalized,
            source: 'admin/manual',
            createdAt: serverTimestamp(),
            ...(scope === 'gym' ? { gymId: activeGym.id } : {}),
        }, { merge: true });
        setAvatarOwned((prev) => new Set(prev).add(normalized));
    }
    async function removeAvatar(userId, key) {
        const ref = doc(db, 'users', userId, 'avatarInventory', inventoryDocId(key));
        await deleteDoc(ref);
        setAvatarOwned((prev) => {
            const next = new Set(prev);
            next.delete(key);
            return next;
        });
    }
    return (_jsxs("div", { className: "page", children: [_jsx("h1", { children: "User" }), activeGym?.id && _jsxs("p", { className: "muted", children: ["Gefiltert auf Gym: ", activeGym.name || activeGym.id] }), _jsx("div", { className: "card list-card", style: { display: 'grid', gap: '0.5rem' }, children: _jsxs("div", { style: { display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }, children: [_jsx("input", { className: "input", placeholder: "Suche nach UID, E-Mail, Username", value: search, onChange: (e) => setSearch(e.target.value), style: { minWidth: '260px' } }), _jsxs("select", { className: "input", value: roleFilter, onChange: (e) => setRoleFilter(e.target.value), style: { minWidth: '160px' }, children: [_jsx("option", { value: "", children: "Alle Rollen" }), _jsx("option", { value: "member", children: "member" }), _jsx("option", { value: "coach", children: "coach" }), _jsx("option", { value: "admin", children: "admin" }), _jsx("option", { value: "gymowner", children: "gymowner" }), _jsx("option", { value: "global_admin", children: "global_admin" }), _jsx("option", { value: "gym_admin", children: "gym_admin" })] }), _jsxs("span", { className: "muted", children: [filtered.length, " User angezeigt"] })] }) }), loading && _jsx("p", { className: "muted", children: "Lade\u2026" }), error && _jsx("p", { className: "error", children: error }), !loading && !error && (_jsx("div", { className: "card list-card", children: _jsxs("table", { className: "table", children: [_jsx("thead", { children: _jsxs("tr", { children: [_jsx("th", { children: "UID" }), _jsx("th", { children: "Email" }), _jsx("th", { children: "Username" }), _jsx("th", { children: "Gyms" }), _jsx("th", { children: "Role" }), _jsx("th", { children: "Aktion" })] }) }), _jsx("tbody", { children: filtered.map((u) => (_jsxs("tr", { children: [_jsx("td", { className: "mono", children: u.id }), _jsx("td", { children: u.email || '–' }), _jsx("td", { children: u.username || '–' }), _jsx("td", { children: u.gymCodes?.join(', ') || (u.role === 'global_admin' ? 'alle' : '–') }), _jsx("td", { children: u.role === 'global_admin' || u.role === 'gym_admin'
                                            ? u.role
                                            : u.gymRole || u.role || 'member' }), _jsx("td", { children: _jsxs("div", { style: { display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }, children: [u.role === 'global_admin' || u.role === 'gym_admin' ? (_jsx("span", { className: "badge", children: u.role })) : (_jsxs("select", { className: "input", disabled: !activeGym?.id || !!saving, value: u.gymRole || u.role || 'member', onChange: (e) => handleRoleChange(u.id, e.target.value), children: [_jsx("option", { value: "member", children: "member" }), _jsx("option", { value: "coach", children: "coach" }), _jsx("option", { value: "admin", children: "admin" }), _jsx("option", { value: "gymowner", children: "gymowner" })] })), _jsx("button", { className: "ghost btn-small", disabled: !u.email || resetting === u.email, onClick: () => handlePasswordReset(u.email), children: "Reset-Link" }), _jsx("button", { className: "ghost btn-small", disabled: !activeGym?.id, onClick: () => openAvatarModal(u), children: "Symbole" })] }) })] }, u.id))) })] }) })), avatarUser && (_jsx("div", { className: "modal-backdrop", onClick: () => setAvatarUser(null), children: _jsxs("div", { className: "modal-card", onClick: (e) => e.stopPropagation(), children: [_jsxs("div", { className: "modal-header", children: [_jsxs("h2", { children: ["Symbole f\u00FCr ", avatarUser.email || avatarUser.id] }), _jsx("button", { className: "ghost btn-small", onClick: () => setAvatarUser(null), children: "Schlie\u00DFen" })] }), avatarLoading && _jsx("p", { className: "muted", children: "Lade\u2026" }), avatarError && _jsx("p", { className: "error", children: avatarError }), !avatarLoading && (_jsxs(_Fragment, { children: [_jsxs("div", { className: "modal-section", children: [_jsx("h3", { children: "Verf\u00FCgbare Symbole" }), _jsxs("div", { className: "avatar-grid", children: [avatarCatalog
                                                    .filter((a) => !avatarOwned.has(normalizeAvatarKey(a.id, a.scope === 'gym' ? activeGym?.id : null)))
                                                    .map((a) => {
                                                    const normalized = normalizeAvatarKey(a.id, a.scope === 'gym' ? activeGym?.id : null);
                                                    const failed = avatarFailed.has(a.id);
                                                    const src = avatarUrls[a.id] || localAvatarPath(normalized);
                                                    return (_jsxs("button", { className: "avatar-card", onClick: () => assignAvatar(avatarUser.id, a.id, a.scope), children: [!failed ? (_jsx("img", { src: src, alt: a.name || a.id, onError: () => setAvatarFailed((prev) => new Set(prev).add(a.id)) })) : (_jsx("div", { className: "avatar-fallback", children: (a.name || a.id).slice(0, 2) })), _jsx("span", { children: a.name || a.id })] }, a.id));
                                                }), avatarCatalog.length === 0 && _jsx("p", { className: "muted", children: "Keine Symbole gefunden." })] })] }), _jsxs("div", { className: "modal-section", children: [_jsx("h3", { children: "Zugewiesene Symbole" }), _jsxs("div", { className: "avatar-grid", children: [Array.from(avatarOwned).map((key) => {
                                                    const failed = avatarFailed.has(key);
                                                    const src = localAvatarPath(key);
                                                    return (_jsxs("div", { className: "avatar-card", children: [!failed ? (_jsx("img", { src: src, alt: key, onError: () => setAvatarFailed((prev) => new Set(prev).add(key)) })) : (_jsx("div", { className: "avatar-fallback", children: key.split('/').pop()?.slice(0, 2) })), _jsx("span", { children: key }), _jsx("button", { className: "ghost btn-small", onClick: () => removeAvatar(avatarUser.id, key), children: "Entfernen" })] }, key));
                                                }), avatarOwned.size === 0 && _jsx("p", { className: "muted", children: "Noch keine Symbole zugewiesen." })] })] })] }))] }) }))] }));
}
