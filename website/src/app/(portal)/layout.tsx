import type { Metadata } from 'next';
import { headers } from 'next/headers';
import { ReactNode } from 'react';

import PortalShell from '@/src/components/layout/portal-shell';
import { buildSiteMetadata, getSiteConfig } from '@/src/config/sites';

export async function generateMetadata(): Promise<Metadata> {
  const headerList = headers();
  const host = headerList.get('host');
  return buildSiteMetadata(getSiteConfig('portal'), host);
}

export default function PortalLayout({ children }: { children: ReactNode }) {
  return <PortalShell>{children}</PortalShell>;
}
