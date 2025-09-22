import type { AdminEventLogEntry } from '@/src/server/admin/dashboard-data';

const defaultEmptyLabel = 'Keine Ereignisse vorhanden.';

export function AdminEventLogTable({
  entries,
  formatTimestamp,
  emptyLabel = defaultEmptyLabel,
  showGymColumn = true,
}: {
  entries: AdminEventLogEntry[];
  formatTimestamp: (value: Date) => string;
  emptyLabel?: string;
  showGymColumn?: boolean;
}) {
  if (entries.length === 0) {
    return (
      <div className="rounded-md border border-dashed border-subtle bg-card-muted px-4 py-6 text-sm text-muted">
        {emptyLabel}
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-[color:var(--page-border)]">
        <thead className="bg-card-muted">
          <tr>
            <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
              Zeitstempel
            </th>
            {showGymColumn ? (
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Gym / Gerät
              </th>
            ) : (
              <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                Gerät
              </th>
            )}
            <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
              Typ
            </th>
            <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
              Details
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-[color:var(--page-border)]">
          {entries.map((event) => (
            <tr key={`${event.id}-${event.timestamp.toISOString()}`} className="hover:bg-card-muted">
              <td className="whitespace-nowrap px-4 py-3 text-sm text-page">{formatTimestamp(event.timestamp)}</td>
              <td className="whitespace-nowrap px-4 py-3 text-sm text-muted">
                {showGymColumn ? (event.gymId ? `Gym ${event.gymId}` : '–') : null}
                {showGymColumn && event.deviceId ? ` · Gerät ${event.deviceId}` : null}
                {!showGymColumn ? (event.deviceId ? `Gerät ${event.deviceId}` : '–') : null}
              </td>
              <td className="whitespace-nowrap px-4 py-3 text-sm font-medium text-page">{event.type ?? 'log'}</td>
              <td className="px-4 py-3 text-sm text-page">{event.description ?? 'Keine Beschreibung'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
