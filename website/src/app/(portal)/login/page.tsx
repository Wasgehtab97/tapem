import type { Metadata } from 'next';
import { Suspense } from 'react';

import LoginForm from './login-form';

export const metadata: Metadata = {
  title: "Login – Tap'em (Dev-Stub)",
  robots: { index: false, follow: false },
};

export default function Page() {
  return (
    <div className="mx-auto w-full max-w-xl space-y-6 px-6 py-16">
      <h1 className="text-2xl font-semibold">Anmelden (Dev-Stub)</h1>
      <p className="text-sm text-muted">
        Diese Anmeldung setzt Vorschau-Cookies und dient dem Testen der geschützten Bereiche. In Production ist der Dev-Login
        deaktiviert.
      </p>
      <Suspense
        fallback={
          <div className="rounded border border-subtle bg-card p-4 text-sm text-muted" aria-live="polite">
            Lade Login-Parameter…
          </div>
        }
      >
        <LoginForm />
      </Suspense>
    </div>
  );
}
