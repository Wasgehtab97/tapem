import type { MetadataRoute } from 'next';

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000';

export default function robots(): MetadataRoute.Robots {
  const normalizedUrl = siteUrl.endsWith('/') ? siteUrl.slice(0, -1) : siteUrl;

  return {
    rules: [{ userAgent: '*', allow: '/' }],
    sitemap: `${normalizedUrl}/sitemap.xml`,
  };
}
