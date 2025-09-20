#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import process from 'node:process';
import module from 'node:module';
import { loadEnvConfig } from '@next/env';
import { ModuleKind, ScriptTarget, transpileModule } from 'typescript';

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
  const { outputText } = transpileModule(source, {
    compilerOptions: {
      module: ModuleKind.CommonJS,
      target: ScriptTarget.ES2020,
      esModuleInterop: true,
    },
    fileName: tsPath,
  });

  const mod = new Module(tsPath);
  mod.filename = tsPath;
  mod.paths = Module._nodeModulePaths(path.dirname(tsPath));
  mod._compile(outputText, tsPath);
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
          using: summary.using,
        })
      );
      return;
    }

    const app = admin.getFirebaseAdminApp();
    console.log(
      JSON.stringify({
        ok: true,
        projectId: app.options.projectId ?? 'unknown',
        using: 'unknown',
      })
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(JSON.stringify({ ok: false, error: message }));
    process.exitCode = 1;
  }
}

main();
