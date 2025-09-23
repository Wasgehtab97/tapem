import type { Timestamp } from 'firebase-admin/firestore';

export type ActivityEventSeverity = 'info' | 'warning' | 'error';
export type ActivityEventSource = 'device' | 'app' | 'backend' | 'admin' | 'system';
export type ActivityActorType = 'user' | 'system' | 'admin';

export type AdminActivityActor = {
  type: ActivityActorType;
  id?: string | null;
  label?: string | null;
};

export type AdminActivityTarget = {
  type: string;
  id?: string | null;
  label?: string | null;
};

export type AdminActivityEvent = {
  id: string;
  gymId: string;
  timestamp: string;
  eventType: string;
  severity: ActivityEventSeverity;
  source: ActivityEventSource;
  summary: string | null;
  userId?: string | null;
  deviceId?: string | null;
  sessionId?: string | null;
  actor?: AdminActivityActor | null;
  targets?: AdminActivityTarget[];
  data?: Record<string, unknown> | null;
};

export type AdminActivityEventRecord = Omit<AdminActivityEvent, 'timestamp'> & {
  timestamp: Date;
};

export type FirestoreActivityEvent = Omit<AdminActivityEvent, 'timestamp'> & {
  timestamp: Timestamp;
};

export type ActivityEventStats = {
  total: number;
  last24h: number;
  last7d: number;
  last30d: number;
};

export type GymActivityResponse = {
  items: AdminActivityEvent[];
  nextCursor: string | null;
  stats: ActivityEventStats;
  requestId: string;
  warnings?: string[];
};
