import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const tauriConfig = JSON.parse(readFileSync(join(root, 'frontend/src-tauri/tauri.conf.json'), 'utf8'));
const packageJson = JSON.parse(readFileSync(join(root, 'frontend/package.json'), 'utf8'));
const cargoToml = readFileSync(join(root, 'frontend/src-tauri/Cargo.toml'), 'utf8');
const cargoVersion = cargoToml.match(/^version\s*=\s*"([^"]+)"/m)?.[1];
const versions = [tauriConfig.version, packageJson.version, cargoVersion];
const stableSemver = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;

if (versions.some((version) => !version || !stableSemver.test(version))) {
  throw new Error(`Release versions must use stable semantic versioning (X.Y.Z): ${versions.join(', ')}`);
}

if (new Set(versions).size !== 1) {
  throw new Error(`Release versions must match: ${versions.join(', ')}`);
}

const [version] = versions;
const releaseTag = process.env.RELEASE_TAG;

if (releaseTag && releaseTag !== `v${version}`) {
  throw new Error(`Release tag ${releaseTag} does not match version v${version}`);
}

console.log(`Release version is valid: v${version}`);
