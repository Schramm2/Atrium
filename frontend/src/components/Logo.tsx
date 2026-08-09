import React from "react";
import Image from "next/image";
import { Dialog, DialogContent, DialogTitle, DialogTrigger } from "./ui/dialog";
import { VisuallyHidden } from "./ui/visually-hidden";
import { About } from "./About";
import { useBrandTheme } from "@/contexts/BrandThemeContext";

interface LogoProps {
    isCollapsed: boolean;
}

const Logo = React.forwardRef<HTMLButtonElement, LogoProps>(({ isCollapsed }, ref) => {
  const { theme } = useBrandTheme();
  const isFirstMotive = theme === 'first-motive';

  const brandMark = isFirstMotive ? (
    <Image src="/first-motive-mark.svg" alt="" width={38} height={38} className="first-motive-mark" />
  ) : (
    <Image src="/ubundi-mark.png" alt="" width={38} height={38} className="rounded-lg" />
  );

  return (
    <Dialog aria-describedby={undefined}>
      {isCollapsed ? (
        <DialogTrigger asChild>
          <button ref={ref} className="flex items-center justify-center mb-2 cursor-pointer bg-transparent border-none p-0 ubundi-logo-lockup" aria-label="About Ubundi Meet">
            {brandMark}
          </button>
        </DialogTrigger>
      ) : (
        <DialogTrigger asChild>
          <button ref={ref} className="ubundi-logo-lockup brand-logo-button" aria-label="About Ubundi Meet">
            {isFirstMotive ? (
              <span className="first-motive-wordmark">
                {brandMark}
                <span>first motive</span>
              </span>
            ) : (
              <Image src="/ubundi-logo-navy.png" alt="Ubundi" width={164} height={46} priority />
            )}
          </button>
        </DialogTrigger>
      )}
      <DialogContent>
        <VisuallyHidden>
          <DialogTitle>About Ubundi Meet</DialogTitle>
        </VisuallyHidden>
        <About />
      </DialogContent>
    </Dialog>
  );
});

Logo.displayName = "Logo";

export default Logo;
