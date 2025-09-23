export type MonitoringGymFeatureProperties = {
  id: string;
  name: string;
  slug: string;
  code: string | null;
  countryCode: string;
  active: boolean;
  statusUpdatedAt: string | null;
};

export type MonitoringGymLocation = {
  lat: number;
  lng: number;
};

export type MonitoringGymListItem = {
  id: string;
  name: string;
  slug: string;
  code: string | null;
  countryCode: string | null;
  active: boolean;
  location: MonitoringGymLocation | null;
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
  gyms: MonitoringGymListItem[];
};
