export type BrandTheme = 'ubundi' | 'first-motive';
export type AppIcon = 'ubundi' | 'first-motive';

export const BRAND_THEME_STORAGE_KEY = 'ubundi-meet-brand-theme';
export const APP_ICON_STORAGE_KEY = 'notive-app-icon';

export function isBrandTheme(value: string | null): value is BrandTheme {
  return value === 'ubundi' || value === 'first-motive';
}

export function isAppIcon(value: string | null): value is AppIcon {
  return value === 'ubundi' || value === 'first-motive';
}
