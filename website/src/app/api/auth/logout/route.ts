import { NextResponse } from 'next/server';
import { clearSessionCookie } from '@/src/server/auth/session';
export const runtime = 'nodejs';

export async function POST() {
  const resp = new NextResponse(null, { status: 204 });
  clearSessionCookie(resp);
  return resp;
}
