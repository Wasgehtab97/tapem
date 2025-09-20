import type { MetadataRoute } from 'next';
import { headers } from 'next/headers';

import { buildMetadataBase, findSiteByHost, getSiteConfig } from '@/src/config/sites';

const MARKETING_DISALLOW = [
  '/login',
  '/gym',
  '/gym/members',
  '/gym/challenges',
  '/gym/leaderboard',
  '/admin',
  '/admin/login',
  '/admin/logout',
];

export default function robots(): MetadataRoute.Robots {
  const headerList = headers();
  const host = headerList.get('host');
  const site = findSiteByHost(host) ?? getSiteConfig('marketing');
  const baseUrl = buildMetadataBase(host).toString().replace(/\/$/, '');

  if (site.key === 'marketing') {
    return {
      rules: [
        {
          userAgent: '*',
          allow: '/',
          disallow: MARKETING_DISALLOW,
        },
      ],
      sitemap: `${baseUrl}/sitemap.xml`,
    };
  }

  return {
    rules: [{ userAgent: '*', disallow: '/' }],
  };
}
