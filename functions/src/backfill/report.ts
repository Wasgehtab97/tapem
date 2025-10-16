import { BuildArtifacts, ReportData, ScanResult, WriterStats } from './types';

function ensureGymReport(
  container: Record<string, {
    logs: number;
    devices: Record<string, number>;
    users: Record<string, number>;
    days: Record<string, number>;
  }>,
  gymId: string,
) {
  if (!container[gymId]) {
    container[gymId] = {
      logs: 0,
      devices: {},
      users: {},
      days: {},
    };
  }
  return container[gymId];
}

export function buildReport(
  scanResults: ScanResult[],
  artifacts: BuildArtifacts,
  writerStats: WriterStats,
  applied: boolean,
): ReportData {
  const gyms: ReportData['gyms'] = {};
  const users: ReportData['users'] = {};
  const orphans: ReportData['orphans'] = [];

  for (const scan of scanResults) {
    const gymEntry = ensureGymReport(gyms, scan.gymId);
    gymEntry.logs += scan.metrics.totalLogs;
    for (const [deviceKey, count] of scan.metrics.deviceLogCounts.entries()) {
      const [, deviceId] = deviceKey.split('::');
      gymEntry.devices[deviceId] = (gymEntry.devices[deviceId] ?? 0) + count;
    }
    for (const [userKey, count] of scan.metrics.userLogCounts.entries()) {
      gymEntry.users[userKey] = (gymEntry.users[userKey] ?? 0) + count;
      users[userKey] = users[userKey] || { logs: 0, days: 0 };
      users[userKey].logs += count;
    }
    for (const [dayComposite, count] of scan.metrics.dayLogCounts.entries()) {
      const [, dayKey] = dayComposite.split('::');
      gymEntry.days[dayKey] = (gymEntry.days[dayKey] ?? 0) + count;
    }
    orphans.push(...scan.metrics.orphans);
  }

  for (const doc of artifacts.daily.values()) {
    users[doc.userId] = users[doc.userId] || { logs: 0, days: 0 };
    users[doc.userId].days += 1;
  }

  return {
    gyms,
    users,
    orphans,
    multiGymPerDay: artifacts.multiGymPerDay,
    skippedExisting: writerStats.skipped,
    written: writerStats.written,
    applied,
  };
}
