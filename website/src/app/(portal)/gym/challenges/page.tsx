import { requireRole } from '@/lib/auth/server';
import { gymChallengesMock } from '@/server/mocks/gym';

export default async function GymChallengesPage() {
  await requireRole(['owner', 'operator', 'admin']);

  return (
    <section className="space-y-6">
      <header className="space-y-2">
        <h1 className="text-2xl font-semibold text-page">Challenges & Kampagnen</h1>
        <p className="text-sm text-muted">
          Aktuelle Engagement-Programme. Die Fortschrittsbalken werden später aus Echtzeitmetriken
          gespeist.
        </p>
      </header>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {gymChallengesMock.map((challenge) => (
          <article key={challenge.id} className="space-y-4 rounded-lg border border-subtle bg-card p-6 shadow-sm">
            <header className="space-y-1">
              <p className="text-xs font-medium uppercase tracking-wide text-muted">
                Challenge #{challenge.id}
              </p>
              <h2 className="text-lg font-semibold text-page">{challenge.title}</h2>
            </header>
            <p className="text-sm text-muted">{challenge.description}</p>
            <div>
              <div className="flex items-center justify-between text-xs font-medium text-muted">
                <span>{challenge.participants} Teilnehmende</span>
                <span>Endet am {challenge.endsOn}</span>
              </div>
              <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-card-muted">
                <div
                  className="h-full rounded-full bg-primary"
                  style={{ width: `${challenge.progress}%` }}
                  role="presentation"
                />
              </div>
              <p className="mt-1 text-xs text-muted">Fortschritt: {challenge.progress}%</p>
            </div>
            <footer className="text-xs text-muted">
              Die Anbindung an Tap&apos;em Challenges API folgt. Bis dahin dienen Mock-Daten zur UX-
              Abstimmung.
            </footer>
          </article>
        ))}
      </div>
    </section>
  );
}
