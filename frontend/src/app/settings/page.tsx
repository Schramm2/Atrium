'use client';

import { ArrowLeft, Bot, Info, Keyboard, Mic, Palette, Settings2, Sparkles } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { AppearanceSettings } from '@/components/AppearanceSettings';
import { About } from '@/components/About';
import { DictationSettings } from '@/components/DictationSettings';
import { PreferenceSettings } from '@/components/PreferenceSettings';
import { RecordingSettings } from '@/components/RecordingSettings';
import { SummaryModelSettings } from '@/components/SummaryModelSettings';
import { TranscriptSettings } from '@/components/TranscriptSettings';
import { TranscriptionPreferences } from '@/components/TranscriptionPreferences';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useConfig } from '@/contexts/ConfigContext';

const TABS = [
  { value: 'general', label: 'General', icon: Settings2 },
  { value: 'appearance', label: 'Appearance', icon: Palette },
  { value: 'recording', label: 'Recording', icon: Mic },
  { value: 'dictation', label: 'Dictation', icon: Keyboard },
  { value: 'transcription', label: 'Transcription', icon: Bot },
  { value: 'summary', label: 'Summary', icon: Sparkles },
  { value: 'about', label: 'About', icon: Info },
] as const;

export default function SettingsPage() {
  const router = useRouter();
  const { transcriptModelConfig, setTranscriptModelConfig } = useConfig();

  return (
    <div className="flex h-screen flex-col bg-gray-50 text-gray-950">
      <header className="shrink-0 border-b border-gray-200 bg-white/90 backdrop-blur">
        <div className="mx-auto flex max-w-7xl items-center gap-4 px-5 py-5 sm:px-8">
          <button
            type="button"
            onClick={() => router.back()}
            className="inline-flex items-center gap-2 rounded-lg px-2 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-100 hover:text-gray-950"
          >
            <ArrowLeft className="h-4 w-4" aria-hidden="true" />
            Back
          </button>
          <h1 className="text-2xl font-semibold tracking-tight">Settings</h1>
        </div>
      </header>

      <div className="min-h-0 flex-1 overflow-y-auto">
        <Tabs defaultValue="general" orientation="vertical" className="mx-auto grid max-w-7xl gap-6 px-5 py-6 sm:px-8 lg:grid-cols-[220px_minmax(0,1fr)] lg:gap-10">
          <aside>
            <TabsList className="flex h-auto w-full justify-start gap-1 overflow-x-auto rounded-xl border border-gray-200 bg-white p-2 shadow-sm lg:sticky lg:top-6 lg:flex-col lg:overflow-visible">
              {TABS.map(tab => {
                const Icon = tab.icon;
                return (
                  <TabsTrigger
                    key={tab.value}
                    value={tab.value}
                    className="justify-start gap-3 rounded-lg px-3 py-2.5 text-gray-600 data-[state=active]:bg-blue-50 data-[state=active]:text-blue-700 data-[state=active]:shadow-none"
                  >
                    <Icon className="h-4 w-4" aria-hidden="true" />
                    {tab.label}
                  </TabsTrigger>
                );
              })}
            </TabsList>
          </aside>

          <main className="min-w-0 pb-10">
            <TabsContent value="general" className="mt-0"><PreferenceSettings /></TabsContent>
            <TabsContent value="appearance" className="mt-0"><AppearanceSettings /></TabsContent>
            <TabsContent value="recording" className="mt-0"><RecordingSettings /></TabsContent>
            <TabsContent value="dictation" className="mt-0"><DictationSettings /></TabsContent>
            <TabsContent value="transcription" className="mt-0">
              <section className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
                <h2 className="text-lg font-semibold text-gray-900">Speech model</h2>
                <div className="mt-5">
                  <TranscriptSettings
                    transcriptModelConfig={transcriptModelConfig}
                    setTranscriptModelConfig={setTranscriptModelConfig}
                  />
                </div>
              </section>
              <TranscriptionPreferences />
            </TabsContent>
            <TabsContent value="summary" className="mt-0"><SummaryModelSettings /></TabsContent>
            <TabsContent value="about" className="mt-0"><About /></TabsContent>
          </main>
        </Tabs>
      </div>
    </div>
  );
}
