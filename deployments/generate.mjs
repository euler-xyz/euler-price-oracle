// Generates deployments/adapters.json — the single source of truth consumers
// (euler-toolbox deployments, euler-data-v3 fingerprints) read instead of
// compiling this repo themselves. Regenerate after an adapter or compiler
// change lands on master:
//
//   forge build
//   FOUNDRY_OUT=out-paris forge build --evm-version paris
//   node deployments/generate.mjs
//
// and commit the refreshed adapters.json alongside the change. Every
// deployable contract under src/adapter is emitted (compiler-derived, not
// filename-derived); consumers select their own subset.
import { execSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { discoverAdapters, VARIANTS } from './artifact-utils.mjs';

const ROOT = new URL('..', import.meta.url).pathname;
const commit = execSync('git rev-parse --short HEAD', { cwd: ROOT }).toString().trim();

const adapters = {};
for (const [name, slot] of discoverAdapters(ROOT)) {
  adapters[name] = {};
  for (const variant of Object.keys(VARIANTS)) {
    const artifact = slot[variant];
    adapters[name][variant] = {
      abi: artifact.abi,
      creationBytecode: artifact.bytecode.object,
      deployedBytecode: artifact.deployedBytecode.object,
      immutableReferences: artifact.deployedBytecode.immutableReferences ?? {},
    };
  }
}
const out = { commit, generatedWith: 'deployments/generate.mjs', adapters };
writeFileSync(join(ROOT, 'deployments/adapters.json'), `${JSON.stringify(out, null, 1)}\n`);
console.log(`adapters.json: ${Object.keys(adapters).length} adapters x ${Object.keys(VARIANTS).length} variants @ ${commit}`);
