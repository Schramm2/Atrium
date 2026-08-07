import React from "react";
import Image from "next/image";
import { Dialog, DialogContent, DialogTitle, DialogTrigger } from "./ui/dialog";
import { VisuallyHidden } from "./ui/visually-hidden";
import { About } from "./About";

interface LogoProps {
    isCollapsed: boolean;
}

const Logo = React.forwardRef<HTMLButtonElement, LogoProps>(({ isCollapsed }, ref) => {
  return (
    <Dialog aria-describedby={undefined}>
      {isCollapsed ? (
        <DialogTrigger asChild>
          <button ref={ref} className="flex items-center justify-center mb-2 cursor-pointer bg-transparent border-none p-0 ubundi-logo-lockup">
            <Image src="/ubundi-mark.png" alt="Ubundi" width={38} height={38} className="rounded-lg" />
          </button>
        </DialogTrigger>
      ) : (
        <DialogTrigger asChild>
          <span className="ubundi-logo-lockup">
            <Image src="/ubundi-logo-navy.png" alt="Ubundi" width={164} height={46} priority />
          </span>
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
