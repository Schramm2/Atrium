'use client';

import { Check } from 'lucide-react';
import { useBrandTheme } from '@/contexts/BrandThemeContext';
import type { AppIcon, BrandTheme } from '@/lib/appearance';

const THEMES: Array<{ value: BrandTheme; label: string }> = [
  { value: 'ubundi', label: 'Ubundi' },
  { value: 'first-motive', label: 'First Motive' },
];

const ICONS: Array<{ value: AppIcon; label: string; src: string }> = [
  { value: 'ubundi', label: 'Ubundi', src: '/brand/notive-ubundi-icon.png' },
  { value: 'first-motive', label: 'First Motive', src: '/brand/notive-first-motive-icon.png' },
];

export function AppearanceSettings() {
  const { theme, appIcon, setTheme, setAppIcon } = useBrandTheme();

  return (
    <div className="appearance-settings">
      <section className="appearance-panel" aria-labelledby="appearance-heading">
        <div className="appearance-heading">
          <h2 id="appearance-heading">Appearance</h2>
          <p>Choose the interface theme and the icon shown in the Dock and app switcher.</p>
        </div>

        <fieldset className="appearance-group">
          <legend>Interface theme</legend>
          <div className="appearance-choice-grid">
            {THEMES.map(option => {
              const selected = theme === option.value;
              return (
                <button
                  key={option.value}
                  type="button"
                  className="appearance-choice"
                  data-selected={selected || undefined}
                  aria-pressed={selected}
                  onClick={() => setTheme(option.value)}
                >
                  <span className={`appearance-theme-preview appearance-theme-preview-${option.value}`} aria-hidden="true">
                    <span />
                    <span />
                    <span />
                  </span>
                  <span className="appearance-choice-label">
                    {option.label}
                    {selected && <Check aria-hidden="true" />}
                  </span>
                </button>
              );
            })}
          </div>
        </fieldset>

        <fieldset className="appearance-group">
          <legend>App icon</legend>
          <div className="appearance-choice-grid">
            {ICONS.map(option => {
              const selected = appIcon === option.value;
              return (
                <button
                  key={option.value}
                  type="button"
                  className="appearance-choice appearance-icon-choice"
                  data-selected={selected || undefined}
                  aria-pressed={selected}
                  onClick={() => setAppIcon(option.value)}
                >
                  <img src={option.src} alt="" aria-hidden="true" />
                  <span className="appearance-choice-label">
                    {option.label}
                    {selected && <Check aria-hidden="true" />}
                  </span>
                </button>
              );
            })}
          </div>
        </fieldset>
      </section>
    </div>
  );
}
