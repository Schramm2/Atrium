'use client';

import MainNav from '@/components/MainNav';
import { DictationWorkspace } from '@/components/Dictation';

export default function DictationPage() {
  return (
    <div className="ubundi-dictation-page">
      <DictationWorkspace
        renderHeader={(status) => (
          <MainNav title="Dictation" eyebrow="Ubundi Meet" status={status} />
        )}
      />
    </div>
  );
}
