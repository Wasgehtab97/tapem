import { ReactNode, useEffect, useState } from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';
import { auth, refreshClaims, ensureUserDoc } from '../firebase';
import { onAuthStateChanged, onIdTokenChanged, User, IdTokenResult } from 'firebase/auth';

interface Props {
  children: ReactNode;
}

export function AuthGate({ children }: Props) {
  const [user, setUser] = useState<User | null>(null);
  const [tokenResult, setTokenResult] = useState<IdTokenResult | null>(null);
  const [checking, setChecking] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    const unsubAuth = onAuthStateChanged(
      auth,
      (u) => {
        setUser(u);
        if (!u) {
          setTokenResult(null);
          setChecking(false);
          return;
        }
        refreshClaims()
          .catch((e) => setError(e?.message || 'Auth-Fehler'))
          .finally(() => setChecking(false));
      },
      (e) => {
        setError(e?.message || 'Auth-Fehler');
        setChecking(false);
      }
    );
    const unsubToken = onIdTokenChanged(auth, async (u) => {
      if (!u) {
        setTokenResult(null);
        return;
      }
      const res = await u.getIdTokenResult();
      setTokenResult(res);
      // Ensure user doc exists
      const role = (res.claims as any)?.role || null;
      await ensureUserDoc(u.uid, u.email, typeof role === 'string' ? role : null);
    });
    return () => {
      unsubAuth();
      unsubToken();
    };
  }, []);

  if (checking) {
    return <div className="page-loading">Lade…</div>;
  }

  if (!user || !tokenResult) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  const claims = tokenResult.claims || {};
  const role = claims.role;
  if (role !== 'global_admin' && role !== 'gym_admin') {
    return (
      <div className="page-denied">
        <p>Kein Zugriff. Bitte mit einem Admin-Account anmelden.</p>
        <button onClick={() => navigate('/login')}>Zurück zum Login</button>
      </div>
    );
  }

  return <>{children}</>;
}
