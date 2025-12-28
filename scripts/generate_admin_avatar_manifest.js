#!/usr/bin/env node
/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', 'admin-web', 'public', 'avatars');

function isPng(name) {
  return name.toLowerCase().endsWith('.png');
}

function readDirSafe(dir) {
  try {
    return fs.readdirSync(dir, { withFileTypes: true });
  } catch (_) {
    return [];
  }
}

function listPngs(dir) {
  const entries = readDirSafe(dir);
  return entries
    .filter((e) => e.isFile() && isPng(e.name))
    .map((e) => path.basename(e.name, path.extname(e.name)))
    .sort();
}

const manifest = { global: [], gyms: {} };
const dirs = readDirSafe(root).filter((e) => e.isDirectory()).map((e) => e.name);

for (const folder of dirs) {
  const full = path.join(root, folder);
  const items = listPngs(full);
  if (folder === 'global') {
    manifest.global = items;
  } else {
    manifest.gyms[folder] = items;
  }
}

const outPath = path.join(root, 'manifest.json');
fs.mkdirSync(root, { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(manifest, null, 2));
console.log(`✅ Avatar manifest written: ${outPath}`);
