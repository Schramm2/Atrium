'use client';

import { type FormEvent, useEffect, useState } from 'react';
import { Keyboard, Mic, Plus, RefreshCw, ShieldCheck, Tags, X } from 'lucide-react';
import { toast } from 'sonner';
import { invoke } from '@tauri-apps/api/core';
import { dictationService } from '@/services/dictationService';
import type { DictationPreferences } from '@/types/dictation';
import type { AudioDevice } from '@/components/DeviceSelection';
import { useConfig } from '@/contexts/ConfigContext';

const PRESET_SHORTCUTS = [
  { value: 'fn', label: 'Fn' },
  { value: 'command+shift+d', label: '⌘ ⇧ D' },
  { value: 'control+shift+space', label: '⌃ ⇧ Space' },
];

const DEFAULT_PREFERENCES: DictationPreferences = {
  shortcut: 'fn',
  microphone: null,
  vocabulary: [],
};

export function DictationSettings() {
  const { transcriptModelConfig } = useConfig();
  const [preferences, setPreferences] = useState(DEFAULT_PREFERENCES);
  const [microphones, setMicrophones] = useState<AudioDevice[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [customShortcut, setCustomShortcut] = useState(DEFAULT_PREFERENCES.shortcut);
  const [vocabularyTerm, setVocabularyTerm] = useState('');

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
      .then(([saved]) => {
        const preferences = { ...DEFAULT_PREFERENCES, ...saved, vocabulary: saved.vocabulary ?? [] };
        setPreferences(preferences);
        setCustomShortcut(preferences.shortcut);
      })
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
      setCustomShortcut(saved.shortcut);
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

  const selectedPreset = PRESET_SHORTCUTS.some(shortcut => shortcut.value === preferences.shortcut)
    ? preferences.shortcut
    : 'custom';

  const saveCustomShortcut = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const shortcut = customShortcut.trim().toLowerCase();
    if (!shortcut) {
      toast.error('Enter a shortcut');
      return;
    }
    save({ ...preferences, shortcut });
  };

  const addVocabularyTerm = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const term = vocabularyTerm.trim().replace(/\s+/g, ' ');
    if (!term) {
      toast.error('Enter a word or phrase');
      return;
    }
    if (preferences.vocabulary.some(saved => saved.toLowerCase() === term.toLowerCase())) {
      toast.error('This custom term is already saved');
      return;
    }
    setVocabularyTerm('');
    save({ ...preferences, vocabulary: [...preferences.vocabulary, term] });
  };

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
        <label className="block text-sm font-medium text-gray-700" htmlFor="dictation-shortcut">Preset</label>
        <select
          id="dictation-shortcut"
          value={selectedPreset}
          disabled={saving}
          onChange={event => {
            if (event.target.value !== 'custom') save({ ...preferences, shortcut: event.target.value });
          }}
          className="mt-2 w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100 disabled:opacity-60"
        >
          {PRESET_SHORTCUTS.map(shortcut => <option key={shortcut.value} value={shortcut.value}>{shortcut.label}</option>)}
          <option value="custom">Custom shortcut</option>
        </select>
        <form className="mt-4 flex flex-col gap-2 sm:flex-row" onSubmit={saveCustomShortcut}>
          <label className="sr-only" htmlFor="dictation-custom-shortcut">Custom shortcut</label>
          <input
            id="dictation-custom-shortcut"
            value={customShortcut}
            disabled={saving}
            onChange={event => setCustomShortcut(event.target.value)}
            placeholder="fn or command+shift+d"
            spellCheck={false}
            autoCapitalize="none"
            className="min-w-0 flex-1 rounded-lg border border-gray-300 bg-white px-3 py-2.5 font-mono text-sm lowercase focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100 disabled:opacity-60"
          />
          <button type="submit" disabled={saving} className="rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-60">
            {saving ? 'Saving…' : 'Save shortcut'}
          </button>
        </form>
        <p className="mt-2 text-sm text-gray-600">Use Fn, Command, or Control in a custom shortcut. Shortcuts that can type into another app are blocked.</p>
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

      <section className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm" aria-labelledby="dictation-vocabulary-title">
        <div className="mb-5 flex items-start gap-3">
          <Tags className="mt-0.5 h-5 w-5 text-blue-600" aria-hidden="true" />
          <div>
            <h2 id="dictation-vocabulary-title" className="text-lg font-semibold text-gray-900">Custom vocabulary</h2>
            <p className="mt-1 text-sm text-gray-600">Add names and terms exactly as Notive should write them, such as Ubundi. They stay on this device.</p>
          </div>
        </div>
        <form className="flex flex-col gap-2 sm:flex-row" onSubmit={addVocabularyTerm}>
          <label className="sr-only" htmlFor="dictation-vocabulary-term">Word or phrase</label>
          <input
            id="dictation-vocabulary-term"
            value={vocabularyTerm}
            disabled={saving}
            onChange={event => setVocabularyTerm(event.target.value)}
            placeholder="Ubundi"
            maxLength={120}
            className="min-w-0 flex-1 rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-100 disabled:opacity-60"
          />
          <button type="submit" disabled={saving} className="inline-flex items-center justify-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-60">
            <Plus className="h-4 w-4" aria-hidden="true" />
            Add term
          </button>
        </form>
        {preferences.vocabulary.length > 0 ? (
          <ul className="mt-4 flex flex-wrap gap-2" aria-label="Custom vocabulary terms">
            {preferences.vocabulary.map(term => (
              <li key={term} className="inline-flex items-center gap-1 rounded-md bg-blue-50 py-1 pl-2.5 pr-1 text-sm text-blue-950">
                <span>{term}</span>
                <button
                  type="button"
                  onClick={() => save({ ...preferences, vocabulary: preferences.vocabulary.filter(saved => saved !== term) })}
                  disabled={saving}
                  className="rounded p-1 text-blue-700 hover:bg-blue-100 disabled:opacity-60"
                  aria-label={`Remove ${term}`}
                >
                  <X className="h-3.5 w-3.5" aria-hidden="true" />
                </button>
              </li>
            ))}
          </ul>
        ) : (
          <p className="mt-4 text-sm text-gray-500">No custom terms yet.</p>
        )}
        <p className="mt-4 text-sm text-gray-600">Notive gives these terms to Whisper before dictation and corrects close spellings from all local speech models.</p>
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
