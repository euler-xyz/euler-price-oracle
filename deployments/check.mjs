// CI guard: verifies the committed adapters.json against fresh compiler
// output. Nothing is regenerated and nothing from the committed file is
// trusted for its own verification: discovery, immutable ranges, and
// normalization all come from the build. Only environment-dependent metadata
// digests are masked, so any real change to ABI, creation bytecode, deployed
// bytecode, immutable ranges, or the adapter inventory fails.
import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import {
  BUNDLE_KEYS,
  discoverAdapters,
  ENTRY_KEYS,
  ipfsMultihash,
  maskEmbeddedMetadataDigests,
  serializeBundle,
  strictHexToBytes,
  stripTrailingMetadata,
  trailerIpfsMultihash,
  VARIANTS,
} from './artifact-utils.mjs';
import { projectSolc, recompile } from './reproduce.mjs';

const ROOT = new URL('..', import.meta.url).pathname;
const bundlePath = process.argv[2] ? resolve(process.argv[2]) : join(ROOT, 'deployments/adapters.json');
const raw = readFileSync(bundlePath, 'utf8');
const committed = JSON.parse(raw);
const built = discoverAdapters(ROOT);

const problems = [];
if (raw !== serializeBundle(committed)) problems.push('the file is not exactly what deployments/generate.mjs writes for its content');

// Envelope schema: nothing in the file is decorative. Unknown or missing
// fields fail, the generator identity is pinned, and the provenance stamp must
// resolve to a real commit in this repository (CI checks out full history for this).
const keyDiff = (object, expected) => {
  const keys = Object.keys(object);
  return { extra: keys.filter((key) => !expected.includes(key)), missing: expected.filter((key) => !keys.includes(key)) };
};
const top = keyDiff(committed, BUNDLE_KEYS);
if (top.extra.length > 0) problems.push(`unexpected top-level fields: ${top.extra.join(', ')}`);
if (top.missing.length > 0) problems.push(`missing top-level fields: ${top.missing.join(', ')}`);
if (committed.generatedWith !== 'deployments/generate.mjs') {
  problems.push(`generatedWith is '${committed.generatedWith}', expected 'deployments/generate.mjs'`);
}
if (typeof committed.commit !== 'string' || !/^[0-9a-f]{7,40}$/.test(committed.commit)) {
  problems.push(`commit stamp '${committed.commit}' is not a commit hash`);
} else {
  try {
    execSync(`git cat-file -e ${committed.commit}^{commit}`, { cwd: ROOT, stdio: 'pipe' });
  } catch {
    problems.push(`commit stamp '${committed.commit}' does not resolve to a commit in this repository`);
  }
}

const VARIANT_KEYS = Object.keys(VARIANTS).sort();
for (const [name, variants] of Object.entries(committed.adapters ?? {})) {
  const variantNames = Object.keys(variants).sort();
  if (JSON.stringify(variantNames) !== JSON.stringify(VARIANT_KEYS)) {
    problems.push(`${name}: variants [${variantNames.join(', ')}], expected [${VARIANT_KEYS.join(', ')}]`);
    continue;
  }
  for (const [variant, entry] of Object.entries(variants)) {
    const { extra, missing } = keyDiff(entry, ENTRY_KEYS);
    if (extra.length > 0) problems.push(`${name}/${variant}: unexpected fields: ${extra.join(', ')}`);
    if (missing.length > 0) problems.push(`${name}/${variant}: missing fields: ${missing.join(', ')}`);
  }
}
const committedNames = Object.keys(committed.adapters ?? {}).sort();
const builtNames = [...built.keys()];
if (JSON.stringify(committedNames) !== JSON.stringify(builtNames)) {
  problems.push(
    `inventory mismatch:\n  committed: ${committedNames.join(', ')}\n  built:     ${builtNames.join(', ')}`,
  );
}

function normalizedEqual(committedHex, builtHex, label, strip) {
  let committedBytes;
  try {
    committedBytes = strictHexToBytes(committedHex, label);
  } catch (error) {
    problems.push(String(error.message ?? error));
    return;
  }
  const builtBytes = strictHexToBytes(builtHex, `${label} (built)`);
  const a = maskEmbeddedMetadataDigests(strip ? stripTrailingMetadata(committedBytes) : committedBytes);
  const b = maskEmbeddedMetadataDigests(strip ? stripTrailingMetadata(builtBytes) : builtBytes);
  if (Buffer.compare(Buffer.from(a), Buffer.from(b)) !== 0) {
    problems.push(`${label}: differs from the current build`);
  }
}

