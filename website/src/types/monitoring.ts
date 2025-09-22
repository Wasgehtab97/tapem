export type MonitoringGymFeatureProperties = {
  id: string;
  name: string;
  slug: string;
  code: string | null;
  countryCode: string;
  active: boolean;
  statusUpdatedAt: string | null;
};

export type MonitoringGymFeature = {
  type: 'Feature';
  geometry: { type: 'Point'; coordinates: [number, number] };
  properties: MonitoringGymFeatureProperties;
};

export type MonitoringGymsAggregates = {
  total: number;
  withCoords: number;
  withoutCoords: number;
};

export type MonitoringGymsFeatureCollection = {
  type: 'FeatureCollection';
  features: MonitoringGymFeature[];
  aggregates: MonitoringGymsAggregates;
};
