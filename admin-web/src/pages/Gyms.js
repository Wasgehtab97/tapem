import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useEffect, useState } from 'react';
import { collection, getDocs, limit, query } from 'firebase/firestore';
import { db } from '../firebase';
import { Link } from 'react-router-dom';
import { useActiveGym } from '../hooks/useActiveGym';
export function Gyms() {
    const [gyms, setGyms] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const { activeGym } = useActiveGym();
    useEffect(() => {
        async function load() {
            try {
                const q = query(collection(db, 'gyms'), limit(50));
                const snap = await getDocs(q);
                const items = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
                setGyms(items);
            }
            catch (err) {
                setError(err?.message || 'Konnte Gyms nicht laden');
            }
            finally {
                setLoading(false);
            }
        }
        load();
    }, []);
    return (_jsxs("div", { className: "page", children: [_jsx("h1", { children: "Gyms" }), loading && _jsx("p", { className: "muted", children: "Lade\u2026" }), error && _jsx("p", { className: "error", children: error }), !loading && !error && (_jsx("div", { className: "card list-card", children: _jsx("ul", { children: gyms.map((g) => {
                        const isActive = activeGym?.id === g.id;
                        return (_jsxs("li", { className: isActive ? 'row-active' : '', children: [_jsx(Link, { to: `/gyms/${g.id}`, children: g.name || g.id }), " ", g.region ? `– ${g.region}` : '', isActive && _jsx("span", { className: "badge", children: "Aktiv" }), _jsx("span", { style: { marginLeft: '0.75rem' }, children: _jsx(Link, { className: "ghost btn-small", to: `/gyms/${g.id}`, children: "Ger\u00E4te & Codes" }) })] }, g.id));
                    }) }) }))] }));
}
