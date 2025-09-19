import type { Metadata } from 'next';
import { headers } from 'next/headers';

import { findSiteByHost, getSiteConfig, type SiteConfig } from '@/src/config/sites';
import { ADMIN_ROUTES, MARKETING_ROUTES, PORTAL_ROUTES } from '@/src/lib/routes';

export const metadata: Metadata = {
  title: 'Kein Zugriff – Tap\'em',
  robots: { index: false, follow: false },
};

type PageContent = {
  title: string;
  message: string;
  actions: Array<{ label: string; href: string; primary?: boolean }>;
  accent: 'red' | 'slate';
};

function resolveSite(): SiteConfig {
  const host = headers().get('host');
  return findSiteByHost(host) ?? getSiteConfig('marketing');
}

function resolveContent(site: SiteConfig): PageContent {
  switch (site.key) {
    case 'portal':
      return {
        title: 'Für deine Rolle ist dieser Bereich gesperrt.',
        message: 'Kontaktiere die Studio-Administration, wenn du weitere Rechte benötigst.',
        actions: [{ label: 'Zur Übersicht', href: PORTAL_ROUTES.gym, primary: true }],
        accent: 'red',
      };
    case 'admin':
      return {
        title: 'Nur Super-Admins dürfen dieses Monitoring sehen.',
        message: 'Bitte wende dich an das Kernteam, um Admin-Rechte zu erhalten.',
        actions: [{ label: 'Zum Monitoring', href: ADMIN_ROUTES.dashboard, primary: true }],
        accent: 'red',
      };
    default:
      return {
        title: 'Dieser Bereich ist geschützt.',
        message: 'Marketing-Inhalte findest du weiterhin öffentlich auf der Startseite.',
        actions: [{ label: 'Zur Startseite', href: MARKETING_ROUTES.home, primary: true }],
        accent: 'red',
      };
  }
}

export default function ForbiddenPage() {
  const site = resolveSite();
  const content = resolveContent(site);
  const accentClass = content.accent === 'red' ? 'text-red-600' : 'text-slate-500';

  return (
    <section className="mx-auto flex w-full max-w-3xl flex-col gap-6 px-6 py-24 text-center">
      <p className={`text-sm font-semibold uppercase tracking-wide ${accentClass}`}>403 – Kein Zugriff</p>
      <h1 className="text-3xl font-bold tracking-tight text-page">{content.title}</h1>
      <p className="text-base text-muted">{content.message}</p>
      <div className="flex flex-col items-center justify-center gap-3 sm:flex-row">
        {content.actions.map((action) => (
          <a
            key={action.label}
            href={action.href}
            className={
              action.primary
                ? 'rounded-full bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground shadow-lg shadow-primary/30 transition hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary'
                : 'rounded-full border border-subtle px-6 py-3 text-sm font-semibold text-page transition hover:border-primary hover:text-primary focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary'
            }
          >
            {action.label}
          </a>
        ))}
      </div>
    </section>
  );
}
