import { test } from 'node:test';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

test('Monitoring gym list sorts and filters gyms with locale-aware comparison', () => {
  const filePath = resolve(process.cwd(), 'src/components/monitoring/monitoring-gym-list.tsx');
  const content = readFileSync(filePath, 'utf8');
  assert.match(
    content,
    /localeCompare\(b.name, 'de', {\s*\n\s*sensitivity: 'base',\s*\n\s*numeric: true,\s*\n\s*}\)/,
    'List should use locale-aware comparison for names'
  );
  assert.match(
    content,
    /window\.setTimeout\(\(\) => {\s*\n\s*setDebouncedQuery/,
    'List should debounce the search input'
  );
  assert.match(content, /gym.name.toLowerCase\(\)\.includes\(normalized\)/, 'List should filter by gym name');
});

test('Monitoring overview triggers map focus and reset handlers', () => {
  const filePath = resolve(process.cwd(), 'src/components/monitoring/monitoring-overview.tsx');
  const content = readFileSync(filePath, 'utf8');
  assert.match(content, /mapRef\.current\?\.flyToGym\(gym.id, { zoom: FOCUS_ZOOM }\)/, 'Overview should call flyToGym on focus');
  assert.match(content, /mapRef\.current\?\.fitToInitial\(\)/, 'Overview should call fitToInitial when resetting view');
});
