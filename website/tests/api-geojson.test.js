import { test } from 'node:test';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

test('GeoJSON admin API exposes secure caching headers and properties', () => {
  const filePath = resolve(process.cwd(), 'src/app/api/admin/gyms.geojson/route.ts');
  const content = readFileSync(filePath, 'utf8');
  assert.match(content, /FeatureCollection/, 'Response should include FeatureCollection type');
  assert.match(content, /const CACHE_HEADER_VALUE = 'private, max-age=60';/, 'API must use private cache control');
  assert.match(
    content,
    /properties: \{\s*id: gym.id,\s*name: gym.name,\s*slug: gym.slug/s,
    'GeoJSON features should expose id, name and slug'
  );
});
