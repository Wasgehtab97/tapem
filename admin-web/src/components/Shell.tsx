import { NavLink, useNavigate } from 'react-router-dom';
import { ReactNode, useEffect, useState } from 'react';
import { auth, db } from '../firebase';
import { signOut } from 'firebase/auth';
import { collection, getDocs, limit, query } from 'firebase/firestore';
import { useActiveGym } from '../hooks/useActiveGym';

interface Props {
  children: ReactNode;
}

export function Shell({ children }: Props) {
  const navigate = useNavigate();
  const { activeGym, setActiveGym, clearActiveGym } = useActiveGym();
  const [gyms, setGyms] = useState<{ id: string; name?: string }[]>([]);
  const [loadingGyms, setLoadingGyms] = useState(false);

  async function handleLogout() {
    await signOut(auth);
    navigate('/login', { replace: true });
  }

  useEffect(() => {
    async function loadGyms() {
      setLoadingGyms(true);
      try {
        const snap = await getDocs(query(collection(db, 'gyms'), limit(50)));
        setGyms(snap.docs.map((d) => ({ id: d.id, ...(d.data() as any) })));
      } finally {
        setLoadingGyms(false);
      }
    }
    loadGyms();
  }, []);

  useEffect(() => {
    function handleGymCreated(event: Event) {
      const detail = (event as CustomEvent<{ id: string; name?: string }>).detail;
      if (!detail?.id) return;
      setGyms((prev) => {
        if (prev.some((g) => g.id === detail.id)) return prev;
        return [{ id: detail.id, name: detail.name }, ...prev];
      });
    }
    window.addEventListener('gym-created', handleGymCreated as EventListener);
    return () => window.removeEventListener('gym-created', handleGymCreated as EventListener);
  }, []);

  return (
    <div className="shell">
      <header className="shell-header">
        <div className="logo">tapem Admin</div>
        <nav className="shell-nav">
          <NavLink to="/" end>
            Dashboard
          </NavLink>
          {activeGym?.id ? (
            <NavLink to={`/gyms/${activeGym.id}`}>Gym</NavLink>
          ) : (
            <span className="nav-disabled">Gym</span>
          )}
          {activeGym?.id ? <NavLink to="/users">User</NavLink> : <span className="nav-disabled">User</span>}
        </nav>
        <div className="shell-actions">
          <label className="gym-select">
            <span>Gym</span>
            <select
              value={activeGym?.id || ''}
              onChange={(e) => {
                const id = e.target.value;
                if (!id) {
                  clearActiveGym();
                  return;
                }
                const gym = gyms.find((g) => g.id === id);
                setActiveGym({ id, name: gym?.name || null });
              }}
            >
              <option value="">{loadingGyms ? 'Lade…' : 'Alle'}</option>
              {gyms.map((g) => (
                <option key={g.id} value={g.id}>
                  {g.name || g.id}
                </option>
              ))}
            </select>
          </label>
          <button className="ghost" onClick={handleLogout}>
            Logout
          </button>
        </div>
      </header>
      <main className="shell-main">{children}</main>
    </div>
  );
}
