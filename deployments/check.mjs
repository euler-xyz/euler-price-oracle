// CI guard: verifies the committed adapters.json against fresh compiler
// output. Nothing is regenerated and nothing from the committed file is
// trusted for its own verification: discovery, immutable ranges, and
// normalization all come from the build. Only environment-dependent metadata
// digests are masked, so any real change to ABI, creation bytecode, deployed
// bytecode, immutable ranges, or the adapter inventory fails.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  discoverAdapters,
  maskEmbeddedMetadataDigests,
  strictHexToBytes,
  stripTrailingMetadata,
  VARIANTS,
} from './artifact-utils.mjs';

const ROOT = new URL('..', import.meta.url).pathname;
const committed = JSON.parse(readFileSync(join(ROOT, 'deployments/adapters.json'), 'utf8'));
const built = discoverAdapters(ROOT);

const problems = [];
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
  }
}

if (problems.length > 0) {
  for (const problem of problems) console.error(`STALE ${problem}`);
  console.error('\nadapters.json does not match the build — regenerate with deployments/generate.mjs and commit.');
  process.exit(1);
}
console.log(`adapters.json verified: ${builtNames.length} adapters x ${Object.keys(VARIANTS).length} variants`);
