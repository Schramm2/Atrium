'use client';

import { Gauge, Languages } from 'lucide-react';
import { LanguageSelection } from '@/components/LanguageSelection';
import { Switch } from '@/components/ui/switch';
import { useConfig } from '@/contexts/ConfigContext';

export function TranscriptionPreferences() {
  const {
    selectedLanguage,
    setSelectedLanguage,
    showConfidenceIndicator,
    toggleConfidenceIndicator,
    transcriptModelConfig,
  } = useConfig();

  return (
    <div className="mt-6 space-y-6">
      <section className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="mb-4 flex items-start gap-3">
          <Languages className="mt-0.5 h-5 w-5 text-blue-600" aria-hidden="true" />
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Language</h2>
            <p className="mt-1 text-sm text-gray-600">Set how Notive detects or translates spoken language.</p>
          </div>
        </div>
        <LanguageSelection
          selectedLanguage={selectedLanguage}
          onLanguageChange={setSelectedLanguage}
          provider={transcriptModelConfig.provider}
        />
      </section>

      <section className="flex items-center justify-between gap-6 rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="flex items-start gap-3">
          <Gauge className="mt-0.5 h-5 w-5 text-blue-600" aria-hidden="true" />
          <div>
            <h2 className="font-semibold text-gray-900">Confidence indicators</h2>
            <p className="mt-1 text-sm text-gray-600">Show transcript quality indicators when the engine provides confidence data.</p>
          </div>
        </div>
        <Switch checked={showConfidenceIndicator} onCheckedChange={toggleConfidenceIndicator} />
      </section>
    </div>
  );
}
