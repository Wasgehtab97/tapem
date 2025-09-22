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
