// CI staleness check at fingerprint level: metadata trailers and immutable
// slots are masked (deployment- and environment-dependent), so only real
// codegen changes fail the check. Run after both forge builds.
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = new URL('..', import.meta.url).pathname;
const committed = JSON.parse(readFileSync(join(ROOT, 'deployments/adapters.json'), 'utf8'));
const VARIANTS = { cancun: 'out', paris: 'out-paris' };

function stripMetadata(code) {
  if (code.length < 2) return code;
  const len = (code[code.length - 2] << 8) | code[code.length - 1];
  if (len === 0 || len + 2 > code.length) return code;
  return code.subarray(0, code.length - (len + 2));
}
function fingerprint(deployedBytecodeHex, immutableReferences) {
  const code = Uint8Array.from(Buffer.from(deployedBytecodeHex.slice(2), 'hex'));
  const runtime = stripMetadata(code);
  const masked = new Uint8Array(runtime);
  for (const ranges of Object.values(immutableReferences ?? {})) {
    for (const { start, length } of ranges) {
      if (start + length <= masked.length) masked.fill(0, start, start + length);
    }
  }
  return createHash('sha256').update(masked).digest('hex');
}

let failed = false;
for (const [className, variants] of Object.entries(committed.adapters)) {
  for (const [variant, entry] of Object.entries(variants)) {
    const artifact = JSON.parse(
      readFileSync(join(ROOT, VARIANTS[variant], `${className}.sol`, `${className}.json`), 'utf8'),
    );
    const fresh = fingerprint(
      artifact.deployedBytecode.object,
      artifact.deployedBytecode.immutableReferences,
    );
    const stored = fingerprint(entry.deployedBytecode, entry.immutableReferences);
    if (fresh !== stored) {
      failed = true;
      console.error(`STALE ${className}/${variant}: committed ${stored.slice(0, 16)}… vs built ${fresh.slice(0, 16)}…`);
    }
  }
}
if (failed) {
  console.error('\nadapters.json is stale — regenerate with deployments/generate.mjs and commit.');
  process.exit(1);
}
console.log('adapters.json fingerprints match the current build');
