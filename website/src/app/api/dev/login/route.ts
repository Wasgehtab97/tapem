import { NextResponse } from 'next/server';

import type { Role } from '@/src/lib/auth/types';

const ROLE_COOKIE = 'tapem_role';
const EMAIL_COOKIE = 'tapem_email';
const MAX_AGE = 60 * 60 * 24 * 7; // 7 Tage
const ROLES: Role[] = ['admin', 'owner', 'operator'];

function isProduction() {
  return process.env.VERCEL_ENV === 'production';
}

function parseRole(value: unknown): Role | undefined {
  if (typeof value === 'string' && ROLES.includes(value as Role)) {
    return value as Role;
  }

  return undefined;
}

export async function POST(request: Request) {
  if (isProduction()) {
    return new NextResponse('dev login disabled in production', { status: 403 });
  }

  const contentType = request.headers.get('content-type') ?? '';
  let role: Role | undefined;
  let email: string | undefined;

  if (contentType.includes('application/json')) {
    try {
      const payload = (await request.json()) as Partial<{ email: string; role: Role }>;
      role = parseRole(payload.role);
      email = payload.email?.trim();
    } catch {
      return NextResponse.json({ error: 'invalid json body' }, { status: 400 });
    }
  } else {
    const formData = await request.formData();
    role = parseRole(formData.get('role'));
    const rawEmail = formData.get('email');
    email = typeof rawEmail === 'string' ? rawEmail.trim() : undefined;
  }

  if (!role) {
    return NextResponse.json({ error: 'invalid role' }, { status: 400 });
  }

  const response = new NextResponse(null, { status: 204 });
  const secure = process.env.NODE_ENV === 'production';

  response.cookies.set({
    name: ROLE_COOKIE,
    value: role,
    httpOnly: true,
    sameSite: 'lax',
    maxAge: MAX_AGE,
    path: '/',
    secure,
  });

  response.cookies.set({
    name: EMAIL_COOKIE,
    value: email && email.length > 0 ? email : '',
    httpOnly: true,
    sameSite: 'lax',
    maxAge: MAX_AGE,
    path: '/',
    secure,
  });

  return response;
}
