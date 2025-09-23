import { test } from 'node:test';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

test('Admin navigation includes Monitoring entry', () => {
  const filePath = resolve(process.cwd(), 'src/components/layout/admin-shell.tsx');
  const content = readFileSync(filePath, 'utf8');
  assert.match(
    content,
    /\{ label: 'Monitoring', route: ADMIN_ROUTES\.monitoring/,
    'Sidebar navigation should link to the Monitoring route'
  );
});

test('Monitoring list links to detail route', () => {
  const filePath = resolve(process.cwd(), 'src/components/monitoring/monitoring-gym-list.tsx');
  const content = readFileSync(filePath, 'utf8');
  assert.match(
    content,
    /buildAdminMonitoringDetailRoute\(gym.id\)/,
    'Monitoring list should use the detail route helper'
  );
  assert.match(content, />\s*Details<span aria-hidden>/, 'Monitoring list should render Details link label');
});
