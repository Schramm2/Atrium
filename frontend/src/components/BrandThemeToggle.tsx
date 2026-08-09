'use client';

import { Blend, Check } from 'lucide-react';
import { useBrandTheme } from '@/contexts/BrandThemeContext';

interface BrandThemeToggleProps {
  collapsed?: boolean;
}

export function BrandThemeToggle({ collapsed = false }: BrandThemeToggleProps) {
  const { theme, toggleTheme } = useBrandTheme();
  const isFirstMotive = theme === 'first-motive';
  const nextThemeName = isFirstMotive ? 'Ubundi' : 'First Motive';

  if (collapsed) {
    return (
      <button
        type="button"
        onClick={toggleTheme}
        className="brand-theme-toggle brand-theme-toggle-collapsed"
        aria-label={`Use ${nextThemeName} theme`}
        title={`Use ${nextThemeName} theme`}
      >
        <Blend aria-hidden="true" />
      </button>
    );
  }

  return (
    <div className="brand-theme-control" aria-label="Application theme">
      <span className="brand-theme-label">Theme</span>
      <button
        type="button"
        onClick={toggleTheme}
        className="brand-theme-toggle"
        aria-pressed={isFirstMotive}
        aria-label={`Current theme: ${isFirstMotive ? 'First Motive' : 'Ubundi'}. Use ${nextThemeName} theme.`}
      >
        <span className={!isFirstMotive ? 'is-active' : undefined}>
          {!isFirstMotive && <Check aria-hidden="true" />}
          Ubundi
        </span>
        <span className={isFirstMotive ? 'is-active' : undefined}>
          {isFirstMotive && <Check aria-hidden="true" />}
          First Motive
        </span>
      </button>
    </div>
  );
}
