'use client';

import { useCallback, useEffect, useRef, useState } from 'react';

import {
  THEME_STORAGE_KEY,
  applyResolvedTheme,
  isThemePreference,
  persistTheme,
  resolveTheme,
  type ThemeMode,
  type ThemePreference,
} from '@/lib/theme';

const TOGGLE_SEQUENCE: ThemePreference[] = ['light', 'dark', 'system'];

const ICONS: Record<ThemePreference, string> = {
  light: '☀️',
  dark: '🌙',
  system: '🖥️',
};

const LABELS: Record<ThemePreference, string> = {
  light: 'Hellmodus',
  dark: 'Dunkelmodus',
  system: 'Systemmodus',
};

export function ThemeToggle() {
  const [isMounted, setIsMounted] = useState(false);
  const [preference, setPreference] = useState<ThemePreference>('system');
  const [resolvedTheme, setResolvedTheme] = useState<ThemeMode>('light');
  const mediaQueryRef = useRef<MediaQueryList | null>(null);
  const preferenceRef = useRef<ThemePreference>('system');

  const applyPreference = useCallback((nextPreference: ThemePreference) => {
    const media = mediaQueryRef.current;
    if (!media) {
      return;
    }

    const nextResolved = resolveTheme(nextPreference, media.matches);
    preferenceRef.current = nextPreference;
    setPreference(nextPreference);
    setResolvedTheme(nextResolved);
    applyResolvedTheme(nextResolved);
    persistTheme(nextPreference, nextResolved);
  }, []);

  useEffect(() => {
    const media = window.matchMedia('(prefers-color-scheme: dark)');
    mediaQueryRef.current = media;

    const stored = window.localStorage.getItem(THEME_STORAGE_KEY);
    const initialPreference = isThemePreference(stored) ? stored : 'system';
    applyPreference(initialPreference);
    setIsMounted(true);

    const handleChange = (event: MediaQueryListEvent) => {
      if (preferenceRef.current === 'system') {
        const nextResolved = event.matches ? 'dark' : 'light';
        setResolvedTheme(nextResolved);
        applyResolvedTheme(nextResolved);
        persistTheme('system', nextResolved);
      }
    };

    if (typeof media.addEventListener === 'function') {
      media.addEventListener('change', handleChange);
      return () => media.removeEventListener('change', handleChange);
    }

    media.addListener(handleChange);
    return () => media.removeListener(handleChange);
  }, [applyPreference]);

  const togglePreference = () => {
    const currentIndex = TOGGLE_SEQUENCE.indexOf(preferenceRef.current);
    const next = TOGGLE_SEQUENCE[(currentIndex + 1) % TOGGLE_SEQUENCE.length];
    applyPreference(next);
  };

  const nextPreference = TOGGLE_SEQUENCE[(TOGGLE_SEQUENCE.indexOf(preference) + 1) % TOGGLE_SEQUENCE.length];
  const currentLabel = LABELS[preference];
  const nextLabel = LABELS[nextPreference];
  const resolvedModeLabel = resolvedTheme === 'dark' ? 'Dunkelmodus aktiv' : 'Hellmodus aktiv';

  if (!isMounted) {
    return (
      <button
        type="button"
        aria-label="Theme-Umschalter wird geladen"
        className="h-10 w-10 rounded-full border border-subtle bg-card-muted"
        disabled
      />
    );
  }

  return (
    <button
      type="button"
      onClick={togglePreference}
      aria-label={`Theme wechseln (aktuell ${currentLabel}, nächster Modus ${nextLabel})`}
      title={`Theme wechseln (nächster Modus: ${nextLabel})`}
      className="flex h-10 w-10 items-center justify-center rounded-full border border-subtle bg-card text-lg transition hover:border-primary hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
    >
      <span aria-hidden="true">{ICONS[preference]}</span>
      <span className="sr-only">Aktiv: {currentLabel} · {resolvedModeLabel}</span>
    </button>
  );
}
