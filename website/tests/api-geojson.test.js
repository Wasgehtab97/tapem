import { test } from 'node:test';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

test('GeoJSON admin API exposes secure caching headers and properties', () => {
  const routePath = resolve(process.cwd(), 'src/app/api/admin/gyms.geojson/route.ts');
  const routeContent = readFileSync(routePath, 'utf8');
  assert.match(routeContent, /FeatureCollection/, 'Response should include FeatureCollection type');
  assert.match(routeContent, /const CACHE_HEADER_VALUE = 'public, max-age=60';/, 'API must use public cache control');

  const serverPath = resolve(process.cwd(), 'src/server/monitoring.ts');
  const serverContent = readFileSync(serverPath, 'utf8');
  assert.match(
    serverContent,
    /const DACH_COUNTRY_CODES = \['DE', 'AT', 'CH', 'GB'\] as const;/,
    'Monitoring query should include British gyms'
  );
  assert.match(
    serverContent,
    /properties:\s*\{\s*id: doc.id,\s*name,\s*slug,\s*code,/s,
    'GeoJSON features should expose id, name, slug and code'
  );
  assert.match(serverContent, /gyms: listItems/, 'GeoJSON response should include the gyms list for the UI');
  assert.match(
    serverContent,
    /const aggregates: MonitoringGymsAggregates = \{\s*total:/,
    'Aggregates should be calculated on the server'
  );
});
