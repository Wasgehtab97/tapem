import type { Metadata, Viewport } from 'next';
import { headers } from 'next/headers';
import { ReactNode } from 'react';

import { buildSiteMetadata, getSiteConfig } from '@/config/sites';

import '../styles/globals.css';

export async function generateMetadata(): Promise<Metadata> {
  const headerList = headers();
  const host = headerList.get('host');
  return buildSiteMetadata(getSiteConfig('marketing'), host);
}

export const viewport: Viewport = {
  themeColor: '#0B0F1A',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="de" suppressHydrationWarning className="h-full">
      <body className="bg-page text-page">{children}</body>
    </html>
  );
}
