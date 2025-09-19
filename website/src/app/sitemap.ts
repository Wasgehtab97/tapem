import type { MetadataRoute } from 'next';
import { headers } from 'next/headers';

import { buildMetadataBase, findSiteByHost, getSiteConfig } from '@/src/config/sites';

const MARKETING_SITEMAP_PATHS = [
  { path: '/', priority: 1, changeFrequency: 'monthly' as const },
  { path: '/#features', priority: 0.8, changeFrequency: 'monthly' as const },
  { path: '/#how-it-works', priority: 0.7, changeFrequency: 'monthly' as const },
  { path: '/#faq', priority: 0.6, changeFrequency: 'monthly' as const },
  { path: '/#contact', priority: 0.6, changeFrequency: 'monthly' as const },
];

export default function sitemap(): MetadataRoute.Sitemap {
  const headerList = headers();
  const host = headerList.get('host');
  const site = findSiteByHost(host) ?? getSiteConfig('marketing');

  if (site.key !== 'marketing') {
    return [];
  }

  const baseUrl = buildMetadataBase(host).toString().replace(/\/$/, '');
  const now = new Date();

  return MARKETING_SITEMAP_PATHS.map((entry) => ({
    url: `${baseUrl}${entry.path}`,
    lastModified: now,
    changeFrequency: entry.changeFrequency,
    priority: entry.priority,
  }));
}
