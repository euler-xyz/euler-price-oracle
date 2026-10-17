import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { standardJsonInput } from './reproduce.mjs';

const metadata = {
  language: 'Solidity',
  settings: {
    compilationTarget: { 'src/A.sol': 'A' },
    evmVersion: 'paris',
    libraries: { 'src/L.sol:L': '0x0000000000000000000000000000000000000001' },
    metadata: { bytecodeHash: 'ipfs' },
    optimizer: { enabled: true, runs: 200 },
    remappings: [':x/=src/'],
  },
  sources: { 'src/A.sol': { keccak256: '0x00' }, 'src/L.sol': { keccak256: '0x00' } },
};
const sources = { 'src/A.sol': 'contract A {}', 'src/L.sol': 'library L {}', 'src/Unused.sol': '' };

describe('standardJsonInput', () => {
  it('compiles only the sources the metadata names, with its settings and the target as output selection', () => {
    const { source, name, input } = standardJsonInput(metadata, sources);
    assert.equal(source, 'src/A.sol');
    assert.equal(name, 'A');
    assert.deepEqual(input, {
      language: 'Solidity',
      sources: { 'src/A.sol': { content: 'contract A {}' }, 'src/L.sol': { content: 'library L {}' } },
      settings: {
        evmVersion: 'paris',
        libraries: { 'src/L.sol': { L: '0x0000000000000000000000000000000000000001' } },
        metadata: { bytecodeHash: 'ipfs' },
        optimizer: { enabled: true, runs: 200 },
        remappings: [':x/=src/'],
        outputSelection: { 'src/A.sol': { A: ['metadata', 'evm.bytecode.object', 'evm.deployedBytecode.object'] } },
      },
    });
  });

  it('rejects a source the bundle does not carry', () => {
    const { 'src/L.sol': _dropped, ...partial } = sources;
    assert.throws(() => standardJsonInput(metadata, partial), /not bundled: src\/L\.sol/);
  });

  it('rejects a library key without a source', () => {
    const unsourced = { ...metadata, settings: { ...metadata.settings, libraries: { L: '0x0000000000000000000000000000000000000001' } } };
    assert.throws(() => standardJsonInput(unsourced, sources), /library L is not <source>:<name>/);
  });

  it('rejects metadata without exactly one compilation target', () => {
    const settings = (compilationTarget) => ({ ...metadata, settings: { ...metadata.settings, compilationTarget } });
    assert.throws(() => standardJsonInput(settings({}), sources), /exactly one compilation target/);
    assert.throws(() => standardJsonInput(settings({ 'src/A.sol': 'A', 'src/L.sol': 'L' }), sources), /exactly one/);
  });
});
