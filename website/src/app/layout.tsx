import type { Metadata, Viewport } from 'next';
import { cookies, headers } from 'next/headers';
import { ReactNode } from 'react';

import { buildSiteMetadata, getSiteConfig } from '@/config/sites';
import { ThemeScript } from '@/components/theme-script';
import { THEME_COLORS, THEME_COOKIE_NAME, getServerThemeHint } from '@/lib/theme';

import '../styles/globals.css';

export async function generateMetadata(): Promise<Metadata> {
  const headerList = headers();
  const host = headerList.get('host');
  return buildSiteMetadata(getSiteConfig('marketing'), host);
}

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: dark)', color: THEME_COLORS.dark },
    { media: '(prefers-color-scheme: light)', color: THEME_COLORS.light },
  ],
};

export default function RootLayout({ children }: { children: ReactNode }) {
  const cookieStore = cookies();
  const themeCookie = cookieStore.get(THEME_COOKIE_NAME)?.value;
  const initialTheme = getServerThemeHint(themeCookie);
  const htmlClassName = initialTheme === 'dark' ? 'h-full dark' : 'h-full';

  return (
    <html lang="de" suppressHydrationWarning className={htmlClassName} data-theme={initialTheme}>
      <head>
        <ThemeScript />
      </head>
      <body className="bg-page text-page">{children}</body>
    </html>
  );
}
