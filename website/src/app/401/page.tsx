import type { Metadata } from 'next';
import { headers } from 'next/headers';

import { buildSiteUrl, findSiteByHost, getSiteConfig, type SiteConfig } from '@/src/config/sites';
import { MARKETING_ROUTES, PORTAL_ROUTES, ADMIN_ROUTES } from '@/src/lib/routes';

export const metadata: Metadata = {
  title: 'Anmeldung erforderlich – Tap\'em',
  robots: { index: false, follow: false },
};

type PageContent = {
  title: string;
  message: string;
  actions: Array<{ label: string; href: string; external?: boolean }>;
  accent: 'amber' | 'slate' | 'red';
};

function resolveSite(): SiteConfig {
  const host = headers().get('host');
  return findSiteByHost(host) ?? getSiteConfig('marketing');
}

function resolveContent(site: SiteConfig): PageContent {
  switch (site.key) {
    case 'portal':
      return {
        title: 'Bitte melde dich im Studio-Portal an.',
        message:
          'Deine Sitzung ist abgelaufen oder du hast noch keine Rolle gewählt. Der Dev-Login bleibt nur in Preview/Entwicklung aktiv.',
        actions: [
          { label: 'Zum Login', href: PORTAL_ROUTES.login },
        ],
        accent: 'amber',
      };
    case 'admin':
      return {
        title: 'Dieser Admin-Bereich ist nur intern zugänglich.',
        message: 'Bitte verwende die interne Authentifizierung oder kontaktiere das Kernteam, falls du Zugang benötigst.',
        actions: [
          { label: 'Zur Monitoring-Übersicht', href: ADMIN_ROUTES.dashboard },
        ],
        accent: 'amber',
      };
    default:
      return {
        title: 'Dieser Bereich erfordert einen Portal-Login.',
        message:
          'Marketing-Inhalte bleiben frei zugänglich. Betreiber:innen erreichen das Portal über die dedizierte Subdomain.',
        actions: [
          { label: 'Zum Portal-Login', href: buildSiteUrl('portal', PORTAL_ROUTES.login), external: true },
          { label: 'Zur Startseite', href: MARKETING_ROUTES.home },
        ],
        accent: 'amber',
      };
  }
}

export default function UnauthorizedPage() {
  const site = resolveSite();
  const content = resolveContent(site);
  const accentClass =
    content.accent === 'red'
      ? 'text-red-600'
      : content.accent === 'slate'
        ? 'text-slate-500'
        : 'text-amber-600';

  return (
    <section className="mx-auto flex w-full max-w-3xl flex-col gap-6 px-6 py-24 text-center">
      <p className={`text-sm font-semibold uppercase tracking-wide ${accentClass}`}>
        401 – Anmeldung erforderlich
      </p>
      <h1 className="text-3xl font-bold tracking-tight text-page">{content.title}</h1>
      <p className="text-base text-muted">{content.message}</p>
      <div className="flex flex-col items-center justify-center gap-3 sm:flex-row">
        {content.actions.map((action) => (
          <a
            key={action.label}
            href={action.href}
            className={`rounded-full px-6 py-3 text-sm font-semibold transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary ${
              action.external
                ? 'border border-subtle text-page hover:border-primary hover:text-primary'
                : 'bg-primary text-primary-foreground shadow-lg shadow-primary/30 hover:bg-primary/90'
            }`}
          >
            {action.label}
          </a>
        ))}
      </div>
    </section>
  );
}
