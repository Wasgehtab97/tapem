import type { Metadata } from 'next';
import Link from 'next/link';
import { ReactNode } from 'react';

import { getDevUserFromCookies } from '@/src/lib/auth/server';
import type { Role } from '@/src/lib/auth/types';
import DevToolbar from '@/src/components/dev-toolbar';

import '../styles/globals.css';

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000';
const navLinks = [
  { href: '/', label: 'Home' },
  { href: '/gym', label: 'Gym' },
  { href: '/admin', label: 'Admin' },
];

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "Tap'em – NFC-basiertes Gym-Tracking",
  description:
    "Tap'em verbindet NFC-Check-ins, Trainingsanalysen und Gamification für moderne Fitnessstudios.",
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
  alternates: {
    canonical: siteUrl,
  },
  robots: {
    index: true,
    follow: true,
  },
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

function isProduction() {
  return process.env.VERCEL_ENV === 'production';
}

export default function RootLayout({ children }: { children: ReactNode }) {
  const devUser = isProduction() ? null : getDevUserFromCookies();
  const currentRole: Role | null = devUser?.role ?? null;

  return (
    <html lang="de" suppressHydrationWarning>
      <body className="bg-white text-slate-900">
        <div className="flex min-h-screen flex-col">
          <header className="border-b border-slate-200 bg-white/95 backdrop-blur">
            <div className="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-4 px-6 py-4">
              <div className="flex flex-1 items-center gap-8">
                <Link
                  href="/"
                  className="text-base font-semibold text-slate-900 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900"
                >
                  Tap&apos;em
                </Link>
                <nav aria-label="Hauptnavigation" className="flex items-center gap-4 text-sm font-medium text-slate-700">
                  {navLinks.map((link) => (
                    <Link
                      key={link.href}
                      href={link.href}
                      className="rounded px-2 py-1 transition hover:bg-slate-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-900"
                    >
                      {link.label}
                    </Link>
                  ))}
                </nav>
              </div>
              {!isProduction() ? (
                <DevToolbar currentRole={currentRole} />
              ) : (
                <div className="hidden" aria-hidden />
              )}
            </div>
          </header>
          <main className="mx-auto w-full max-w-6xl flex-1 px-6 py-10">{children}</main>
          <footer className="border-t border-slate-200 bg-slate-50">
            <div className="mx-auto w-full max-w-6xl px-6 py-4 text-sm text-slate-500">
              © {new Date().getFullYear()} Tap&apos;em – Preview
            </div>
          </footer>
        </div>
      </body>
    </html>
  );
}
