import { useEffect, useState } from 'react';
import { collection, getDocs, limit, query } from 'firebase/firestore';
import { db } from '../firebase';
import { Link } from 'react-router-dom';
import { useActiveGym } from '../hooks/useActiveGym';

interface GymSummary {
  id: string;
  name?: string;
  region?: string;
}

export function Gyms() {
  const [gyms, setGyms] = useState<GymSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { activeGym } = useActiveGym();

  useEffect(() => {
    async function load() {
      try {
        const q = query(collection(db, 'gyms'), limit(50));
        const snap = await getDocs(q);
        const items = snap.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
        setGyms(items);
      } catch (err: any) {
        setError(err?.message || 'Konnte Gyms nicht laden');
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  return (
    <div className="page">
      <h1>Gyms</h1>
      {loading && <p className="muted">Lade…</p>}
      {error && <p className="error">{error}</p>}
      {!loading && !error && (
        <div className="card list-card">
          <ul>
            {gyms.map((g) => {
              const isActive = activeGym?.id === g.id;
              return (
                <li key={g.id} className={isActive ? 'row-active' : ''}>
                  <Link to={`/gyms/${g.id}`}>{g.name || g.id}</Link> {g.region ? `– ${g.region}` : ''}
                  {isActive && <span className="badge">Aktiv</span>}
                  <span style={{ marginLeft: '0.75rem' }}>
                    <Link className="ghost btn-small" to={`/gyms/${g.id}`}>
                      Geräte & Codes
                    </Link>
                  </span>
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </div>
  );
}
