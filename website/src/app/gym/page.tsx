import { requireRole } from '@/src/lib/auth/server';
import { gymChallengesMock, gymLeaderboardMock, gymOverviewKpis } from '@/src/server/mocks/gym';

export default async function GymOverviewPage() {
  const { user } = await requireRole(['owner', 'operator', 'admin']);
  const highlightedChallenges = gymChallengesMock.slice(0, 2);
  const topLeaderboard = gymLeaderboardMock.slice(0, 3);

  return (
    <div className="space-y-12">
      <section className="space-y-4">
        <header>
          <p className="text-sm font-semibold uppercase tracking-wide text-slate-500">Gym Dashboard</p>
          <h1 className="mt-1 text-3xl font-semibold text-slate-900">Willkommen zurück, {user.email}</h1>
          <p className="mt-2 max-w-2xl text-sm text-slate-600">
            Dieses Operator-Dashboard zeigt Live-Metriken aus dem Tap&apos;em-Netzwerk. Die Daten sind
            aktuell noch Mock-Werte und werden später über Firestore und Realtime-Analytics gespeist.
          </p>
        </header>
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          {gymOverviewKpis.map((kpi) => (
            <article
              key={kpi.label}
              className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm"
            >
              <p className="text-sm font-medium text-slate-600">{kpi.label}</p>
              <p className="mt-2 text-2xl font-semibold text-slate-900">{kpi.value}</p>
              <p className="mt-1 text-xs text-emerald-600">{kpi.change}</p>
            </article>
          ))}
        </div>
      </section>
      <section className="grid gap-6 lg:grid-cols-2">
        <div className="space-y-4 rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <header>
            <h2 className="text-xl font-semibold text-slate-900">Aktive Challenges</h2>
            <p className="mt-1 text-sm text-slate-600">
              Top-Kampagnen, die deine Mitglieder aktuell motivieren.
            </p>
          </header>
          <ul className="space-y-4">
            {highlightedChallenges.map((challenge) => (
              <li key={challenge.id} className="rounded-md border border-slate-100 p-4">
                <h3 className="text-base font-semibold text-slate-900">{challenge.title}</h3>
                <p className="mt-1 text-sm text-slate-600">{challenge.description}</p>
                <div className="mt-3 flex items-center justify-between text-sm text-slate-500">
                  <span>{challenge.participants} Teilnehmende</span>
                  <span>Fortschritt: {challenge.progress}%</span>
                  <span>Endet am {challenge.endsOn}</span>
                </div>
              </li>
            ))}
          </ul>
          <p className="text-xs text-slate-500">
            Die Challenge-Daten stammen aus statischen Mocks. In Produktion werden sie dynamisch aus
            Firestore geladen.
          </p>
        </div>
        <div className="space-y-4 rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <header>
            <h2 className="text-xl font-semibold text-slate-900">Leaderboard (Top 3)</h2>
            <p className="mt-1 text-sm text-slate-600">
              Eine schnelle Vorschau auf die engagiertesten Mitglieder.
            </p>
          </header>
          <ol className="space-y-3">
            {topLeaderboard.map((entry) => (
              <li
                key={entry.id}
                className="flex items-center justify-between gap-4 rounded-md border border-slate-100 p-4"
              >
                <div className="flex items-center gap-3">
                  <span className="flex h-10 w-10 items-center justify-center rounded-full bg-slate-900 text-sm font-semibold text-white">
                    {entry.avatarInitials}
                  </span>
                  <div>
                    <p className="text-sm font-semibold text-slate-900">
                      #{entry.rank} {entry.member}
                    </p>
                    <p className="text-xs text-slate-500">Streak: {entry.streak} Tage</p>
                  </div>
                </div>
                <span className="text-lg font-semibold text-slate-900">{entry.points} XP</span>
              </li>
            ))}
          </ol>
          <p className="text-xs text-slate-500">
            Vollständige Ranglisten stehen im Leaderboard-Tab bereit. Die Live-Version wird später
            mit Realtime-Daten gespeist.
          </p>
        </div>
      </section>
    </div>
  );
}
