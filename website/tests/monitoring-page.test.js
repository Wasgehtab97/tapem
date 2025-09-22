import { test } from 'node:test';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

test('Monitoring page renders map component and heading', () => {
  const filePath = resolve(process.cwd(), 'src/app/(admin)/admin/monitoring/page.tsx');
  const content = readFileSync(filePath, 'utf8');
  assert.match(content, /<h1 className=\"[^\"]*\">Standorte<\/h1>/, 'Monitoring page should render Standorte heading');
  assert.match(content, /<MonitoringMap \/>/, 'Monitoring page should include MonitoringMap component');
});