// The metadata is the one the committed bytecode was built with: its IPFS hash
// is the one in the bytecode's trailer. Remappings carry the build machine's
// absolute paths, so they are the one setting not compared with this build
// (checkReproduction proves they resolve); every other setting, the compiler
// and the source hashes must match it.
// Forge's parsed metadata and the raw metadata can list the same keys in a different order.
const canonical = (value) => (Array.isArray(value)
  ? `[${value.map(canonical).join(',')}]`
  : value && typeof value === 'object'
    ? `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${canonical(value[key])}`).join(',')}}`
    : JSON.stringify(value));
const settingsWithoutRemappings = (metadata) => {
  const { remappings: _remappings, ...settings } = metadata.settings ?? {};
  return settings;
};
const namedSources = new Set();
function checkMetadata(label, stored, artifact) {
  if (typeof stored.metadata !== 'string') {
    problems.push(`${label}: metadata missing`);
    return;
  }
  let metadata;
  try {
    metadata = JSON.parse(stored.metadata);
  } catch {
    problems.push(`${label}: metadata is not JSON`);
    return;
  }
  for (const path of Object.keys(metadata.sources ?? {})) namedSources.add(path);
  let deployed;
  let creation;
  try {
    deployed = strictHexToBytes(stored.deployedBytecode, `${label} deployedBytecode`);
    creation = strictHexToBytes(stored.creationBytecode, `${label} creationBytecode`);
  } catch {
    return;
  }
  const digest = trailerIpfsMultihash(deployed);
  let expected;
  try {
    expected = ipfsMultihash(stored.metadata);
  } catch (error) {
    problems.push(`${label}: ${error.message ?? error}`);
    return;
  }
  if (!digest || !digest.equals(expected)) problems.push(`${label}: metadata is not the one the deployed bytecode names`);
  if (digest && !Buffer.from(creation).includes(digest)) problems.push(`${label}: creation bytecode does not embed the deployed bytecode's metadata`);
  const built = artifact.metadata;
  if (metadata.compiler?.version !== built.compiler?.version) problems.push(`${label}: compiler differs from the current build`);
  if (canonical(settingsWithoutRemappings(metadata)) !== canonical(settingsWithoutRemappings(built))) {
    problems.push(`${label}: compiler settings differ from the current build`);
  }
  if (canonical(metadata.sources) !== canonical(built.sources)) {
    problems.push(`${label}: sources or their hashes differ from the current build`);
  }
  checkReproduction(label, stored, metadata);
}

function resolveSolc() {
  try {
    return projectSolc(ROOT);
  } catch (error) {
    problems.push(`cannot run the project's solc to recompile the bundled inputs: ${error.message ?? error}`);
    return null;
  }
}
const solc = resolveSolc();
const reproduced = [];
// The digest only ties the metadata to the trailer; recompiling the bundled
// inputs proves solc produces exactly this metadata and bytecode from them.
function checkReproduction(label, stored, metadata) {
  if (!solc) return;
  if (metadata.compiler?.version !== solc.version) {
    problems.push(`${label}: metadata names solc ${metadata.compiler?.version}, the project compiles with ${solc.version}`);
    return;
  }
  let rebuilt;
  try {
    rebuilt = recompile(solc.path, metadata, committed.sources ?? {});
  } catch (error) {
    problems.push(`${label}: bundled inputs do not compile: ${error.message ?? error}`);
    return;
  }
  if (rebuilt.metadata !== stored.metadata) problems.push(`${label}: metadata is not what solc produces from the bundled inputs`);
  if (rebuilt.creationBytecode !== stored.creationBytecode) {
    problems.push(`${label}: creation bytecode is not what solc produces from the bundled inputs`);
  }
  if (rebuilt.deployedBytecode !== stored.deployedBytecode) {
    problems.push(`${label}: deployed bytecode is not what solc produces from the bundled inputs`);
  }
  reproduced.push(label);
}

for (const name of builtNames) {
  const entry = committed.adapters?.[name];
  if (!entry) continue; // already reported by the inventory check
  for (const variant of Object.keys(VARIANTS)) {
    const artifact = built.get(name)[variant];
    const stored = entry[variant];
    if (!stored) {
      problems.push(`${name}/${variant}: missing from committed file`);
      continue;
    }
    if (JSON.stringify(stored.abi) !== JSON.stringify(artifact.abi)) {
      problems.push(`${name}/${variant}: ABI differs from the current build`);
    }
    if (JSON.stringify(stored.immutableReferences ?? {}) !== JSON.stringify(artifact.deployedBytecode.immutableReferences ?? {})) {
      problems.push(`${name}/${variant}: immutableReferences differ from the current build`);
    }
    normalizedEqual(stored.creationBytecode, artifact.bytecode.object, `${name}/${variant} creationBytecode`, false);
    normalizedEqual(stored.deployedBytecode, artifact.deployedBytecode.object, `${name}/${variant} deployedBytecode`, true);
    checkMetadata(`${name}/${variant}`, stored, artifact);
  }
}

// Every source a build names is in the file, exactly as this repository has it, and nothing else is.
const committedSources = committed.sources ?? {};
const committedSourcePaths = Object.keys(committedSources).sort();
const namedSourcePaths = [...namedSources].sort();
if (JSON.stringify(committedSourcePaths) !== JSON.stringify(namedSourcePaths)) {
  problems.push(`sources: the file holds [${committedSourcePaths.length}] paths, the builds name [${namedSourcePaths.length}]`);
}
for (const path of namedSourcePaths) {
  let onDisk;
  try {
    onDisk = readFileSync(join(ROOT, path), 'utf8');
  } catch {
    problems.push(`sources: ${path} is not in this repository`);
    continue;
  }
  if (committedSources[path] !== onDisk) problems.push(`sources: ${path} differs from this repository`);
}

if (problems.length > 0) {
  for (const problem of problems) console.error(`STALE ${problem}`);
  console.error('\nadapters.json does not match the build — regenerate with deployments/generate.mjs and commit.');
  process.exit(1);
}
console.log(
  `adapters.json verified: ${builtNames.length} adapters x ${Object.keys(VARIANTS).length} variants, ${namedSourcePaths.length} sources, recompiled ${reproduced.length} builds with solc ${solc.version}`,
);
