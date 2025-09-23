import { NextResponse } from 'next/server';
import { createHash } from 'crypto';

import { getAdminUserFromSession } from '@/src/server/auth/session';
import { fetchActivityEventsForGym } from '@/src/server/activity/events';
import type { GymActivityResponse } from '@/src/types/admin-activity';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const revalidate = 0;

const CACHE_HEADER_VALUE = 'private, max-age=30';
const ERROR_HEADERS = new Headers({ 'Cache-Control': 'no-store' });

function createRequestId(): string {
  return Math.random().toString(36).slice(2, 10);
}

function buildEtag(payload: string): string {
  const hash = createHash('sha1').update(payload).digest('base64url');
  return `"${hash}"`;
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

function parseList(single: string | null, multi: string[]): string[] {
  const values: string[] = [];
  const sources = multi.length > 0 ? multi : single ? [single] : [];
  sources.forEach((entry) => {
    entry
      .split(',')
      .map((token) => token.trim())
      .filter(Boolean)
      .forEach((token) => {
        if (!values.includes(token)) {
          values.push(token);
        }
      });
  });
  return values.slice(0, 10);
}

function parseDate(value: string | null): Date | null {
  if (!value) {
    return null;
  }
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function sanitizeId(value: string | null): string | null {
  if (!value) {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

export async function GET(request: Request, { params }: { params: { gymId: string } }) {
  const requestId = createRequestId();
  const logPrefix = `[admin-monitoring] events ${requestId}`;
  try {
    const user = await getAdminUserFromSession();
    if (!user) {
      return NextResponse.json({ error: 'unauthorized', requestId }, { status: 401, headers: ERROR_HEADERS });
    }
    if (user.role !== 'admin' && user.role !== 'owner') {
      return NextResponse.json({ error: 'forbidden', requestId }, { status: 403, headers: ERROR_HEADERS });
    }

    const url = new URL(request.url);
    const searchParams = url.searchParams;
    const limitRaw = searchParams.get('limit');
    const limit = limitRaw ? Number.parseInt(limitRaw, 10) : 50;
    if (Number.isNaN(limit) || limit < 1 || limit > 200) {
      return NextResponse.json({ error: 'invalid_limit', requestId }, { status: 400, headers: ERROR_HEADERS });
    }

    const from = parseDate(searchParams.get('from'));
    const to = parseDate(searchParams.get('to'));
    if ((from && to && from > to) || (from && Number.isNaN(from.getTime())) || (to && Number.isNaN(to.getTime()))) {
      return NextResponse.json({ error: 'invalid_range', requestId }, { status: 400, headers: ERROR_HEADERS });
    }

    const types = parseList(searchParams.get('types'), searchParams.getAll('types'));
    const severity = parseList(searchParams.get('severity'), searchParams.getAll('severity')).filter((value) =>
      value === 'info' || value === 'warning' || value === 'error'
    );
    const userId = sanitizeId(searchParams.get('userId'));
    const deviceId = sanitizeId(searchParams.get('deviceId'));
    const cursor = searchParams.get('cursor');

    const result = await fetchActivityEventsForGym(params.gymId, {
      limit,
      from,
      to,
      eventTypes: types,
      severity: severity.length > 0 ? (severity as ('info' | 'warning' | 'error')[]) : undefined,
      userId: userId ?? undefined,
      deviceId: deviceId ?? undefined,
      cursor: cursor ?? undefined,
    });

    const payload: GymActivityResponse = {
      items: result.items.map((item) => ({
        id: item.id,
        gymId: item.gymId,
        timestamp: item.timestamp.toISOString(),
        eventType: item.eventType,
        severity: item.severity,
        source: item.source,
        summary: item.summary ?? null,
        userId: item.userId ?? null,
        deviceId: item.deviceId ?? null,
        sessionId: item.sessionId ?? null,
        actor: item.actor ?? null,
        targets: item.targets ?? [],
        data: item.data ?? null,
      })),
      nextCursor: result.nextCursor,
      stats: result.stats,
      requestId,
      warnings: result.warnings,
    };

    const body = JSON.stringify(payload);
    const etag = buildEtag(body);
    const headers = new Headers({
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': CACHE_HEADER_VALUE,
      ETag: etag,
    });

    const ifNoneMatch = request.headers.get('if-none-match');
    if (etagMatches(ifNoneMatch, etag)) {
      headers.delete('Content-Type');
      return new Response(null, { status: 304, headers });
    }

    console.info(
      `${logPrefix} gym=${params.gymId} items=${payload.items.length} limit=${limit} cursor=${cursor ? 'yes' : 'no'}`
    );
    return new Response(body, { status: 200, headers });
  } catch (error) {
    console.error(`${logPrefix} failed`, error);
    return NextResponse.json({ error: 'internal_error', requestId }, { status: 500, headers: ERROR_HEADERS });
  }
}
