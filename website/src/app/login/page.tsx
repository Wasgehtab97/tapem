import LoginForm from './login-form';

function getNextPath(searchParams?: Record<string, string | string[] | undefined>) {
  const nextParam = searchParams?.next;
  const nextValue = Array.isArray(nextParam) ? nextParam[0] : nextParam;

  if (typeof nextValue === 'string' && nextValue.startsWith('/')) {
    return nextValue;
  }

  return '/gym';
}

export default function LoginPage({
  searchParams,
}: {
  searchParams?: Record<string, string | string[] | undefined>;
}) {
  const nextPath = getNextPath(searchParams);

  return (
    <div className="mx-auto flex min-h-[70vh] w-full max-w-xl flex-col gap-8 px-6 py-12">
      <div className="rounded-md border border-amber-400 bg-amber-50 p-4 text-amber-900">
        <p className="font-semibold">Dev-Login (Stub)</p>
        <p className="mt-1 text-sm">
          Dieser Login dient nur für Entwicklung und Previews. Firebase Auth wird später
          angebunden.
        </p>
      </div>
      <div className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <h1 className="text-2xl font-semibold text-slate-900">Anmeldung</h1>
        <p className="mt-1 text-sm text-slate-600">
          Wähle eine Rolle und (optional) eine E-Mail-Adresse. Nach der Anmeldung wirst du zum
          gewünschten Bereich weitergeleitet.
        </p>
        <LoginForm nextPath={nextPath} />
      </div>
    </div>
  );
}
