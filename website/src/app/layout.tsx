import type { Metadata } from 'next';
import { ReactNode } from 'react';

import '../styles/globals.css';

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000';

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

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="de" suppressHydrationWarning>
      <body className="bg-white text-slate-900 dark:bg-slate-950 dark:text-slate-100">
        {children}
      </body>
    </html>
  );
}
