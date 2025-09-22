import { NextResponse } from 'next/server';
import { createHash } from 'crypto';

import { getAdminUserFromSession } from '@/src/server/auth/session';
import { fetchGymsForMap } from '@/src/server/monitoring';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

const CACHE_HEADER_VALUE = 'private, max-age=60';
const EMPTY_HEADERS = new Headers({ 'Cache-Control': CACHE_HEADER_VALUE });

function buildEtag(payload: string): string {
  const hash = createHash('sha1').update(payload).digest('base64url');
  return `"${hash}"`;
}

export async function GET(request: Request) {
  const debugId = Math.random().toString(36).slice(2, 8);
  try {
    const user = await getAdminUserFromSession();
    if (!user) {
      return NextResponse.json({ error: 'unauthorized', requestId: debugId }, { status: 401, headers: EMPTY_HEADERS });
    }
    if (user.role !== 'admin' && user.role !== 'owner') {
      return NextResponse.json({ error: 'forbidden', requestId: debugId }, { status: 403, headers: EMPTY_HEADERS });
    }

    const { gyms, total, missingLocation } = await fetchGymsForMap();
    const featureCollection = {
      type: 'FeatureCollection' as const,
      features: gyms.map((gym) => ({
        type: 'Feature' as const,
        geometry: {
          type: 'Point' as const,
          coordinates: [gym.location.lng, gym.location.lat],
        },
        properties: {
          id: gym.id,
          name: gym.name,
          slug: gym.slug,
          city: gym.city ?? null,
          state: gym.state ?? null,
          status: gym.status?.status ?? null,
          checkins24h: gym.status?.checkins24h ?? null,
          devicesOnline: gym.status?.devicesOnline ?? null,
        },
      })),
      meta: {
        total,
        missingLocation,
      },
    };

    const body = JSON.stringify(featureCollection);
    const etag = buildEtag(body);
    const headers = new Headers({
      'Content-Type': 'application/geo+json; charset=utf-8',
      'Cache-Control': CACHE_HEADER_VALUE,
      ETag: etag,
    });

    const ifNoneMatch = request.headers.get('if-none-match');
    if (ifNoneMatch && ifNoneMatch.replace(/^W\//, '') === etag.replace(/^W\//, '')) {
      return new Response(null, { status: 304, headers });
    }

    console.info(`[admin-monitoring] ${debugId} gyms=${gyms.length} missing=${missingLocation}`);
    return new Response(body, { status: 200, headers });
  } catch (error) {
    console.error(`[admin-monitoring] ${debugId} failed`, error);
    return NextResponse.json({ error: 'internal_error', requestId: debugId }, { status: 500, headers: EMPTY_HEADERS });
  }
}
