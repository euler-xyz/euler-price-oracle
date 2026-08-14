// Shared by generate.mjs (writes adapters.json) and check.mjs (verifies it in
// CI). Discovery and normalization derive from compiler output, never from
// the committed file, so a tampered artifact cannot vouch for itself.
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

export const VARIANTS = { cancun: 'out', paris: 'out-paris' };

export function strictHexToBytes(hex, label) {
  if (typeof hex !== 'string' || !/^0x(?:[0-9a-fA-F]{2})*$/.test(hex)) {
    throw new Error(`${label}: not canonical hex`);
  }
  return Uint8Array.from(Buffer.from(hex.slice(2), 'hex'));
}

const KNOWN_KEYS = new Set(['ipfs', 'bzzr0', 'bzzr1', 'solc', 'experimental']);
function isSolidityMetadataCbor(cbor) {
  if (cbor.length < 1) return false;
  const head = cbor[0];
  if (head < 0xa1 || head > 0xb7) return false;
  let i = 1;
  for (let e = 0; e < head - 0xa0; e++) {
    const h = cbor[i];
    if (h === undefined || h < 0x60 || h > 0x77) return false;
    const len = h - 0x60;
    if (i + 1 + len > cbor.length) return false;
    const key = Buffer.from(cbor.subarray(i + 1, i + 1 + len)).toString('utf8');
    if (!KNOWN_KEYS.has(key)) return false;
    i += 1 + len;
    const v = cbor[i];
    if (v === undefined) return false;
    if (v >= 0x40 && v <= 0x57) i += 1 + (v - 0x40);
    else if (v === 0x58) {
      const l = cbor[i + 1];
      if (l === undefined || i + 2 + l > cbor.length) return false;
      i += 2 + l;
    } else if (v === 0xf4 || v === 0xf5) i += 1;
    else return false;
  }
  return i === cbor.length;
}

/** Fail-closed: the trailer is only stripped when it validates as solc CBOR. */
export function stripTrailingMetadata(code) {
  if (code.length < 2) return code;
  const len = (code[code.length - 2] << 8) | code[code.length - 1];
  if (len === 0 || len + 2 > code.length) return code;
  const cbor = code.subarray(code.length - (len + 2), code.length - 2);
  if (!isSolidityMetadataCbor(cbor)) return code;
  return code.subarray(0, code.length - (len + 2));
}

// Creation bytecode embeds the runtime (and factories embed children), each
// carrying a metadata digest that varies with build environment. Zero every
// embedded digest; all executable bytes remain compared.
const DIGEST_MARKERS = [
  { marker: [0x64, 0x69, 0x70, 0x66, 0x73, 0x58, 0x22, 0x12, 0x20], len: 32 },
  { marker: [0x65, 0x62, 0x7a, 0x7a, 0x72, 0x30, 0x58, 0x20], len: 32 },
  { marker: [0x65, 0x62, 0x7a, 0x7a, 0x72, 0x31, 0x58, 0x20], len: 32 },
];
export function maskEmbeddedMetadataDigests(code) {
  const out = new Uint8Array(code);
  for (const { marker, len } of DIGEST_MARKERS) {
    outer: for (let i = 0; i + marker.length + len <= out.length; i++) {
      for (let j = 0; j < marker.length; j++) {
        if (out[i + j] !== marker[j]) continue outer;
      }
      out.fill(0, i + marker.length, i + marker.length + len);
      i += marker.length + len - 1;
    }
  }
  return out;
}

/**
 * Enumerates deployable adapter contracts from compiler output: every
 * artifact whose compilationTarget lives under src/adapter and which has
 * non-empty deployed bytecode in BOTH variants. Missing either variant for a
 * contract that is deployable in the other is an error, not a skip.
 */
export function discoverAdapters(root) {
  const found = new Map(); // name -> { [variant]: artifact }
  for (const [variant, outDir] of Object.entries(VARIANTS)) {
    const base = join(root, outDir);
    if (!existsSync(base)) throw new Error(`missing build output ${outDir} — run both forge builds`);
    for (const solDir of readdirSync(base)) {
      const dir = join(base, solDir);
      let entries;
      try {
        entries = readdirSync(dir);
      } catch {
        continue;
      }
      for (const file of entries) {
        if (!file.endsWith('.json')) continue;
        const artifact = JSON.parse(readFileSync(join(dir, file), 'utf8'));
        const target = artifact.metadata?.settings?.compilationTarget ?? {};
        const [source] = Object.keys(target);
        if (!source || !source.startsWith('src/adapter/')) continue;
        if (!artifact.deployedBytecode?.object || artifact.deployedBytecode.object === '0x') continue;
        const name = target[source];
        const slot = found.get(name) ?? {};
        slot[variant] = artifact;
        found.set(name, slot);
      }
    }
  }
  for (const [name, slot] of found) {
    for (const variant of Object.keys(VARIANTS)) {
      if (!slot[variant]) throw new Error(`${name}: missing ${variant} artifact`);
    }
  }
  return new Map([...found.entries()].sort(([a], [b]) => a.localeCompare(b)));
}
