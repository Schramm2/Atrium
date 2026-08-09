'use client';

import Image from 'next/image';
import { useBrandTheme } from '@/contexts/BrandThemeContext';

interface BrandAssetProps {
  className?: string;
  priority?: boolean;
}

interface BrandMarkProps extends BrandAssetProps {
  size?: number;
}

interface BrandWordmarkProps extends BrandAssetProps {
  width?: number;
}

export function BrandMark({ size = 38, className = '', priority = false }: BrandMarkProps) {
  const { theme } = useBrandTheme();
  const isFirstMotive = theme === 'first-motive';

  return (
    <Image
      src={isFirstMotive ? '/first-motive-mark.svg' : '/ubundi-mark.png'}
      alt=""
      width={size}
      height={size}
      priority={priority}
      className={`${isFirstMotive ? 'first-motive-mark' : 'rounded-xl'} ${className}`.trim()}
    />
  );
}

export function BrandWordmark({ width = 164, className = '', priority = false }: BrandWordmarkProps) {
  const { theme } = useBrandTheme();

  if (theme === 'first-motive') {
    return (
      <span className={`first-motive-wordmark ${className}`.trim()}>
        <BrandMark size={38} priority={priority} />
        <span>first motive</span>
      </span>
    );
  }

  return (
    <Image
      src="/ubundi-logo-navy.png"
      alt="Ubundi"
      width={width}
      height={Math.round(width * 46 / 164)}
      priority={priority}
      className={className}
    />
  );
}
