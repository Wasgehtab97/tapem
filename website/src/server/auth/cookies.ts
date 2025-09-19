import 'server-only';

import { findSiteByHost, normalizeHost } from '@/src/config/sites';

function isLocalHost(hostname: string): boolean {
  return hostname.includes('localhost') || hostname.startsWith('127.');
}

export function resolveCookieDomain(request: Request): string | undefined {
  const hostHeader = request.headers.get('host');
  const normalized = normalizeHost(hostHeader);
  if (!normalized) {
    return undefined;
  }

  const [hostname] = normalized.split(':');
  if (!hostname || isLocalHost(hostname)) {
    return undefined;
  }

  const site = findSiteByHost(normalized) ?? findSiteByHost(hostname);
  if (!site) {
    return undefined;
  }

  return hostname;
}

export function resolveCookieSecurity(request: Request): boolean {
  const hostHeader = request.headers.get('host');
  const normalized = normalizeHost(hostHeader);
  if (!normalized) {
    return true;
  }

  const [hostname] = normalized.split(':');
  if (!hostname) {
    return true;
  }

  return !isLocalHost(hostname);
}
