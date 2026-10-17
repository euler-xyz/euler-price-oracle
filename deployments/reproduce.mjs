import { execFileSync } from 'node:child_process';

const OUTPUTS = ['metadata', 'evm.bytecode.object', 'evm.deployedBytecode.object'];
const MAX_SOLC_OUTPUT_BYTES = 64 * 1024 * 1024;
const SOLC_TIMEOUT_MS = 120_000;

export function projectSolc(root) {
  const path = execFileSync('forge', ['compiler', 'resolve', '--path'], { cwd: root, encoding: 'utf8' }).trim();
  const banner = execFileSync(path, ['--version'], { encoding: 'utf8' });
  const version = /^Version: (\d+\.\d+\.\d+\+commit\.[0-9a-f]+)/m.exec(banner)?.[1];
  if (!version) throw new Error(`${path} does not report a solc version`);
  return { path, version };
}

function standardJsonLibraries(libraries) {
  return Object.entries(libraries ?? {}).reduce((nested, [key, address]) => {
    const at = key.lastIndexOf(':');
    if (at <= 0) throw new Error(`library ${key} is not <source>:<name>`);
    const source = key.slice(0, at);
    return { ...nested, [source]: { ...nested[source], [key.slice(at + 1)]: address } };
  }, {});
}

/**
 * The standard JSON input a verifier derives from one build's metadata and
 * the bundled sources: every metadata setting except the metadata-only
 * compilationTarget, which becomes the output selection.
 */
export function standardJsonInput(metadata, sources) {
  const { compilationTarget, libraries, ...settings } = metadata.settings ?? {};
  const targets = Object.entries(compilationTarget ?? {});
  if (targets.length !== 1) throw new Error('metadata does not name exactly one compilation target');
  const [[source, name]] = targets;
  const missing = Object.keys(metadata.sources ?? {}).filter((path) => typeof sources[path] !== 'string');
  if (missing.length > 0) throw new Error(`not bundled: ${missing.join(', ')}`);
  return {
    source,
    name,
    input: {
      language: metadata.language,
      sources: Object.fromEntries(Object.keys(metadata.sources).map((path) => [path, { content: sources[path] }])),
      settings: {
        ...settings,
        libraries: standardJsonLibraries(libraries),
        outputSelection: { [source]: { [name]: OUTPUTS } },
      },
    },
  };
}

// --no-import-callback keeps solc off the filesystem: an import the bundle
// does not carry must fail here, as it would for a block explorer.
export function recompile(solcPath, metadata, sources) {
  const { source, name, input } = standardJsonInput(metadata, sources);
  const stdout = execFileSync(solcPath, ['--standard-json', '--no-import-callback'], {
    input: JSON.stringify(input),
    encoding: 'utf8',
    maxBuffer: MAX_SOLC_OUTPUT_BYTES,
    timeout: SOLC_TIMEOUT_MS,
  });
  const output = JSON.parse(stdout);
  const error = (output.errors ?? []).find((entry) => entry.severity === 'error');
  if (error) {
    const file = error.sourceLocation?.file;
    throw new Error(`${error.type}: ${error.message}${file ? ` (in ${file})` : ''}`);
  }
  const contract = output.contracts?.[source]?.[name];
  if (typeof contract?.metadata !== 'string' || !contract.evm?.bytecode?.object || !contract.evm?.deployedBytecode?.object) {
    throw new Error(`solc produced no metadata and bytecode for ${source}:${name}`);
  }
  return {
    metadata: contract.metadata,
    creationBytecode: `0x${contract.evm.bytecode.object}`,
    deployedBytecode: `0x${contract.evm.deployedBytecode.object}`,
  };
}
