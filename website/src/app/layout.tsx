// website/src/app/layout.tsx
import type { Metadata, Route } from 'next';
import Link from 'next/link';
import { ReactNode } from 'react';

import { getDevUserFromCookies } from '@/src/lib/auth/server';
import type { Role } from '@/src/lib/auth/types';
import { ROUTES } from '@/src/lib/routes';
import DevToolbar from '@/src/components/dev-toolbar';

import '../styles/globals.css';

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000';
const isProd = process.env.VERCEL_ENV === 'production';

/**
 * Navigation: mit typedRoutes typisiert, damit href exakt existierende interne Routen sind.
 */
const navLinks: Array<{ href: Route; label: string }> = [
  { href: ROUTES.home, label: 'Home' },
  { href: ROUTES.gym, label: 'Gym' },
  { href: ROUTES.admin, label: 'Admin' },
];

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "Tap'em – NFC-basiertes Gym-Tracking",
  description:
    "Tap'em verbindet NFC-Check-ins, Trainingsanalysen und Gamification für moderne Fitnessstudios.",
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#f1f5f9' },
    { media: '(prefers-color-scheme: dark)', color: '#020617' },
  ],
  openGraph: {
    title: "Tap'em – NFC-basiertes Gym-Tracking",
    description:
      "Tap'em verbindet NFC-Check-ins, Trainingsanalysen und Gamification für moderne Fitnessstudios.",
    url: siteUrl,
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
  alternates: { canonical: siteUrl },
  // Previews/Dev: noindex; Production: index
  robots: isProd
    ? { index: true, follow: true }
    : { index: false, follow: false, noimageindex: true, nocache: true },
  twitter: {
    card: 'summary_large_image',
    title: "Tap'em – NFC-basiertes Gym-Tracking",
    description:
      "Tap'em verbindet NFC-Check-ins, Trainingsanalysen und Gamification für moderne Fitnessstudios.",
    images: ['/opengraph-image'],
  },
  icons: {
    icon: '/icon.svg',
    shortcut: '/icon.svg',
    apple: '/icon.svg',
  },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  // Dev-Toolbar nur außerhalb von Production
  const devUser = isProd ? null : getDevUserFromCookies();
  const currentRole: Role | null = devUser?.role ?? null;

  return (
    <html lang="de" suppressHydrationWarning className="h-full">
      <body className="bg-page text-page">
        <div className="relative flex min-h-screen flex-col">
          <header className="border-b border-subtle surface-blur">
            <div className="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-4 px-6 py-4">
              <div className="flex flex-1 items-center gap-8">
                <Link
                  href={ROUTES.home}
                  className="text-base font-semibold text-page focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >
                  Tap&apos;em
                </Link>

                <nav aria-label="Hauptnavigation" className="flex items-center gap-4 text-sm font-medium text-muted">
                  {navLinks.map((link) => (
                    <Link
                      key={link.href}
                      href={link.href}
                      className="rounded px-2 py-1 transition hover:text-primary focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                    >
                      {link.label}
                    </Link>
                  ))}
                </nav>
              </div>

              {!isProd ? (
                <DevToolbar currentRole={currentRole} />
              ) : (
                <div className="hidden" aria-hidden />
              )}
            </div>
          </header>

          <main className="flex-1">{children}</main>

          <footer className="border-t border-subtle bg-surface-muted">
            <div className="mx-auto w-full max-w-6xl px-6 py-6 text-center text-sm text-muted md:text-left">
              © {new Date().getFullYear()} Tap&apos;em{!isProd ? ' – Preview' : ''}
            </div>
          </footer>
        </div>
      </body>
    </html>
  );
}
