import type { Metadata } from 'next';

export type SiteKey = 'marketing' | 'portal' | 'admin';

type DeploymentStage = 'production' | 'preview' | 'development';

type SiteHosts = {
  production: string;
  preview: string[];
  development: string[];
};

export type SiteConfig = {
  key: SiteKey;
  label: string;
  hosts: SiteHosts;
};

const ENV_MARKETING_HOST = process.env.NEXT_PUBLIC_MARKETING_HOST;
const ENV_PORTAL_HOST = process.env.NEXT_PUBLIC_PORTAL_HOST;
const ENV_ADMIN_HOST = process.env.NEXT_PUBLIC_ADMIN_HOST;

const SITE_CONFIGS: Record<SiteKey, SiteConfig> = {
  marketing: {
    key: 'marketing',
    label: 'Marketing',
    hosts: {
      production: 'tapem.app',
      preview: ['tapem.vercel.app'],
      development: [ENV_MARKETING_HOST?.trim() || 'localhost:3000'],
    },
  },
  portal: {
    key: 'portal',
    label: 'Portal',
    hosts: {
      production: 'portal.tapem.app',
      preview: ['portal-tapem.vercel.app'],
      development: [ENV_PORTAL_HOST?.trim() || 'portal.localhost:3000'],
    },
  },
  admin: {
    key: 'admin',
    label: 'Admin',
    hosts: {
      production: 'admin.tapem.app',
      preview: ['admin-tapem.vercel.app'],
      development: [ENV_ADMIN_HOST?.trim() || 'admin.localhost:3000'],
    },
  },
};

const HOST_LOOKUP = new Map<string, SiteConfig>();

function registerHost(host: string | undefined, site: SiteConfig) {
  if (!host) {
    return;
  }
  const normalized = normalizeHost(host);
  if (!normalized) {
    return;
  }
  if (!HOST_LOOKUP.has(normalized)) {
    HOST_LOOKUP.set(normalized, site);
  }
}

for (const site of Object.values(SITE_CONFIGS)) {
  const { production, preview, development } = site.hosts;
  registerHost(production, site);
  for (const candidate of preview) {
    registerHost(candidate, site);
  }
  for (const candidate of development) {
    registerHost(candidate, site);
    const withoutPort = candidate.includes(':')
      ? candidate.slice(0, candidate.indexOf(':'))
      : candidate;
    if (withoutPort && withoutPort !== candidate) {
      registerHost(withoutPort, site);
    }
  }
}

export function getDeploymentStage(): DeploymentStage {
  const env = process.env.VERCEL_ENV;
  if (env === 'production') {
    return 'production';
  }
  if (env === 'preview') {
    return 'preview';
  }
  return 'development';
}

export function normalizeHost(host: string | null | undefined): string | null {
  if (!host) {
    return null;
  }
  return host.trim().toLowerCase();
}

export function findSiteByHost(host: string | null | undefined): SiteConfig | null {
  const normalized = normalizeHost(host);
  if (!normalized) {
    return null;
  }
  return HOST_LOOKUP.get(normalized) ?? null;
}

export function getSiteConfig(key: SiteKey): SiteConfig {
  return SITE_CONFIGS[key];
}

export function getPreferredHost(site: SiteKey): string {
  const stage = getDeploymentStage();
  const config = getSiteConfig(site);

  if (stage === 'production') {
    return config.hosts.production;
  }

  if (stage === 'preview') {
    const [primaryPreview] = config.hosts.preview;
    return primaryPreview ?? config.hosts.production;
  }

  const [primaryDev] = config.hosts.development;
  return primaryDev ?? config.hosts.preview[0] ?? config.hosts.production;
}

function isLocalHost(host: string): boolean {
  return host.includes('localhost') || host.startsWith('127.');
}

function buildOrigin(host: string): URL {
  const protocol = isLocalHost(host) ? 'http' : 'https';
  return new URL(`${protocol}://${host}`);
}

export function buildSiteUrl(site: SiteKey, path = '/'): string {
  const host = getPreferredHost(site);
  const origin = buildOrigin(host);
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return new URL(normalizedPath, origin).toString();
}

export function buildMetadataBase(host: string | null | undefined): URL {
  const normalized = normalizeHost(host) ?? getPreferredHost('marketing');
  return buildOrigin(normalized);
}

export function buildSiteMetadata(site: SiteConfig, host: string | null | undefined): Metadata {
  const metadataBase = buildMetadataBase(host ?? getPreferredHost(site.key));
  const baseUrl = metadataBase.toString().replace(/\/$/, '');

  const shared: Metadata = {
    metadataBase,
    alternates: { canonical: baseUrl },
    themeColor: [
      { media: '(prefers-color-scheme: light)', color: '#f1f5f9' },
      { media: '(prefers-color-scheme: dark)', color: '#020617' },
    ],
    icons: {
      icon: '/icon.svg',
      shortcut: '/icon.svg',
      apple: '/icon.svg',
    },
  };

  if (site.key === 'marketing') {
    return {
      ...shared,
      title: "Tap'em – NFC-basiertes Gym-Tracking",
      description:
        "Tap'em verbindet NFC-Check-ins, Trainingsanalysen und Gamification für moderne Fitnessstudios.",
      openGraph: {
        title: "Tap'em – NFC-basiertes Gym-Tracking",
        description:
          "Tap'em verbindet NFC-Check-ins, Trainingsanalysen und Gamification für moderne Fitnessstudios.",
        url: baseUrl,
        siteName: "Tap'em",
        locale: 'de_DE',
        type: 'website',
        images: [
          {
            url: '/opengraph-image',
            width: 1200,
            height: 630,
            alt: "Tap'em – NFC-basiertes Gym-Tracking & -Management",
          },
        ],
      },
      robots: { index: true, follow: true },
      twitter: {
        card: 'summary_large_image',
        title: "Tap'em – NFC-basiertes Gym-Tracking",
        description:
          "Tap'em verbindet NFC-Check-ins, Trainingsanalysen und Gamification für moderne Fitnessstudios.",
        images: ['/opengraph-image'],
      },
    };
  }

  if (site.key === 'portal') {
    return {
      ...shared,
      title: "Tap'em Studio-Portal",
      description: 'Geschützter Login-Bereich für Studio-Betreiber:innen von Tap\'em.',
      openGraph: {
        title: "Tap'em Studio-Portal",
        description: 'Geschützter Login-Bereich für Studio-Betreiber:innen von Tap\'em.',
        url: baseUrl,
        siteName: "Tap'em Portal",
        locale: 'de_DE',
        type: 'website',
      },
      robots: {
        index: false,
        follow: false,
        noimageindex: true,
        nocache: true,
      },
    };
  }

  return {
    ...shared,
    title: "Tap'em Admin Monitoring",
    description: 'Interner Monitoring-Bereich für Tap\'em Administrator:innen.',
    openGraph: {
      title: "Tap'em Admin Monitoring",
      description: 'Interner Monitoring-Bereich für Tap\'em Administrator:innen.',
      url: baseUrl,
      siteName: "Tap'em Admin",
      locale: 'de_DE',
      type: 'website',
    },
    robots: {
      index: false,
      follow: false,
      noimageindex: true,
      nocache: true,
    },
  };
}

export function isMarketingHost(host: string | null | undefined): boolean {
  return findSiteByHost(host)?.key === 'marketing';
}

export function isPortalHost(host: string | null | undefined): boolean {
  return findSiteByHost(host)?.key === 'portal';
}

export function isAdminHost(host: string | null | undefined): boolean {
  return findSiteByHost(host)?.key === 'admin';
}
