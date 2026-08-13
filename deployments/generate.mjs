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

/** Deployable adapter classes. Deprecated adapters are deliberately absent. */
const CLASSES = [
  'ChainlinkOracle',
  'ChainlinkInfrequentOracle',
  'ChainlinkInfrequentNanosecondOracle',
  'ChainlinkInfrequentXStocksOracle',
  'ChronicleOracle',
  'CrossAdapter',
  'FixedRateOracle',
  'LidoOracle',
  'LidoFundamentalOracle',
  'PendleOracle',
  'PendleUniversalOracle',
  'PythOracle',
  'RateProviderOracle',
];

/** evm_version variants: cancun for Shanghai-capable chains, paris otherwise. */
const VARIANTS = { cancun: 'out', paris: 'out-paris' };

const commit = execSync('git rev-parse --short HEAD', { cwd: ROOT }).toString().trim();
const adapters = {};
for (const className of CLASSES) {
  adapters[className] = {};
  for (const [variant, outDir] of Object.entries(VARIANTS)) {
    const path = join(ROOT, outDir, `${className}.sol`, `${className}.json`);
    if (!existsSync(path)) {
      throw new Error(`missing artifact ${path} — run both forge builds first`);
    }
    const artifact = JSON.parse(readFileSync(path, 'utf8'));
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
