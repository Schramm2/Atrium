'use client';

import React from 'react';

interface MainNavProps {
  title: string;
  eyebrow?: string;
  status?: React.ReactNode;
}

const MainNav: React.FC<MainNavProps> = ({ title, eyebrow, status }) => {
  return (
    <header className="ubundi-main-nav">
      <div>
        {eyebrow && <p className="ubundi-eyebrow">{eyebrow}</p>}
        <h1>{title}</h1>
      </div>
      {status}
    </header>
  );
};

export default MainNav;
