import { jsx as _jsx } from "react/jsx-runtime";
import { createContext, useContext, useEffect, useMemo, useState } from 'react';
const ActiveGymContext = createContext(undefined);
const STORAGE_KEY = 'tapem.admin.activeGym';
export function ActiveGymProvider({ children }) {
    const [activeGym, setActiveGymState] = useState(null);
    useEffect(() => {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            if (raw) {
                setActiveGymState(JSON.parse(raw));
            }
        }
        catch (e) {
            console.warn('ActiveGym load failed', e);
        }
    }, []);
    const value = useMemo(() => {
        const setActiveGym = (gym) => {
            setActiveGymState(gym);
            try {
                localStorage.setItem(STORAGE_KEY, JSON.stringify(gym));
            }
            catch (e) {
                console.warn('ActiveGym persist failed', e);
            }
        };
        const clearActiveGym = () => {
            setActiveGymState(null);
            try {
                localStorage.removeItem(STORAGE_KEY);
            }
            catch (e) {
                console.warn('ActiveGym clear failed', e);
            }
        };
        return { activeGym, setActiveGym, clearActiveGym };
    }, [activeGym]);
    return _jsx(ActiveGymContext.Provider, { value: value, children: children });
}
export function useActiveGym() {
    const ctx = useContext(ActiveGymContext);
    if (!ctx)
        throw new Error('useActiveGym must be used inside ActiveGymProvider');
    return ctx;
}
