'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

import type { Role } from '@/src/lib/auth/types';

const quickRoles: Role[] = ['owner', 'operator', 'admin'];

type PendingAction = Role | 'logout' | null;

type DevToolbarProps = {
  currentRole: Role | null;
};

export default function DevToolbar({ currentRole }: DevToolbarProps) {
  const router = useRouter();
  const [pending, setPending] = useState<PendingAction>(null);
  const [error, setError] = useState<string | null>(null);

  async function post(endpoint: string, body?: Record<string, unknown>) {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: body ? { 'Content-Type': 'application/json' } : undefined,
      body: body ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      const message =
        response.status === 403
          ? 'Dev-Login ist in Production deaktiviert.'
          : 'Aktion fehlgeschlagen. Bitte erneut versuchen.';
      throw new Error(message);
    }
  }

  async function handleSwitchRole(role: Role) {
    try {
      setPending(role);
      setError(null);
      await post('/api/dev/login', { role });
      router.refresh();
    } catch (err) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Aktion fehlgeschlagen.');
      }
    } finally {
      setPending(null);
    }
  }

  async function handleLogout() {
    try {
      setPending('logout');
      setError(null);
      await post('/api/dev/logout');
      router.refresh();
    } catch (err) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Aktion fehlgeschlagen.');
      }
    } finally {
      setPending(null);
    }
  }

  return (
    <div className="flex flex-col items-end gap-1 text-xs text-muted">
      <div className="flex items-center gap-2">
        <span className="rounded-full border border-subtle bg-card-muted px-3 py-1 font-medium text-muted">
          Rolle: {currentRole ?? 'anonym'}
        </span>
        {quickRoles.map((role) => (
          <button
            key={role}
            type="button"
            onClick={() => handleSwitchRole(role)}
            className="rounded border border-subtle bg-card px-3 py-1 font-medium text-muted transition hover:bg-card-muted focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:cursor-not-allowed disabled:opacity-60"
            disabled={pending !== null}
          >
            Als {role}
          </button>
        ))}
        <button
          type="button"
          onClick={handleLogout}
          className="rounded border border-subtle bg-card px-3 py-1 font-medium text-muted transition hover:bg-card-muted focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:cursor-not-allowed disabled:opacity-60"
          disabled={pending !== null}
        >
          Logout
        </button>
      </div>
      {pending ? (
        <p className="text-[11px] text-slate-500">{pending === 'logout' ? 'Abmelden…' : `Wechsel zu ${pending}…`}</p>
      ) : null}
      {error ? (
        <p className="text-[11px] text-red-600" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}
