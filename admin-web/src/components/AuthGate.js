import { jsx as _jsx, jsxs as _jsxs, Fragment as _Fragment } from "react/jsx-runtime";
import { useEffect, useState } from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';
import { auth, refreshClaims, ensureUserDoc } from '../firebase';
import { onAuthStateChanged, onIdTokenChanged } from 'firebase/auth';
export function AuthGate({ children }) {
    const [user, setUser] = useState(null);
    const [tokenResult, setTokenResult] = useState(null);
    const [checking, setChecking] = useState(true);
    const [error, setError] = useState(null);
    const location = useLocation();
    const navigate = useNavigate();
    useEffect(() => {
        const unsubAuth = onAuthStateChanged(auth, (u) => {
            setUser(u);
            if (!u) {
                setTokenResult(null);
                setChecking(false);
                return;
            }
            refreshClaims()
                .catch((e) => setError(e?.message || 'Auth-Fehler'))
                .finally(() => setChecking(false));
        }, (e) => {
            setError(e?.message || 'Auth-Fehler');
            setChecking(false);
        });
        const unsubToken = onIdTokenChanged(auth, async (u) => {
            if (!u) {
                setTokenResult(null);
                return;
            }
            const res = await u.getIdTokenResult();
            setTokenResult(res);
            // Ensure user doc exists
            const role = res.claims?.role || null;
            await ensureUserDoc(u.uid, u.email, typeof role === 'string' ? role : null);
        });
        return () => {
            unsubAuth();
            unsubToken();
        };
    }, []);
    if (checking) {
        return _jsx("div", { className: "page-loading", children: "Lade\u2026" });
    }
    if (!user || !tokenResult) {
        return _jsx(Navigate, { to: "/login", state: { from: location }, replace: true });
    }
    const claims = tokenResult.claims || {};
    const role = claims.role;
    if (role !== 'global_admin' && role !== 'gym_admin') {
        return (_jsxs("div", { className: "page-denied", children: [_jsx("p", { children: "Kein Zugriff. Bitte mit einem Admin-Account anmelden." }), _jsx("button", { onClick: () => navigate('/login'), children: "Zur\u00FCck zum Login" })] }));
    }
    return _jsx(_Fragment, { children: children });
}
