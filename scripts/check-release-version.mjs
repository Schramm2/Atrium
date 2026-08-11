import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const nativeManifest = JSON.parse(readFileSync(join(root, 'macos/version.json'), 'utf8'));
const versions = [nativeManifest.version];
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
