#!/usr/bin/env node
import process from 'node:process';

const target = process.env.HEALTH_URL ?? 'http://localhost:3000/api/health/firebase-admin';

async function main() {
  try {
    const response = await fetch(target, { headers: { 'cache-control': 'no-cache' } });
    const body = await response.json();
    const output = {
      status: response.status,
      ok: response.ok,
      body,
    };
    console.log(JSON.stringify(output, null, 2));
    if (!response.ok) {
      process.exitCode = 1;
    }
  } catch (error) {
    console.error(JSON.stringify({ ok: false, error: error instanceof Error ? error.message : String(error) }));
    process.exitCode = 1;
  }
}

main();
