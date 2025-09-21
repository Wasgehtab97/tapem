import { THEME_COLORS, THEME_COOKIE_NAME, THEME_STORAGE_KEY } from '@/lib/theme';

const themeInitializer = `(() => {
  try {
    const storageKey = '${THEME_STORAGE_KEY}';
    const cookieName = '${THEME_COOKIE_NAME}';
    const metaSelector = 'meta[name="theme-color"]';
    const darkColor = '${THEME_COLORS.dark}';
    const lightColor = '${THEME_COLORS.light}';

    const root = document.documentElement;
    const media = window.matchMedia('(prefers-color-scheme: dark)');
    const stored = window.localStorage.getItem(storageKey);
    const isValidPreference = stored === 'light' || stored === 'dark' || stored === 'system';
    const preference = isValidPreference ? stored : 'system';
    if (!isValidPreference) {
      try {
        window.localStorage.setItem(storageKey, 'system');
      } catch (error) {
        // Storage ggf. deaktiviert – ignorieren.
      }
    }

    const resolved = preference === 'system' ? (media.matches ? 'dark' : 'light') : preference;

    root.classList.toggle('dark', resolved === 'dark');
    root.setAttribute('data-theme', resolved);

    const meta = document.querySelector(metaSelector);
    if (meta) {
      meta.setAttribute('content', resolved === 'dark' ? darkColor : lightColor);
    }

    document.cookie = cookieName + '=' + resolved + '; path=/; max-age=31536000; SameSite=Lax';

    if (preference === 'system') {
      const update = (event) => {
        const currentPreference = window.localStorage.getItem(storageKey);
        if (currentPreference && currentPreference !== 'system') {
          return;
        }
        const next = event.matches ? 'dark' : 'light';
        root.classList.toggle('dark', next === 'dark');
        root.setAttribute('data-theme', next);
        const metaEl = document.querySelector(metaSelector);
        if (metaEl) {
          metaEl.setAttribute('content', next === 'dark' ? darkColor : lightColor);
        }
        document.cookie = cookieName + '=' + next + '; path=/; max-age=31536000; SameSite=Lax';
      };

      if (typeof media.addEventListener === 'function') {
        media.addEventListener('change', update);
      } else if (typeof media.addListener === 'function') {
        media.addListener(update);
      }
    }
  } catch (error) {
    // Kein Theme-Flash, wenn Storage/Cookies blockiert sind.
  }
})();`;

export function ThemeScript() {
  return <script dangerouslySetInnerHTML={{ __html: themeInitializer }} suppressHydrationWarning />;
}
