import { useEffect, useMemo, useState } from 'react';
import { collection, getDocs, limit, query, where, updateDoc, doc, getDoc, setDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { getDownloadURL, getStorage, ref as storageRef } from 'firebase/storage';
import { db, auth } from '../firebase';
import { sendPasswordResetEmail } from 'firebase/auth';
import { useActiveGym } from '../hooks/useActiveGym';

interface UserRow {
  id: string;
  email?: string;
  username?: string;
  gymCodes?: string[];
  role?: string;
  gymRole?: string;
}

interface AvatarCatalogItem {
  id: string;
  name?: string;
  description?: string;
  assetUrl?: string;
  assetStoragePath?: string;
  isActive?: boolean;
  tier?: string;
  scope: 'global' | 'gym';
}

export function Users() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { activeGym } = useActiveGym();
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [saving, setSaving] = useState<string | null>(null);
  const [extraUser, setExtraUser] = useState<UserRow | null>(null);
  const [resetting, setResetting] = useState<string | null>(null);
  const [avatarUser, setAvatarUser] = useState<UserRow | null>(null);
  const [avatarCatalog, setAvatarCatalog] = useState<AvatarCatalogItem[]>([]);
  const [avatarOwned, setAvatarOwned] = useState<Set<string>>(new Set());
  const [avatarUrls, setAvatarUrls] = useState<Record<string, string>>({});
  const [avatarLoading, setAvatarLoading] = useState(false);
  const [avatarError, setAvatarError] = useState<string | null>(null);
  const [avatarFailed, setAvatarFailed] = useState<Set<string>>(new Set());

  useEffect(() => {
    async function load() {
      try {
        if (activeGym?.id) {
          const [gymSnap, globalSnap, membershipSnap] = await Promise.all([
            getDocs(query(collection(db, 'users'), where('gymCodes', 'array-contains', activeGym.id), limit(50))),
            getDocs(query(collection(db, 'users'), where('role', '==', 'global_admin'), limit(50))),
            getDocs(query(collection(db, 'gyms', activeGym.id, 'users'), limit(200))),
          ]);
          const membershipRoles = new Map<string, string>();
          membershipSnap.docs.forEach((doc) => {
            const role = (doc.data() as any)?.role;
            if (typeof role === 'string' && role) {
              membershipRoles.set(doc.id, role);
            }
          });
          const gymItems = gymSnap.docs.map((d) => ({ id: d.id, ...(d.data() as any) }));
          const globalItems = globalSnap.docs.map((d) => ({ id: d.id, ...(d.data() as any) }));
          const merged = new Map<string, UserRow>();
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
        } else {
          const snap = await getDocs(query(collection(db, 'users'), limit(50)));
          const items = snap.docs.map((d) => ({ id: d.id, ...(d.data() as any) }));
          setUsers(items);
        }
      } catch (err: any) {
        setError(err?.message || 'Konnte User nicht laden');
      } finally {
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
          setExtraUser({ id: snap.id, ...(snap.data() as any) });
        } else {
          setExtraUser(null);
        }
      })
      .catch(() => setExtraUser(null));
  }, [search]);

  const filtered = useMemo(() => {
    const term = search.toLowerCase();
    const base = users.filter((u) => {
      if (!activeGym?.id) return false;
      const effectiveRole =
        u.role === 'global_admin' || u.role === 'gym_admin' ? u.role : u.gymRole || u.role || 'member';
      const matchesGym = (u.gymCodes || []).includes(activeGym.id);
      const matchesTerm =
        !term ||
        u.id.toLowerCase().includes(term) ||
        (u.email || '').toLowerCase().includes(term) ||
        (u.username || '').toLowerCase().includes(term);
      const matchesRole = !roleFilter || effectiveRole.toLowerCase() === roleFilter;
      return matchesGym && matchesTerm && matchesRole;
    });
    if (extraUser) {
      const matchesGym = !!activeGym?.id && (extraUser.gymCodes || []).includes(activeGym.id);
      const extraEffectiveRole =
        extraUser.role === 'global_admin' || extraUser.role === 'gym_admin'
          ? extraUser.role
          : extraUser.gymRole || extraUser.role || 'member';
      const matchesRole = !roleFilter || extraEffectiveRole.toLowerCase() === roleFilter;
      if (matchesGym && matchesRole && !base.find((u) => u.id === extraUser.id)) {
        return [...base, extraUser];
      }
    }
    return base;
  }, [users, search, roleFilter, extraUser, activeGym?.id]);

  async function handleRoleChange(uid: string, nextRole: string) {
    if (!activeGym?.id) return;
    setSaving(uid);
    try {
      await updateDoc(doc(db, 'gyms', activeGym.id, 'users', uid), { role: nextRole });
      setUsers((prev) => prev.map((u) => (u.id === uid ? { ...u, gymRole: nextRole } : u)));
      setExtraUser((prev) => (prev && prev.id === uid ? { ...prev, gymRole: nextRole } : prev));
    } catch (err: any) {
      setError(err?.message || 'Konnte Rolle nicht setzen');
    } finally {
      setSaving(null);
    }
  }

  async function handlePasswordReset(email?: string) {
    if (!email) return;
    setResetting(email);
    try {
      await sendPasswordResetEmail(auth, email);
      alert(`Passwort-Reset-Link gesendet an ${email}`);
    } catch (err: any) {
      alert(err?.message || 'Konnte Reset-Link nicht senden');
    } finally {
      setResetting(null);
    }
  }

  function normalizeAvatarKey(key: string, gymId?: string | null) {
    if (!key) return key;
    if (key.includes('/')) return key;
    if (!gymId) return `global/${key}`;
    return `${gymId}/${key}`;
  }

  function localAvatarPath(key: string) {
    return `/avatars/${key}.png`;
  }

  function inventoryDocId(key: string) {
    return key.replaceAll('/', '__');
  }

  async function loadAvatarCatalog() {
    if (!activeGym?.id) return;
    setAvatarLoading(true);
    setAvatarError(null);
    try {
      const manifestRes = await fetch('/avatars/manifest.json');
      if (manifestRes.ok) {
        const manifest = await manifestRes.json();
        const gymId = activeGym.id;
        const items: AvatarCatalogItem[] = [];
        (manifest.global || []).forEach((name: string) => {
          items.push({
            id: `global/${name}`,
            name,
            scope: 'global',
            isActive: true,
          });
        });
        (manifest.gyms?.[gymId] || []).forEach((name: string) => {
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
        getDocs(
          query(collection(db, 'gyms', activeGym.id, 'avatarCatalog'), where('isActive', '==', true), limit(200))
        ),
      ]);
      const items: AvatarCatalogItem[] = [
        ...globalSnap.docs.map((d) => ({ id: d.id, ...(d.data() as any), scope: 'global' as const })),
        ...gymSnap.docs.map((d) => ({ id: d.id, ...(d.data() as any), scope: 'gym' as const })),
      ];
      items.sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id));
      setAvatarCatalog(items);

      const storage = getStorage();
      const urls: Record<string, string> = {};
      await Promise.all(
        items.map(async (item) => {
          if (item.assetUrl) {
            urls[item.id] = item.assetUrl;
            return;
          }
          if (item.assetStoragePath) {
            try {
              urls[item.id] = await getDownloadURL(storageRef(storage, item.assetStoragePath));
            } catch (e) {
              // ignore missing assets
            }
          }
        })
      );
      setAvatarUrls(urls);
    } catch (err: any) {
      setAvatarError(err?.message || 'Konnte Avatar-Katalog nicht laden');
    } finally {
      setAvatarLoading(false);
    }
  }

  async function loadUserInventory(uid: string) {
    if (!uid) return;
    try {
      const snap = await getDocs(query(collection(db, 'users', uid, 'avatarInventory'), limit(400)));
      const keys = snap.docs.map((d) => {
        const data = d.data() as any;
        const raw = data?.key || d.id.replaceAll('__', '/');
        return normalizeAvatarKey(raw, activeGym?.id);
      });
      setAvatarOwned(new Set(keys));
    } catch (err: any) {
      setAvatarError(err?.message || 'Konnte Inventar nicht laden');
    }
  }

  async function openAvatarModal(user: UserRow) {
    if (!activeGym?.id) return;
    setAvatarUser(user);
    setAvatarError(null);
    await Promise.all([loadAvatarCatalog(), loadUserInventory(user.id)]);
  }

  async function assignAvatar(userId: string, key: string, scope: 'global' | 'gym') {
    if (!activeGym?.id) return;
    const normalized = normalizeAvatarKey(key, scope === 'gym' ? activeGym.id : null);
    const ref = doc(db, 'users', userId, 'avatarInventory', inventoryDocId(normalized));
    await setDoc(
      ref,
      {
        key: normalized,
        source: 'admin/manual',
        createdAt: serverTimestamp(),
        ...(scope === 'gym' ? { gymId: activeGym.id } : {}),
      },
      { merge: true }
    );
    setAvatarOwned((prev) => new Set(prev).add(normalized));
  }

  async function removeAvatar(userId: string, key: string) {
    const ref = doc(db, 'users', userId, 'avatarInventory', inventoryDocId(key));
    await deleteDoc(ref);
    setAvatarOwned((prev) => {
      const next = new Set(prev);
      next.delete(key);
      return next;
    });
  }

  return (
    <div className="page">
      <h1>User</h1>
      {activeGym?.id && <p className="muted">Gefiltert auf Gym: {activeGym.name || activeGym.id}</p>}
      <div className="card list-card" style={{ display: 'grid', gap: '0.5rem' }}>
        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
          <input
            className="input"
            placeholder="Suche nach UID, E-Mail, Username"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ minWidth: '260px' }}
          />
          <select
            className="input"
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            style={{ minWidth: '160px' }}
          >
            <option value="">Alle Rollen</option>
            <option value="member">member</option>
            <option value="coach">coach</option>
            <option value="admin">admin</option>
            <option value="global_admin">global_admin</option>
            <option value="gym_admin">gym_admin</option>
          </select>
          <span className="muted">{filtered.length} User angezeigt</span>
        </div>
      </div>
      {loading && <p className="muted">Lade…</p>}
      {error && <p className="error">{error}</p>}
      {!loading && !error && (
        <div className="card list-card">
          <table className="table">
            <thead>
              <tr>
                <th>UID</th>
                <th>Email</th>
                <th>Username</th>
                <th>Gyms</th>
                <th>Role</th>
                <th>Aktion</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((u) => (
                <tr key={u.id}>
                  <td className="mono">{u.id}</td>
                  <td>{u.email || '–'}</td>
                  <td>{u.username || '–'}</td>
                  <td>{u.gymCodes?.join(', ') || (u.role === 'global_admin' ? 'alle' : '–')}</td>
                <td>
                  {u.role === 'global_admin' || u.role === 'gym_admin'
                    ? u.role
                    : u.gymRole || u.role || 'member'}
                </td>
                  <td>
                    <div style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }}>
                      {u.role === 'global_admin' || u.role === 'gym_admin' ? (
                        <span className="badge">{u.role}</span>
                      ) : (
                        <select
                          className="input"
                          disabled={!activeGym?.id || !!saving}
                          value={u.gymRole || u.role || 'member'}
                          onChange={(e) => handleRoleChange(u.id, e.target.value)}
                        >
                          <option value="member">member</option>
                          <option value="coach">coach</option>
                          <option value="admin">admin</option>
                        </select>
                      )}
                      <button
                        className="ghost btn-small"
                        disabled={!u.email || resetting === u.email}
                        onClick={() => handlePasswordReset(u.email)}
                      >
                        Reset-Link
                      </button>
                      <button
                        className="ghost btn-small"
                        disabled={!activeGym?.id}
                        onClick={() => openAvatarModal(u)}
                      >
                        Symbole
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {avatarUser && (
        <div className="modal-backdrop" onClick={() => setAvatarUser(null)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Symbole für {avatarUser.email || avatarUser.id}</h2>
              <button className="ghost btn-small" onClick={() => setAvatarUser(null)}>
                Schließen
              </button>
            </div>
            {avatarLoading && <p className="muted">Lade…</p>}
            {avatarError && <p className="error">{avatarError}</p>}
            {!avatarLoading && (
              <>
                <div className="modal-section">
                  <h3>Verfügbare Symbole</h3>
                  <div className="avatar-grid">
                    {avatarCatalog
                      .filter((a) => !avatarOwned.has(normalizeAvatarKey(a.id, a.scope === 'gym' ? activeGym?.id : null)))
                      .map((a) => {
                        const normalized = normalizeAvatarKey(a.id, a.scope === 'gym' ? activeGym?.id : null);
                        const failed = avatarFailed.has(a.id);
                        const src = avatarUrls[a.id] || localAvatarPath(normalized);
                        return (
                          <button
                            key={a.id}
                            className="avatar-card"
                            onClick={() => assignAvatar(avatarUser.id, a.id, a.scope)}
                          >
                            {!failed ? (
                              <img
                                src={src}
                                alt={a.name || a.id}
                                onError={() =>
                                  setAvatarFailed((prev) => new Set(prev).add(a.id))
                                }
                              />
                            ) : (
                              <div className="avatar-fallback">{(a.name || a.id).slice(0, 2)}</div>
                            )}
                            <span>{a.name || a.id}</span>
                          </button>
                        );
                      })}
                    {avatarCatalog.length === 0 && <p className="muted">Keine Symbole gefunden.</p>}
                  </div>
                </div>
                <div className="modal-section">
                  <h3>Zugewiesene Symbole</h3>
                  <div className="avatar-grid">
                    {Array.from(avatarOwned).map((key) => {
                      const failed = avatarFailed.has(key);
                      const src = localAvatarPath(key);
                      return (
                        <div key={key} className="avatar-card">
                          {!failed ? (
                            <img
                              src={src}
                              alt={key}
                              onError={() =>
                                setAvatarFailed((prev) => new Set(prev).add(key))
                              }
                            />
                          ) : (
                            <div className="avatar-fallback">{key.split('/').pop()?.slice(0, 2)}</div>
                          )}
                          <span>{key}</span>
                          <button className="ghost btn-small" onClick={() => removeAvatar(avatarUser.id, key)}>
                            Entfernen
                          </button>
                        </div>
                      );
                    })}
                    {avatarOwned.size === 0 && <p className="muted">Noch keine Symbole zugewiesen.</p>}
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
