'use client';

import { useEffect, useState } from 'react';
import { Keyboard, Mic, RefreshCw, ShieldCheck } from 'lucide-react';
import { toast } from 'sonner';
import { invoke } from '@tauri-apps/api/core';
import { dictationService } from '@/services/dictationService';
import type { DictationPreferences } from '@/types/dictation';
import type { AudioDevice } from '@/components/DeviceSelection';
import { useConfig } from '@/contexts/ConfigContext';

const SHORTCUTS = [
  { value: 'option+space', label: '⌥ Space' },
  { value: 'control+space', label: '⌃ Space' },
  { value: 'option+d', label: '⌥ D' },
  { value: 'command+shift+d', label: '⌘ ⇧ D' },
];

const DEFAULT_PREFERENCES: DictationPreferences = {
  shortcut: 'option+space',
  microphone: null,
};

export function DictationSettings() {
  const { transcriptModelConfig } = useConfig();
  const [preferences, setPreferences] = useState(DEFAULT_PREFERENCES);
  const [microphones, setMicrophones] = useState<AudioDevice[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const loadMicrophones = async () => {
    setRefreshing(true);
    try {
      const devices = await invoke<AudioDevice[]>('get_audio_devices');
      setMicrophones(devices.filter(device => device.device_type === 'Input'));
    } catch (error) {
      toast.error('Could not load microphones', { description: String(error) });
    } finally {
      setRefreshing(false);
    }
  };

  useEffect(() => {
    Promise.all([dictationService.getPreferences(), loadMicrophones()])
      .then(([saved]) => setPreferences(saved))
      .catch(error => toast.error('Could not load dictation settings', { description: String(error) }))
      .finally(() => setLoading(false));
  }, []);

  const save = async (next: DictationPreferences) => {
    const previous = preferences;
    setPreferences(next);
    setSaving(true);
    try {
      const saved = await dictationService.setPreferences(next);
      setPreferences(saved);
      toast.success('Dictation settings saved');
    } catch (error) {
      setPreferences(previous);
      toast.error('Could not save dictation settings', { description: String(error) });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div className="rounded-xl border border-gray-200 bg-white p-6 text-sm text-gray-500">Loading dictation settings…</div>;
  }

  return (
    <div className="space-y-6">
      <section className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="mb-5 flex items-start gap-3">
          <Keyboard className="mt-0.5 h-5 w-5 text-blue-600" aria-hidden="true" />
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Global shortcut</h2>
            <p className="mt-1 text-sm text-gray-600">Hold the shortcut to speak. Release it to transcribe and insert the text.</p>
          </div>
        </div>
        <label className="block text-sm font-medium text-gray-700" htmlFor="dictation-shortcut">Shortcut</label>
        <select
          id="dictation-shortcut"
          value={preferences.shortcut}
          disabled={saving}
          onChange={event => save({ ...preferences, shortcut: event.target.value })}
          className="mt-2 w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100 disabled:opacity-60"
        >
          {SHORTCUTS.map(shortcut => <option key={shortcut.value} value={shortcut.value}>{shortcut.label}</option>)}
        </select>
      </section>

      <section className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="mb-5 flex items-start justify-between gap-4">
          <div className="flex items-start gap-3">
            <Mic className="mt-0.5 h-5 w-5 text-blue-600" aria-hidden="true" />
            <div>
              <h2 className="text-lg font-semibold text-gray-900">Dictation microphone</h2>
              <p className="mt-1 text-sm text-gray-600">Choose a microphone for dictation without changing meeting recording devices.</p>
            </div>
          </div>
          <button type="button" onClick={loadMicrophones} disabled={refreshing || saving} className="rounded-lg p-2 text-gray-500 hover:bg-gray-100 disabled:opacity-50" aria-label="Refresh microphones">
            <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
          </button>
        </div>
        <label className="block text-sm font-medium text-gray-700" htmlFor="dictation-microphone">Microphone</label>
        <select
          id="dictation-microphone"
          value={preferences.microphone ?? 'default'}
          disabled={saving}
          onChange={event => save({ ...preferences, microphone: event.target.value === 'default' ? null : event.target.value })}
          className="mt-2 w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100 disabled:opacity-60"
        >
          <option value="default">System default</option>
          {microphones.map(device => <option key={device.name} value={device.name}>{device.name}</option>)}
        </select>
      </section>

      <section className="rounded-xl border border-blue-100 bg-blue-50 p-5">
        <div className="flex items-start gap-3">
          <ShieldCheck className="mt-0.5 h-5 w-5 text-blue-700" aria-hidden="true" />
          <div>
            <h2 className="font-semibold text-blue-950">Transcription model</h2>
            <p className="mt-1 text-sm text-blue-800">Dictation uses {transcriptModelConfig.provider === 'parakeet' ? 'Parakeet' : 'Whisper'} · {transcriptModelConfig.model}. Change it in Transcription settings.</p>
          </div>
        </div>
      </section>
    </div>
  );
}
