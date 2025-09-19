'use client';

import { FormEvent, useState } from 'react';
import { useRouter } from 'next/navigation';

import type { Role } from '@/src/lib/auth/types';

const roles: Role[] = ['admin', 'owner', 'operator'];

export default function LoginForm({ nextPath }: { nextPath: string }) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    const formData = new FormData(event.currentTarget);
    const email = formData.get('email')?.toString().trim();
    const role = formData.get('role')?.toString() as Role | undefined;

    if (!role) {
      setError('Bitte eine Rolle auswählen.');
      return;
    }

    setIsSubmitting(true);

    const response = await fetch('/api/dev/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: email && email.length > 0 ? email : undefined,
        role,
      }),
    });

    setIsSubmitting(false);

    if (!response.ok) {
      const message =
        response.status === 403
          ? 'Dev-Login ist in Production deaktiviert.'
          : 'Login fehlgeschlagen. Bitte erneut versuchen.';
      setError(message);
      return;
    }

    router.push(nextPath || '/gym');
    router.refresh();
  }

  return (
    <form className="mt-6 space-y-5" onSubmit={handleSubmit}>
      <input name="next" type="hidden" value={nextPath} />
      <div className="flex flex-col gap-2">
        <label className="text-sm font-medium text-slate-700" htmlFor="email">
          E-Mail-Adresse (optional)
        </label>
        <input
          id="email"
          name="email"
          type="email"
          placeholder="dev@example.com"
          className="rounded-md border border-slate-300 px-3 py-2 text-base text-slate-900 shadow-sm focus:border-slate-900 focus:outline-none focus:ring-2 focus:ring-slate-900/20"
          autoComplete="email"
        />
      </div>
      <div className="flex flex-col gap-2">
        <label className="text-sm font-medium text-slate-700" htmlFor="role">
          Rolle
        </label>
        <select
          id="role"
          name="role"
          className="rounded-md border border-slate-300 px-3 py-2 text-base text-slate-900 shadow-sm focus:border-slate-900 focus:outline-none focus:ring-2 focus:ring-slate-900/20"
          defaultValue="owner"
        >
          <option value="" disabled>
            Rolle auswählen
          </option>
          {roles.map((roleOption) => (
            <option key={roleOption} value={roleOption}>
              {roleOption}
            </option>
          ))}
        </select>
      </div>
      {error ? (
        <p className="text-sm text-red-600" role="alert">
          {error}
        </p>
      ) : null}
      <button
        type="submit"
        className="w-full rounded-md bg-slate-900 px-4 py-2 text-center text-sm font-semibold text-white shadow-sm transition hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-slate-900/40 disabled:cursor-not-allowed disabled:opacity-75"
        disabled={isSubmitting}
      >
        {isSubmitting ? 'Anmeldung…' : 'Einloggen'}
      </button>
    </form>
  );
}
