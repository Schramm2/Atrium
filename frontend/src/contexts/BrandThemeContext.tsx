'use client';

import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import {
  APP_ICON_STORAGE_KEY,
  BRAND_THEME_STORAGE_KEY,
  type AppIcon,
  type BrandTheme,
  isAppIcon,
  isBrandTheme,
} from '@/lib/appearance';

export type { AppIcon, BrandTheme } from '@/lib/appearance';

interface BrandThemeContextValue {
  theme: BrandTheme;
  appIcon: AppIcon;
  setTheme: (theme: BrandTheme) => void;
  setAppIcon: (icon: AppIcon) => void;
  toggleTheme: () => void;
}

const BrandThemeContext = createContext<BrandThemeContextValue | null>(null);

function applyNativeAppIcon(icon: AppIcon) {
  void invoke('set_app_icon', { icon }).catch(error => {
    console.error('Failed to update the Notive app icon:', error);
  });
}

export function BrandThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<BrandTheme>('ubundi');
  const [appIcon, setAppIconState] = useState<AppIcon>('ubundi');

  useEffect(() => {
    const savedTheme = window.localStorage.getItem(BRAND_THEME_STORAGE_KEY);
    const initialTheme = isBrandTheme(savedTheme) ? savedTheme : 'ubundi';
    const savedIcon = window.localStorage.getItem(APP_ICON_STORAGE_KEY);
    const initialIcon = isAppIcon(savedIcon) ? savedIcon : initialTheme;

    setThemeState(initialTheme);
    setAppIconState(initialIcon);
    document.documentElement.dataset.brandTheme = initialTheme;
    applyNativeAppIcon(initialIcon);
  }, []);

  const setTheme = useCallback((nextTheme: BrandTheme) => {
    setThemeState(nextTheme);
    window.localStorage.setItem(BRAND_THEME_STORAGE_KEY, nextTheme);
    document.documentElement.dataset.brandTheme = nextTheme;

    document.body.classList.add('brand-theme-changing');
    window.setTimeout(() => document.body.classList.remove('brand-theme-changing'), 240);
  }, []);

  const setAppIcon = useCallback((nextIcon: AppIcon) => {
    setAppIconState(nextIcon);
    window.localStorage.setItem(APP_ICON_STORAGE_KEY, nextIcon);
    applyNativeAppIcon(nextIcon);
  }, []);

  const toggleTheme = useCallback(() => {
    setTheme(theme === 'ubundi' ? 'first-motive' : 'ubundi');
  }, [setTheme, theme]);

  return (
    <BrandThemeContext.Provider value={{ theme, appIcon, setTheme, setAppIcon, toggleTheme }}>
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
