#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import process from 'node:process';
import module from 'node:module';
import nextEnv from '@next/env';
import ts from 'typescript';

const { loadEnvConfig } = nextEnv;
const { Module } = module;

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectDir = path.resolve(__dirname, '../..');

loadEnvConfig(projectDir, false, {
  infoLog: () => {},
  errorLog: (message) => {
    if (message) {
      console.error(message);
    }
  },
});

process.env.NODE_ENV = process.env.NODE_ENV ?? 'development';

function loadAdminModule() {
  const tsPath = path.resolve(projectDir, 'src/server/firebase/admin.ts');
  const source = fs.readFileSync(tsPath, 'utf8');
  const { outputText } = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2020,
      esModuleInterop: true,
    },
    fileName: tsPath,
  });

  const sanitized = outputText.replace(/require\(["']server-only["']\);\s*/g, '');
  const mod = new Module(tsPath);
  mod.filename = tsPath;
  mod.paths = Module._nodeModulePaths(path.dirname(tsPath));
  mod._compile(sanitized, tsPath);
  return mod.exports;
}

async function main() {
  try {
    const admin = loadAdminModule();
    admin.assertFirebaseAdminReady();
    const summary = typeof admin.getFirebaseAdminConfigSummary === 'function'
      ? admin.getFirebaseAdminConfigSummary()
      : null;

    if (summary) {
      console.log(
        JSON.stringify({
          ok: true,
          projectId: summary.projectId,
          mode: summary.mode,
          usesServiceAccount: summary.usesServiceAccount,
        })
      );
      return;
    }

    const app = admin.getFirebaseAdminApp();
    console.log(
      JSON.stringify({
        ok: true,
        projectId: app.options.projectId ?? 'unknown',
        mode: 'production',
        usesServiceAccount: true,
      })
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(JSON.stringify({ ok: false, error: message }));
    process.exitCode = 1;
  }
}

main();
