import type { AdminActivityEventRecord } from '@/src/types/admin-activity';

const defaultEmptyLabel = 'Keine Ereignisse vorhanden.';

const SEVERITY_STYLES: Record<string, string> = {
  info: 'bg-sky-100 text-sky-900 border-sky-200 dark:bg-sky-500/10 dark:text-sky-200 dark:border-sky-500/40',
  warning: 'bg-amber-100 text-amber-900 border-amber-200 dark:bg-amber-500/10 dark:text-amber-200 dark:border-amber-500/40',
  error: 'bg-rose-100 text-rose-900 border-rose-200 dark:bg-rose-500/10 dark:text-rose-200 dark:border-rose-500/40',
};

const SOURCE_LABELS: Record<string, string> = {
  device: 'Gerät',
  app: 'App',
  backend: 'Backend',
  admin: 'Admin',
  system: 'System',
};

function formatEventType(value: string): string {
  if (!value) {
    return 'unbekannt';
  }
  return value.replace(/\./g, ' › ');
}

function resolveSeverityStyle(value: string | undefined) {
  if (!value) {
    return SEVERITY_STYLES.info;
  }
  return SEVERITY_STYLES[value] ?? SEVERITY_STYLES.info;
}

function resolveSourceLabel(value: string | undefined) {
  if (!value) {
    return SOURCE_LABELS.system;
  }
  return SOURCE_LABELS[value] ?? value;
}

type AdminEventLogTableEntry = AdminActivityEventRecord;

export function AdminEventLogTable({
  entries,
  formatTimestamp,
  emptyLabel = defaultEmptyLabel,
  showGymColumn = true,
}: {
  entries: AdminEventLogTableEntry[];
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
              Ereignis
            </th>
            <th scope="col" className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted">
              Kontext
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-[color:var(--page-border)]">
          {entries.map((event) => {
            const severity = event.severity ?? 'info';
            const severityLabel = severity === 'info' ? 'Info' : severity === 'warning' ? 'Warnung' : 'Fehler';
            const sourceLabel = resolveSourceLabel(event.source);
            const contextItems: { label: string; value: string }[] = [];
            if (showGymColumn && event.gymId) {
              contextItems.push({ label: 'Gym', value: event.gymId });
            }
            if (event.deviceId) {
              contextItems.push({ label: 'Gerät', value: event.deviceId });
            }
            if (event.userId) {
              contextItems.push({ label: 'User', value: event.userId });
            }
            if (event.sessionId) {
              contextItems.push({ label: 'Session', value: event.sessionId });
            }
            if (event.actor?.id) {
              contextItems.push({ label: `Actor:${event.actor.type}`, value: event.actor.id });
            }
            (event.targets ?? []).forEach((target) => {
              if (target.id) {
                contextItems.push({ label: target.type, value: target.id });
              }
            });

            const payloadEntries = Object.entries(event.data ?? {}).slice(0, 6);

            return (
              <tr key={`${event.id}-${event.timestamp.toISOString()}`} className="align-top hover:bg-card-muted">
                <td className="whitespace-nowrap px-4 py-3 text-sm text-page">{formatTimestamp(event.timestamp)}</td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-muted">
                  {showGymColumn ? (event.gymId ? `Gym ${event.gymId}` : '–') : null}
                  {showGymColumn && event.deviceId ? ` · Gerät ${event.deviceId}` : null}
                  {!showGymColumn ? (event.deviceId ? `Gerät ${event.deviceId}` : '–') : null}
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap items-center gap-2">
                    <span
                      className={`inline-flex items-center rounded-full border px-2 py-0.5 text-xs font-semibold ${resolveSeverityStyle(
                        severity
                      )}`}
                    >
                      {severityLabel}
                    </span>
                    <span className="text-sm font-semibold text-page">{formatEventType(event.eventType)}</span>
                    <span className="text-xs text-muted">{sourceLabel}</span>
                  </div>
                  {event.summary ? <p className="mt-2 text-sm text-page">{event.summary}</p> : null}
                </td>
                <td className="px-4 py-3">
                  {contextItems.length > 0 ? (
                    <dl className="flex flex-wrap gap-2 text-xs text-muted">
                      {contextItems.map((item) => (
                        <div key={`${event.id}-${item.label}-${item.value}`} className="flex items-center gap-1 rounded border border-subtle px-2 py-1">
                          <dt className="font-semibold uppercase tracking-wide">{item.label}</dt>
                          <dd className="font-mono text-[11px] text-page">{item.value}</dd>
                        </div>
                      ))}
                    </dl>
                  ) : (
                    <p className="text-xs text-muted">Keine Referenzen</p>
                  )}
                  {payloadEntries.length > 0 ? (
                    <div className="mt-3 space-y-1">
                      <p className="text-xs font-semibold uppercase tracking-wide text-muted">Details</p>
                      <dl className="grid gap-1 text-xs">
                        {payloadEntries.map(([key, value]) => (
                          <div key={key} className="grid grid-cols-[auto,1fr] items-start gap-2">
                            <dt className="font-semibold text-muted">{key}</dt>
                            <dd className="font-mono text-[11px] text-page">
                              {typeof value === 'boolean' ? (value ? 'true' : 'false') : String(value)}
                            </dd>
                          </div>
                        ))}
                      </dl>
                    </div>
                  ) : null}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
