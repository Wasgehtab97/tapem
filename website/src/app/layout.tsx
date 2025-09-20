import type { Metadata, Viewport } from 'next';
import { headers } from 'next/headers';
import { ReactNode } from 'react';

import { SITE_THEME_COLORS, buildSiteMetadata, getSiteConfig } from '@/src/config/sites';

import '../styles/globals.css';

export async function generateMetadata(): Promise<Metadata> {
  const headerList = headers();
  const host = headerList.get('host');
  return buildSiteMetadata(getSiteConfig('marketing'), host);
}

export const viewport: Viewport = {
  themeColor: SITE_THEME_COLORS,
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="de" suppressHydrationWarning className="h-full">
      <body className="bg-page text-page">{children}</body>
    </html>
  );
}
