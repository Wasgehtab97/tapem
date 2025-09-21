import { NextResponse } from 'next/server';
import { getSession } from '@/src/server/auth/session';
import { isAdmin } from '@/src/server/auth/roles';
export const runtime = 'nodejs';

export async function GET() {
  const s = await getSession();
  if (!s) return NextResponse.json({ ok: false }, { status: 401 });
  return NextResponse.json({
    ok: true,
    uid: s.uid, email: (s as any).email ?? null,
    admin: await isAdmin(s.uid, (s as any).email ?? null),
  });
}
