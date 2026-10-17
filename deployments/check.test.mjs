// Needs both forge builds (out/ and out-paris/), like check.mjs itself.
import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { after, describe, it } from 'node:test';
import { promisify } from 'node:util';
import { ipfsMultihash } from './artifact-utils.mjs';

const ROOT = new URL('..', import.meta.url).pathname;
const CHECK = join(ROOT, 'deployments/check.mjs');
const BUNDLE = JSON.parse(readFileSync(join(ROOT, 'deployments/adapters.json'), 'utf8'));
const MAX_OUTPUT_BYTES = 16 * 1024 * 1024;

const scratch = mkdtempSync(join(tmpdir(), 'adapters-check-'));
after(() => rmSync(scratch, { recursive: true, force: true }));

const execFileAsync = promisify(execFile);
async function check(bundle) {
  const args = [CHECK];
  if (bundle) {
    const path = join(scratch, `${randomUUID()}.json`);
    writeFileSync(path, JSON.stringify(bundle));
    args.push(path);
  }
  try {
    const { stdout } = await execFileAsync(process.execPath, args, { maxBuffer: MAX_OUTPUT_BYTES });
    return { code: 0, stdout, stale: [] };
  } catch (error) {
    if (typeof error.code !== 'number') throw error;
    const stale = error.stderr.split('\n').filter((line) => line.startsWith('STALE ')).map((line) => line.slice('STALE '.length));
    return { code: error.code, stdout: error.stdout, stale };
  }
}

const withBuild = (bundle, name, variant, build) => ({
  ...bundle,
  adapters: { ...bundle.adapters, [name]: { ...bundle.adapters[name], [variant]: build } },
});

// Re-digests the edited metadata into both trailers, so the digest checks
// pass and only recompilation can catch the edit.
function rehashed(build, edit) {
  const metadata = JSON.stringify(edit(JSON.parse(build.metadata)));
  const from = ipfsMultihash(build.metadata).toString('hex');
  const to = ipfsMultihash(metadata).toString('hex');
  assert.notEqual(from, to);
  assert.ok(build.creationBytecode.includes(from) && build.deployedBytecode.includes(from));
  return {
    ...build,
    metadata,
    creationBytecode: build.creationBytecode.replaceAll(from, to),
    deployedBytecode: build.deployedBytecode.replaceAll(from, to),
  };
}

const TARGET = 'ChainlinkOracle';
const VARIANT = 'cancun';
const LABEL = `${TARGET}/${VARIANT}`;
const target = BUNDLE.adapters[TARGET][VARIANT];
const NOT_REPRODUCED = [
  `${LABEL}: metadata is not what solc produces from the bundled inputs`,
  `${LABEL}: creation bytecode is not what solc produces from the bundled inputs`,
  `${LABEL}: deployed bytecode is not what solc produces from the bundled inputs`,
];

describe('deployments/check.mjs', { concurrency: true }, () => {
  it('verifies the committed bundle', async () => {
    const result = await check();
    const builds = Object.values(BUNDLE.adapters).reduce((count, variants) => count + Object.keys(variants).length, 0);
    assert.equal(result.code, 0);
    assert.match(result.stdout, new RegExp(`verified: .*recompiled ${builds} builds with solc `));
  });

  it('fails on a deployed trailer that names another solc version', async () => {
    assert.ok(target.deployedBytecode.endsWith('64736f6c63430008170033'));
    const deployedBytecode = target.deployedBytecode.replace(/0008170033$/, '0008180033');
    const result = await check(withBuild(BUNDLE, TARGET, VARIANT, { ...target, deployedBytecode }));
    assert.equal(result.code, 1);
    assert.deepEqual(result.stale, [`${LABEL}: deployed bytecode is not what solc produces from the bundled inputs`]);
  });

  describe('rehashed metadata that no longer reproduces', { concurrency: true }, () => {
    it('fails on a remapping that points outside the bundled sources', async () => {
      const build = rehashed(target, (metadata) => ({
        ...metadata,
        settings: { ...metadata.settings, remappings: [...metadata.settings.remappings, ':@solady/=missing/'] },
      }));
      const result = await check(withBuild(BUNDLE, TARGET, VARIANT, build));
      assert.equal(result.code, 1);
      assert.equal(result.stale.length, 1, result.stale.join('\n'));
      assert.match(result.stale[0], new RegExp(`^${LABEL}: bundled inputs do not compile: .*missing/utils/FixedPointMathLib\\.sol`));
    });

    it('fails on language Yul', async () => {
      const build = rehashed(target, (metadata) => ({ ...metadata, language: 'Yul' }));
      const result = await check(withBuild(BUNDLE, TARGET, VARIANT, build));
      assert.equal(result.code, 1);
      assert.equal(result.stale.length, 1, result.stale.join('\n'));
      assert.match(result.stale[0], new RegExp(`^${LABEL}: bundled inputs do not compile: `));
    });

    it('fails on an emptied output.abi', async () => {
      const build = rehashed(target, (metadata) => ({ ...metadata, output: { ...metadata.output, abi: [] } }));
      const result = await check(withBuild(BUNDLE, TARGET, VARIANT, build));
      assert.equal(result.code, 1);
      assert.deepEqual(result.stale, NOT_REPRODUCED);
    });
  });

  describe('tampering the digest and source checks catch', { concurrency: true }, () => {
    it('fails on a changed source', async () => {
      const path = 'src/adapter/chainlink/ChainlinkOracle.sol';
      const result = await check({ ...BUNDLE, sources: { ...BUNDLE.sources, [path]: `${BUNDLE.sources[path]}\n` } });
      assert.equal(result.code, 1);
      assert.ok(result.stale.includes(`sources: ${path} differs from this repository`), result.stale.join('\n'));
    });

    it('fails on metadata swapped between two builds', async () => {
      const paris = BUNDLE.adapters[TARGET].paris;
      const swapped = withBuild(
        withBuild(BUNDLE, TARGET, VARIANT, { ...target, metadata: paris.metadata }),
        TARGET,
        'paris',
        { ...paris, metadata: target.metadata },
      );
      const result = await check(swapped);
      assert.equal(result.code, 1);
      assert.ok(
        result.stale.includes(`${LABEL}: metadata is not the one the deployed bytecode names`)
          && result.stale.includes(`${TARGET}/paris: metadata is not the one the deployed bytecode names`),
        result.stale.join('\n'),
      );
    });

    it('fails on an extra source', async () => {
      const result = await check({ ...BUNDLE, sources: { ...BUNDLE.sources, 'src/Extra.sol': '' } });
      assert.equal(result.code, 1);
      assert.ok(result.stale.some((line) => /^sources: the file holds \[\d+\] paths/.test(line)), result.stale.join('\n'));
    });
  });
});
