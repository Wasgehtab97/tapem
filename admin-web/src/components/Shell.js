import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { NavLink, useNavigate } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { auth, db } from '../firebase';
import { signOut } from 'firebase/auth';
import { collection, getDocs, limit, query } from 'firebase/firestore';
import { useActiveGym } from '../hooks/useActiveGym';
export function Shell({ children }) {
    const navigate = useNavigate();
    const { activeGym, setActiveGym, clearActiveGym } = useActiveGym();
    const [gyms, setGyms] = useState([]);
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
                setGyms(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
            }
            finally {
                setLoadingGyms(false);
            }
        }
        loadGyms();
    }, []);
    useEffect(() => {
        function handleGymCreated(event) {
            const detail = event.detail;
            if (!detail?.id)
                return;
            setGyms((prev) => {
                if (prev.some((g) => g.id === detail.id))
                    return prev;
                return [{ id: detail.id, name: detail.name }, ...prev];
            });
        }
        window.addEventListener('gym-created', handleGymCreated);
        return () => window.removeEventListener('gym-created', handleGymCreated);
    }, []);
    return (_jsxs("div", { className: "shell", children: [_jsxs("header", { className: "shell-header", children: [_jsx("div", { className: "logo", children: "tapem Admin" }), _jsxs("nav", { className: "shell-nav", children: [_jsx(NavLink, { to: "/", end: true, children: "Dashboard" }), activeGym?.id ? (_jsx(NavLink, { to: `/gyms/${activeGym.id}`, children: "Gym" })) : (_jsx("span", { className: "nav-disabled", children: "Gym" })), activeGym?.id ? _jsx(NavLink, { to: "/users", children: "User" }) : _jsx("span", { className: "nav-disabled", children: "User" })] }), _jsxs("div", { className: "shell-actions", children: [_jsxs("label", { className: "gym-select", children: [_jsx("span", { children: "Gym" }), _jsxs("select", { value: activeGym?.id || '', onChange: (e) => {
                                            const id = e.target.value;
                                            if (!id) {
                                                clearActiveGym();
                                                return;
                                            }
                                            const gym = gyms.find((g) => g.id === id);
                                            setActiveGym({ id, name: gym?.name || null });
                                        }, children: [_jsx("option", { value: "", children: loadingGyms ? 'Lade…' : 'Alle' }), gyms.map((g) => (_jsx("option", { value: g.id, children: g.name || g.id }, g.id)))] })] }), _jsx("button", { className: "ghost", onClick: handleLogout, children: "Logout" })] })] }), _jsx("main", { className: "shell-main", children: children })] }));
}
