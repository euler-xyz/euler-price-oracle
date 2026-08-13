// Generates deployments/adapters.json — the single source of truth consumers
// (euler-toolbox deployments, euler-data-v3 fingerprints) read instead of
// compiling this repo themselves. Regenerate after an adapter or compiler
// change lands on master:
//
//   forge build
//   FOUNDRY_OUT=out-paris forge build --evm-version paris
//   node deployments/generate.mjs
//
// and commit the refreshed adapters.json alongside the change.
import { execSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = new URL('..', import.meta.url).pathname;

// Every concrete contract under src/adapter is emitted; consumers select
// their own subset (euler-data-v3 recognizes only supported classes, the
// toolbox lists only what it deploys). Abstract bases and libraries have no
// deployable bytecode and are skipped automatically.
import { readdirSync } from 'node:fs';
function discoverClasses() {
  const names = [];
  const walk = (dir) => {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      if (entry.isDirectory()) walk(join(dir, entry.name));
      else if (entry.name.endsWith('.sol')) names.push(entry.name.replace(/\.sol$/, ''));
    }
  };
  walk(join(ROOT, 'src/adapter'));
  return names.sort();
}
const CLASSES = discoverClasses();

/** evm_version variants: cancun for Shanghai-capable chains, paris otherwise. */
const VARIANTS = { cancun: 'out', paris: 'out-paris' };

const commit = execSync('git rev-parse --short HEAD', { cwd: ROOT }).toString().trim();
const adapters = {};
for (const className of CLASSES) {
  adapters[className] = {};
  for (const [variant, outDir] of Object.entries(VARIANTS)) {
    const path = join(ROOT, outDir, `${className}.sol`, `${className}.json`);
    if (!existsSync(path)) {
      delete adapters[className];
      break;
    }
    const artifact = JSON.parse(readFileSync(path, 'utf8'));
    if (!artifact.deployedBytecode?.object || artifact.deployedBytecode.object === '0x') {
      delete adapters[className];
      break;
    }
    adapters[className][variant] = {
      abi: artifact.abi,
      creationBytecode: artifact.bytecode.object,
      deployedBytecode: artifact.deployedBytecode.object,
      immutableReferences: artifact.deployedBytecode.immutableReferences ?? {},
    };
  }
}
const out = { commit, generatedWith: 'deployments/generate.mjs', adapters };
writeFileSync(join(ROOT, 'deployments/adapters.json'), `${JSON.stringify(out, null, 1)}\n`);
console.log(`adapters.json: ${CLASSES.length} classes x ${Object.keys(VARIANTS).length} variants @ ${commit}`);
