import { readFileSync } from 'node:fs';

const manifestPath = process.argv[2];

if (!manifestPath) {
  throw new Error('Usage: node scripts/check-updater-manifest.mjs <latest.json>');
}

const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
const platform = manifest.platforms?.['darwin-aarch64'];

if (!/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/.test(manifest.version ?? '')) {
  throw new Error('Updater manifest has no stable semantic version');
}

if (!platform?.url?.endsWith('.app.tar.gz') || !platform.signature) {
  throw new Error('Updater manifest has no signed Apple Silicon macOS update');
}

console.log(`Updater manifest is valid for v${manifest.version}`);
