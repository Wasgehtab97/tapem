import type { Metadata } from 'next';
import { headers } from 'next/headers';

import { buildSiteUrl, findSiteByHost, getSiteConfig, type SiteConfig } from '@/src/config/sites';
import { ADMIN_ROUTES, MARKETING_ROUTES, PORTAL_ROUTES } from '@/src/lib/routes';

export const metadata: Metadata = {
  title: 'Nicht gefunden – Tap\'em',
  robots: { index: false, follow: false },
};

type PageContent = {
  title: string;
  message: string;
  actions: Array<{ label: string; href: string; primary?: boolean; external?: boolean }>;
  accent: 'slate' | 'red';
};

function resolveSite(): SiteConfig {
  const host = headers().get('host');
  return findSiteByHost(host) ?? getSiteConfig('marketing');
}

function resolveContent(site: SiteConfig): PageContent {
  switch (site.key) {
    case 'portal':
      return {
        title: 'Diese Portal-Seite existiert nicht.',
        message: 'Überprüfe die Adresse oder navigiere zurück zum Dashboard. In Preview kannst du Rollen via Dev-Toolbar wechseln.',
        actions: [{ label: 'Zur Übersicht', href: PORTAL_ROUTES.gym.href, primary: true }],
        accent: 'slate',
      };
    case 'admin':
      return {
        title: 'Dieser Admin-Endpunkt ist nicht verfügbar.',
        message: 'Nutze das Monitoring-Dashboard oder prüfe die verwendete Subdomain.',
        actions: [{ label: 'Zum Monitoring', href: ADMIN_ROUTES.dashboard.href, primary: true }],
        accent: 'slate',
      };
    default:
      return {
        title: 'Diese Seite gibt es (noch) nicht.',
        message: 'Prüfe die URL oder kehre zur Startseite zurück. Studios erreichen das Portal über den Login-Button.',
        actions: [
          { label: 'Zur Startseite', href: MARKETING_ROUTES.home.href, primary: true },
          { label: 'Zum Portal-Login', href: buildSiteUrl('portal', PORTAL_ROUTES.login.href), external: true },
        ],
        accent: 'slate',
      };
  }
}

export default function NotFoundPage() {
  const site = resolveSite();
  const content = resolveContent(site);
  const accentClass = content.accent === 'red' ? 'text-red-600' : 'text-slate-500';

  return (
    <section className="mx-auto flex w-full max-w-3xl flex-col gap-6 px-6 py-24 text-center">
      <p className={`text-sm font-semibold uppercase tracking-wide ${accentClass}`}>404 – Nicht gefunden</p>
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
            rel={action.external ? 'noreferrer noopener' : undefined}
            target={action.external ? '_blank' : undefined}
          >
            {action.label}
          </a>
        ))}
      </div>
    </section>
  );
}
