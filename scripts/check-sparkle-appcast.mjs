import { readFileSync } from 'node:fs';

const [appcastPath, expectedVersion] = process.argv.slice(2);

if (!appcastPath || !expectedVersion) {
  throw new Error(
    'Usage: node scripts/check-sparkle-appcast.mjs <appcast.xml> <expected-version>',
  );
}

const stableSemver = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
if (!stableSemver.test(expectedVersion)) {
  throw new Error(`Expected version is not stable semantic versioning: ${expectedVersion}`);
}

const appcast = readFileSync(appcastPath, 'utf8');
const escapedVersion = expectedVersion.replaceAll('.', '\\.');
const versionPattern = new RegExp(
  `<sparkle:version>\\s*${escapedVersion}\\s*</sparkle:version>`,
);
const shortVersionPattern = new RegExp(
  `<sparkle:shortVersionString>\\s*${escapedVersion}\\s*</sparkle:shortVersionString>`,
);
const enclosurePattern = /<enclosure\b(?=[^>]*\burl="https:\/\/[^"?]+\.zip")(?=[^>]*\bsparkle:edSignature="[A-Za-z0-9+/=]+")(?=[^>]*\blength="[1-9]\d*")[^>]*>/s;
const signedFeedPattern = /<!-- sparkle-signatures:\s*\nedSignature: [A-Za-z0-9+/=]+\s*\nlength: [1-9]\d*\s*\n-->/s;

if (!appcast.includes('xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"')) {
  throw new Error('Sparkle appcast namespace is missing');
}
if (!versionPattern.test(appcast) || !shortVersionPattern.test(appcast)) {
  throw new Error(`Sparkle appcast does not contain version ${expectedVersion}`);
}
if (!enclosurePattern.test(appcast)) {
  throw new Error('Sparkle appcast has no signed HTTPS zip enclosure');
}
if (!signedFeedPattern.test(appcast)) {
  throw new Error('Sparkle appcast does not contain a signed-feed block');
}

console.log(`Sparkle appcast is valid for v${expectedVersion}`);
