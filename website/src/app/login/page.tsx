import type { Metadata } from 'next';
import LoginForm from './login-form';

export const metadata: Metadata = {
  title: 'Login – Tap\'em (Dev-Stub)',
  robots: { index: false, follow: false },
};

export default function Page() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">Anmelden (Dev-Stub)</h1>
      <p className="text-sm text-slate-600">
        Diese Anmeldung setzt nur Vorschau-Cookies und dient dem Testen der geschützten Bereiche. In Production ist der
        Dev-Login deaktiviert.
      </p>
      <LoginForm />
    </div>
  );
}
