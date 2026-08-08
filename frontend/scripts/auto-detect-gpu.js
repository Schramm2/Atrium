#!/usr/bin/env node
/**
 * Auto-detect GPU capabilities and set appropriate features
 * Used by npm scripts to automatically enable hardware acceleration
 */

const os = require('os');

function detectGPU() {
  const platform = os.platform();

  // macOS: Metal is always available, check for Apple Silicon for CoreML
  if (platform === 'darwin') {
    const arch = os.arch();
    if (arch === 'arm64') {
      console.log('🍎 Apple Silicon detected - using Metal + CoreML');
      return 'coreml'; // CoreML includes Metal
    } else {
      console.log('🍎 macOS Intel detected - using Metal');
      return 'metal';
    }
  }

  throw new Error(`Ubundi Meet supports macOS only (received ${platform}).`);
}

// Redirect console.log to stderr so only the feature goes to stdout
const originalLog = console.log;
console.log = (...args) => {
  process.stderr.write(args.join(' ') + '\n');
};

// Detect and output the feature
const feature = detectGPU();

// Restore console.log
console.log = originalLog;

// Only write the feature to stdout (no newline, no extra text)
if (feature) {
  process.stdout.write(feature);
}
