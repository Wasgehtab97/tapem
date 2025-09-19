import type { MetadataRoute } from 'next';

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000';
const protectedRoutes = ['/gym', '/gym/members', '/gym/challenges', '/gym/leaderboard', '/admin'];

export default function robots(): MetadataRoute.Robots {
  const normalizedUrl = siteUrl.endsWith('/') ? siteUrl.slice(0, -1) : siteUrl;
  const isProd = process.env.VERCEL_ENV === 'production';

  if (!isProd) {
    return {
      rules: [{ userAgent: '*', disallow: '/' }],
      sitemap: `${normalizedUrl}/sitemap.xml`,
    };
  }

  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: protectedRoutes,
      },
    ],
    sitemap: `${normalizedUrl}/sitemap.xml`,
  };
}
