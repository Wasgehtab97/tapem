import { NextResponse } from 'next/server';
import { createHash } from 'crypto';

import { getAdminUserFromSession } from '@/src/server/auth/session';
import { fetchGymsForMap } from '@/src/server/monitoring';
import type { MonitoringGymsFeatureCollection } from '@/src/types/monitoring';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

const CACHE_HEADER_VALUE = 'public, max-age=60';
const ERROR_HEADERS = new Headers({ 'Cache-Control': 'no-store' });

function buildEtag(payload: string): string {
  const hash = createHash('sha1').update(payload).digest('base64url');
  return `"${hash}"`;
}

function createRequestId(): string {
  return Math.random().toString(36).slice(2, 10);
}

function normalizeEtag(value: string): string {
  return value.trim().replace(/^W\//i, '');
}

function etagMatches(candidateHeader: string | null, etag: string): boolean {
  if (!candidateHeader) {
    return false;
  }
  const normalized = normalizeEtag(etag);
  return candidateHeader
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean)
    .some((value) => {
      if (value === '*') {
        return true;
      }
      return normalizeEtag(value) === normalized;
    });
}

export async function GET(request: Request) {
  const requestId = createRequestId();
  const logPrefix = `[admin-monitoring] ${requestId}`;
  try {
    const user = await getAdminUserFromSession();
    if (!user) {
      return NextResponse.json({ error: 'unauthorized', requestId }, { status: 401, headers: ERROR_HEADERS });
    }
    if (user.role !== 'admin' && user.role !== 'owner') {
      return NextResponse.json({ error: 'forbidden', requestId }, { status: 403, headers: ERROR_HEADERS });
    }

    const featureCollection: MonitoringGymsFeatureCollection = await fetchGymsForMap({ requestId });
    const body = JSON.stringify(featureCollection);
    const etag = buildEtag(body);
    const headers = new Headers({
      'Content-Type': 'application/geo+json; charset=utf-8',
      'Cache-Control': CACHE_HEADER_VALUE,
      ETag: etag,
    });

    const ifNoneMatch = request.headers.get('if-none-match');
    if (etagMatches(ifNoneMatch, etag)) {
      headers.delete('Content-Type');
      console.info(`${logPrefix} 304 cache-hit`);
      return new Response(null, { status: 304, headers });
    }

    console.info(
      `${logPrefix} features=${featureCollection.features.length} withCoords=${featureCollection.aggregates.withCoords} ` +
        `withoutCoords=${featureCollection.aggregates.withoutCoords}`
    );
    return new Response(body, { status: 200, headers });
  } catch (error) {
    console.error(`${logPrefix} failed`, error);
    return NextResponse.json({ error: 'internal_error', requestId }, { status: 500, headers: ERROR_HEADERS });
  }
}
