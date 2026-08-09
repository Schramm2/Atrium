'use client';

import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';

export type BrandTheme = 'ubundi' | 'first-motive';

const STORAGE_KEY = 'ubundi-meet-brand-theme';

interface BrandThemeContextValue {
  theme: BrandTheme;
  setTheme: (theme: BrandTheme) => void;
  toggleTheme: () => void;
}

const BrandThemeContext = createContext<BrandThemeContextValue | null>(null);

function isBrandTheme(value: string | null): value is BrandTheme {
  return value === 'ubundi' || value === 'first-motive';
}

export function BrandThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<BrandTheme>('ubundi');

  useEffect(() => {
    const savedTheme = window.localStorage.getItem(STORAGE_KEY);
    const initialTheme = isBrandTheme(savedTheme) ? savedTheme : 'ubundi';
    setThemeState(initialTheme);
    document.documentElement.dataset.brandTheme = initialTheme;
  }, []);

  const setTheme = useCallback((nextTheme: BrandTheme) => {
    setThemeState(nextTheme);
    window.localStorage.setItem(STORAGE_KEY, nextTheme);
    document.documentElement.dataset.brandTheme = nextTheme;

    document.body.classList.add('brand-theme-changing');
    window.setTimeout(() => document.body.classList.remove('brand-theme-changing'), 240);
  }, []);

  const toggleTheme = useCallback(() => {
    setTheme(theme === 'ubundi' ? 'first-motive' : 'ubundi');
  }, [setTheme, theme]);

  return (
    <BrandThemeContext.Provider value={{ theme, setTheme, toggleTheme }}>
      {children}
    </BrandThemeContext.Provider>
  );
}

export function useBrandTheme() {
  const context = useContext(BrandThemeContext);
  if (!context) {
    throw new Error('useBrandTheme must be used within a BrandThemeProvider');
  }
  return context;
}
