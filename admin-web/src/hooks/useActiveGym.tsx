import { createContext, ReactNode, useContext, useEffect, useMemo, useState } from 'react';

type ActiveGym = { id: string; name?: string | null };

type Ctx = {
  activeGym: ActiveGym | null;
  setActiveGym: (gym: ActiveGym) => void;
  clearActiveGym: () => void;
};

const ActiveGymContext = createContext<Ctx | undefined>(undefined);
const STORAGE_KEY = 'tapem.admin.activeGym';

export function ActiveGymProvider({ children }: { children: ReactNode }) {
  const [activeGym, setActiveGymState] = useState<ActiveGym | null>(null);

  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        setActiveGymState(JSON.parse(raw));
      }
    } catch (e) {
      console.warn('ActiveGym load failed', e);
    }
  }, []);

  const value = useMemo<Ctx>(() => {
    const setActiveGym = (gym: ActiveGym) => {
      setActiveGymState(gym);
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(gym));
      } catch (e) {
        console.warn('ActiveGym persist failed', e);
      }
    };
    const clearActiveGym = () => {
      setActiveGymState(null);
      try {
        localStorage.removeItem(STORAGE_KEY);
      } catch (e) {
        console.warn('ActiveGym clear failed', e);
      }
    };
    return { activeGym, setActiveGym, clearActiveGym };
  }, [activeGym]);

  return <ActiveGymContext.Provider value={value}>{children}</ActiveGymContext.Provider>;
}

export function useActiveGym() {
  const ctx = useContext(ActiveGymContext);
  if (!ctx) throw new Error('useActiveGym must be used inside ActiveGymProvider');
  return ctx;
}
