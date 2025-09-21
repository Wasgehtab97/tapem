import type { Metadata, Viewport } from 'next';
import { headers } from 'next/headers';
import { ReactNode } from 'react';

import AdminShell from '@/components/layout/admin-shell';
import { SITE_THEME_COLORS, buildSiteMetadata, getSiteConfig } from '@/config/sites';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function generateMetadata(): Promise<Metadata> {
  const headerList = headers();
  const host = headerList.get('host');
  return buildSiteMetadata(getSiteConfig('admin'), host);
}

export const viewport: Viewport = {
  themeColor: SITE_THEME_COLORS,
};

export default function AdminLayout({ children }: { children: ReactNode }) {
  return <AdminShell>{children}</AdminShell>;
}
