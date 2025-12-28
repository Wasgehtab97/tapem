import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Navigate, Route, Routes } from 'react-router-dom';
import { AuthGate } from '../components/AuthGate';
import { Dashboard } from './Dashboard';
import { Login } from './Login';
import { GymDetail } from './GymDetail';
import { Users } from './Users';
import { Devices } from './Devices';
import { Shell } from '../components/Shell';
import { useActiveGym } from '../hooks/useActiveGym';
function RequireGym({ children }) {
    const { activeGym } = useActiveGym();
    if (!activeGym?.id) {
        return _jsx(Navigate, { to: "/", replace: true });
    }
    return children;
}
function GymRedirect() {
    const { activeGym } = useActiveGym();
    if (!activeGym?.id) {
        return _jsx(Navigate, { to: "/", replace: true });
    }
    return _jsx(Navigate, { to: `/gyms/${activeGym.id}`, replace: true });
}
export default function App() {
    return (_jsxs(Routes, { children: [_jsx(Route, { path: "/login", element: _jsx(Login, {}) }), _jsx(Route, { path: "/*", element: _jsx(AuthGate, { children: _jsx(Shell, { children: _jsxs(Routes, { children: [_jsx(Route, { path: "/", element: _jsx(Dashboard, {}) }), _jsx(Route, { path: "/gyms", element: _jsx(GymRedirect, {}) }), _jsx(Route, { path: "/gyms/:gymId", element: _jsx(RequireGym, { children: _jsx(GymDetail, {}) }) }), _jsx(Route, { path: "/users", element: _jsx(RequireGym, { children: _jsx(Users, {}) }) }), _jsx(Route, { path: "/gyms/:gymId/devices", element: _jsx(RequireGym, { children: _jsx(Devices, {}) }) }), _jsx(Route, { path: "*", element: _jsx(Navigate, { to: "/", replace: true }) })] }) }) }) })] }));
}
