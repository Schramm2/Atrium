'use client';

import React from 'react';
import { useSidebar } from '@/components/Sidebar/SidebarProvider';

interface MainContentProps {
  children: React.ReactNode;
}

const MainContent: React.FC<MainContentProps> = ({ children }) => {
  const { isCollapsed } = useSidebar();

  return (
    <main 
      className={`ubundi-main-content min-h-screen flex-none transition-[width,margin] duration-300 ${
        isCollapsed ? 'ml-16 w-[calc(100vw-4rem)]' : 'ml-[280px] w-[calc(100vw-280px)]'
      }`}
    >
      <div>
        {children}
      </div>
    </main>
  );
};

export default MainContent;
