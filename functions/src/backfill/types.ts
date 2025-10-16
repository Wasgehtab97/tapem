import { Timestamp } from 'firebase-admin/firestore';

export interface ScanOptions {
  from?: Timestamp | Date | string | number;
  to?: Timestamp | Date | string | number;
  userId?: string;
  pageSize?: number;
}

export interface SessionMeta {
  dayKey?: string;
  timezone?: string;
  offsetMinutes?: number;
}

export interface LogDocument {
  id: string;
  gymId: string;
  deviceId: string;
  timestamp: Timestamp;
  userId?: string | null;
  sessionId?: string | null;
  timezone?: string | null;
  offsetMinutes?: number | null;
  sessionMeta?: SessionMeta | null;
}

export interface SessionAccumulator {
  count: number;
  deviceCounts: Map<string, number>;
  gymCounts: Map<string, number>;
}

export interface DayAccumulator {
  userId: string;
  dayKey: string;
  dayTimestamp: Timestamp;
  timezone: string;
  logCount: number;
  sessionCounts: Map<string, SessionAccumulator>;
  deviceCounts: Map<string, number>;
  gymCounts: Map<string, number>;
  sessionIds: Set<string>;
}

export interface DeviceSessionRecord {
  count: number;
  lastTimestamp: number;
  dayKeys: Set<string>;
}

export interface DeviceAccumulator {
  gymId: string;
  deviceId: string;
  sessions: Map<string, DeviceSessionRecord>;
  lastActive: number | null;
  dayKeys: Set<string>;
  userIds: Set<string>;
}

export interface ScanMetrics {
  totalLogs: number;
  deviceLogCounts: Map<string, number>;
  userLogCounts: Map<string, number>;
  dayLogCounts: Map<string, number>;
  orphans: Array<{ path: string; reason: string }>;
}

export interface ScanResult {
  gymId: string;
  days: Map<string, DayAccumulator>;
  devices: Map<string, DeviceAccumulator>;
  metrics: ScanMetrics;
}

export interface DailySummarySession {
  count: number;
  gymId: string;
  deviceId: string;
}

export interface DailySummaryDoc {
  userId: string;
  dateKey: string;
  date: Timestamp;
  logCount: number;
  totalSessions: number;
  sessionCounts: Record<string, DailySummarySession>;
  deviceCounts: Record<string, number>;
  gymId: string;
}

export interface AggregateSummaryDoc {
  userId: string;
  gymId: string;
  trainingDayCount: number;
  totalSessions: number;
  firstWorkoutDate: Timestamp | null;
  lastWorkoutDate: Timestamp | null;
  deviceCounts: Record<string, number>;
}

export interface DeviceUsageDoc {
  gymId: string;
  deviceId: string;
  totalSessions: number;
  rangeCounts: Record<string, number>;
  lastActive: Timestamp | null;
  recentDates: string[];
}

export interface WriterStats {
  attempted: number;
  written: number;
  skipped: number;
}

export interface ReportData {
  gyms: Record<string, {
    logs: number;
    devices: Record<string, number>;
    users: Record<string, number>;
    days: Record<string, number>;
  }>;
  users: Record<string, {
    logs: number;
    days: number;
  }>;
  orphans: Array<{ path: string; reason: string }>;
  multiGymPerDay: Record<string, Record<string, string[]>>;
  skippedExisting: number;
  written: number;
  applied: boolean;
}

export interface BuildArtifacts {
  daily: Map<string, DailySummaryDoc>;
  aggregates: Map<string, AggregateSummaryDoc>;
  devices: Map<string, DeviceUsageDoc>;
  multiGymPerDay: Record<string, Record<string, string[]>>;
}

export interface BackfillRunParams {
  gymId?: string;
  userId?: string;
  from?: Timestamp | Date | string | number;
  to?: Timestamp | Date | string | number;
  apply?: boolean;
}

export interface BackfillVerifyParams {
  userId: string;
  from?: Timestamp | Date | string | number;
  to?: Timestamp | Date | string | number;
}

export interface VerificationDiff {
  daily: {
    missing: string[];
    extra: string[];
    mismatched: Array<{ dateKey: string; expected: DailySummaryDoc; actual: DailySummaryDoc }>;
  };
  aggregate: {
    expected: AggregateSummaryDoc | null;
    actual: AggregateSummaryDoc | null;
  };
  devices: {
    missing: Array<{ gymId: string; deviceId: string; expected: DeviceUsageDoc }>;
    extra: Array<{ gymId: string; deviceId: string; actual: DeviceUsageDoc }>;
    mismatched: Array<{ gymId: string; deviceId: string; expected: DeviceUsageDoc; actual: DeviceUsageDoc }>;
  };
}
