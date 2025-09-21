export const THEME_STORAGE_KEY = 'tapem-theme';
export const THEME_COOKIE_NAME = 'tapem-theme';

export type ThemePreference = 'light' | 'dark' | 'system';
export type ThemeMode = 'light' | 'dark';

export const THEME_COLORS: Record<ThemeMode, string> = {
  light: '#f1f5f9',
  dark: '#020617',
};

export function isThemePreference(value: string | null): value is ThemePreference {
  return value === 'light' || value === 'dark' || value === 'system';
}

export function resolveTheme(preference: ThemePreference, systemPrefersDark: boolean): ThemeMode {
  if (preference === 'system') {
    return systemPrefersDark ? 'dark' : 'light';
  }

  return preference;
}

export function applyResolvedTheme(theme: ThemeMode) {
  const root = document.documentElement;
  root.classList.toggle('dark', theme === 'dark');
  root.setAttribute('data-theme', theme);

  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) {
    meta.setAttribute('content', THEME_COLORS[theme]);
  }
}

export function persistTheme(preference: ThemePreference, resolved: ThemeMode) {
  try {
    window.localStorage.setItem(THEME_STORAGE_KEY, preference);
  } catch {
    // Ignorieren – Storage eventuell deaktiviert.
  }

  try {
    document.cookie = `${THEME_COOKIE_NAME}=${resolved}; path=/; max-age=31536000; SameSite=Lax`;
  } catch {
    // Ignorieren – Cookies eventuell blockiert.
  }
}

export function getServerThemeHint(cookieValue: string | undefined): ThemeMode {
  if (cookieValue === 'dark') {
    return 'dark';
  }

  return 'light';
}
