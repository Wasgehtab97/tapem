import { test } from 'node:test';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

test('Monitoring page renders overview component container', () => {
  const filePath = resolve(process.cwd(), 'src/app/(admin)/admin/monitoring/page.tsx');
  const content = readFileSync(filePath, 'utf8');
  assert.match(
    content,
    /<div className=\"mx-auto w-full max-w-6xl px-6 py-12\">/, 
    'Monitoring page should keep the container layout'
  );
  assert.match(content, /<MonitoringOverview \/>/, 'Monitoring page should include MonitoringOverview component');
});
