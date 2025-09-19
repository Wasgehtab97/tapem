import type { Metadata } from 'next';
import { headers } from 'next/headers';
import { ReactNode } from 'react';

import AdminShell from '@/src/components/layout/admin-shell';
import MarketingShell from '@/src/components/layout/marketing-shell';
import PortalShell from '@/src/components/layout/portal-shell';
import { buildSiteMetadata, findSiteByHost, getSiteConfig } from '@/src/config/sites';

import '../styles/globals.css';

function resolveSiteFromRequest() {
  const headerList = headers();
  const host = headerList.get('host');
  return findSiteByHost(host) ?? getSiteConfig('marketing');
}

export async function generateMetadata(): Promise<Metadata> {
  const headerList = headers();
  const host = headerList.get('host');
  const site = findSiteByHost(host) ?? getSiteConfig('marketing');
  return buildSiteMetadata(site, host);
}

export default function RootLayout({ children }: { children: ReactNode }) {
  const site = resolveSiteFromRequest();

  return (
    <html lang="de" suppressHydrationWarning className="h-full">
      <body className="bg-page text-page">
        {site.key === 'marketing' ? (
          <MarketingShell>{children}</MarketingShell>
        ) : site.key === 'portal' ? (
          <PortalShell>{children}</PortalShell>
        ) : (
          <AdminShell>{children}</AdminShell>
        )}
      </body>
    </html>
  );
}
