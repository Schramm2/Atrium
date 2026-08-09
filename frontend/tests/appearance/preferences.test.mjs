import assert from 'node:assert/strict';
import test from 'node:test';

import {
  APP_ICON_STORAGE_KEY,
  BRAND_THEME_STORAGE_KEY,
  isAppIcon,
  isBrandTheme,
} from '../../src/lib/appearance.ts';

test('appearance preferences accept the two supported brand choices', () => {
  for (const value of ['ubundi', 'first-motive']) {
    assert.equal(isBrandTheme(value), true);
    assert.equal(isAppIcon(value), true);
  }

  assert.equal(isBrandTheme('notive'), false);
  assert.equal(isAppIcon('notive'), false);
});

test('the theme keeps its legacy key and the app icon uses a Notive key', () => {
  assert.equal(BRAND_THEME_STORAGE_KEY, 'ubundi-meet-brand-theme');
  assert.equal(APP_ICON_STORAGE_KEY, 'notive-app-icon');
});
