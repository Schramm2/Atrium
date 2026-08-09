'use client';

import { useEffect, useState } from 'react';
import { Bell, BellRing, FolderOpen, HardDrive, Moon, RefreshCw, Volume2 } from 'lucide-react';
import { invoke } from '@tauri-apps/api/core';
import { toast } from 'sonner';
import { Switch } from '@/components/ui/switch';
import { useConfig, type NotificationSettings } from '@/contexts/ConfigContext';

const AUTOMATIC_UPDATE_CHECKS_KEY = 'automaticUpdateChecks';

export function PreferenceSettings() {
  const {
    notificationSettings,
    storageLocations,
    isLoadingPreferences,
    loadPreferences,
    updateNotificationSettings,
  } = useConfig();
  const [automaticUpdateChecks, setAutomaticUpdateChecks] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadPreferences();
    const saved = window.localStorage.getItem(AUTOMATIC_UPDATE_CHECKS_KEY);
    setAutomaticUpdateChecks(saved !== 'false');
  }, [loadPreferences]);

  const saveNotifications = async (next: NotificationSettings) => {
    setSaving(true);
    try {
      await updateNotificationSettings(next);
      toast.success('Notification settings saved');
    } catch (error) {
      toast.error('Could not save notification settings', { description: String(error) });
    } finally {
      setSaving(false);
    }
  };

  const setTopLevel = <K extends keyof NotificationSettings>(key: K, value: NotificationSettings[K]) => {
    if (!notificationSettings) return;
    saveNotifications({ ...notificationSettings, [key]: value });
  };

  const setNotificationType = (
    key: keyof NotificationSettings['notification_preferences'],
    value: boolean,
  ) => {
    if (!notificationSettings) return;
    saveNotifications({
      ...notificationSettings,
      notification_preferences: {
        ...notificationSettings.notification_preferences,
        [key]: value,
      },
    });
  };

  const setAutomaticUpdates = (enabled: boolean) => {
    setAutomaticUpdateChecks(enabled);
    window.localStorage.setItem(AUTOMATIC_UPDATE_CHECKS_KEY, enabled.toString());
    window.dispatchEvent(new CustomEvent('automatic-update-checks-changed', { detail: enabled }));
    toast.success('Update preference saved');
  };

  const openFolder = async (type: 'database' | 'models' | 'recordings') => {
    const commands = {
      database: 'open_database_folder',
      models: 'open_models_folder',
      recordings: 'open_recordings_folder',
    } as const;
    try {
      await invoke(commands[type]);
    } catch (error) {
      toast.error(`Could not open the ${type} folder`, { description: String(error) });
    }
  };

  if (isLoadingPreferences && !notificationSettings && !storageLocations) {
    return <div className="rounded-xl border border-gray-200 bg-white p-6 text-sm text-gray-500">Loading general settings…</div>;
  }

  return (
    <div className="space-y-6">
      <section className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="mb-5 flex items-start gap-3">
          <Bell className="mt-0.5 h-5 w-5 text-blue-600" aria-hidden="true" />
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Notifications</h2>
            <p className="mt-1 text-sm text-gray-600">Choose which local events can notify you.</p>
          </div>
        </div>

        {notificationSettings ? (
          <div className="divide-y divide-gray-100">
            <SettingSwitch
              icon={<BellRing />}
              label="Recording activity"
              description="Notify when recording starts, pauses, resumes, or stops."
              checked={notificationSettings.recording_notifications
                && notificationSettings.notification_preferences.show_recording_started
                && notificationSettings.notification_preferences.show_recording_stopped
                && notificationSettings.notification_preferences.show_recording_paused
                && notificationSettings.notification_preferences.show_recording_resumed}
              disabled={saving}
              onChange={value => {
                saveNotifications({
                  ...notificationSettings,
                  recording_notifications: value,
                  notification_preferences: {
                    ...notificationSettings.notification_preferences,
                    show_recording_started: value,
                    show_recording_stopped: value,
                    show_recording_paused: value,
                    show_recording_resumed: value,
                  },
                });
              }}
            />
            <SettingSwitch
              label="Transcription complete"
              description="Notify when background transcription finishes."
              checked={notificationSettings.notification_preferences.show_transcription_complete}
              disabled={saving}
              onChange={value => setNotificationType('show_transcription_complete', value)}
            />
            <SettingSwitch
              label="System errors"
              description="Notify when a background task needs your attention."
              checked={notificationSettings.notification_preferences.show_system_errors}
              disabled={saving}
              onChange={value => setNotificationType('show_system_errors', value)}
            />
            <SettingSwitch
              icon={<Volume2 />}
              label="Notification sound"
              description="Play a sound with Notive notifications."
              checked={notificationSettings.notification_sound}
              disabled={saving}
              onChange={value => setTopLevel('notification_sound', value)}
            />
            <SettingSwitch
              icon={<Moon />}
              label="Pause non-critical notifications"
              description="Temporarily suppress notifications that do not require immediate attention."
              checked={notificationSettings.manual_dnd_mode}
              disabled={saving}
              onChange={value => setTopLevel('manual_dnd_mode', value)}
            />
          </div>
        ) : (
          <p className="text-sm text-amber-700">Notification settings are not available.</p>
        )}
      </section>

      <section className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="mb-2 flex items-start gap-3">
          <RefreshCw className="mt-0.5 h-5 w-5 text-blue-600" aria-hidden="true" />
          <div className="flex-1">
            <div className="flex items-center justify-between gap-6">
              <div>
                <h2 className="font-semibold text-gray-900">Automatic update checks</h2>
                <p className="mt-1 text-sm text-gray-600">Check once per day while Notive is open. Updates are never installed without confirmation.</p>
              </div>
              <Switch checked={automaticUpdateChecks} onCheckedChange={setAutomaticUpdates} />
            </div>
          </div>
        </div>
      </section>

      <section className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="mb-5 flex items-start gap-3">
          <HardDrive className="mt-0.5 h-5 w-5 text-blue-600" aria-hidden="true" />
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Local data</h2>
            <p className="mt-1 text-sm text-gray-600">Open the folders where Notive keeps its local data.</p>
          </div>
        </div>
        <div className="space-y-3">
          <FolderRow label="Database" path={storageLocations?.database} onOpen={() => openFolder('database')} />
          <FolderRow label="Models" path={storageLocations?.models} onOpen={() => openFolder('models')} />
          <FolderRow label="Recordings" path={storageLocations?.recordings} onOpen={() => openFolder('recordings')} />
        </div>
      </section>
    </div>
  );
}

function SettingSwitch({
  icon,
  label,
  description,
  checked,
  disabled,
  onChange,
}: {
  icon?: React.ReactNode;
  label: string;
  description: string;
  checked: boolean;
  disabled?: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <div className="flex items-center justify-between gap-6 py-4 first:pt-0 last:pb-0">
      <div className="flex items-start gap-3">
        {icon && <span className="mt-0.5 text-gray-400 [&>svg]:h-4 [&>svg]:w-4">{icon}</span>}
        <div>
          <h3 className="text-sm font-medium text-gray-900">{label}</h3>
          <p className="mt-0.5 text-sm text-gray-600">{description}</p>
        </div>
      </div>
      <Switch checked={checked} disabled={disabled} onCheckedChange={onChange} />
    </div>
  );
}

function FolderRow({ label, path, onOpen }: { label: string; path?: string; onOpen: () => void }) {
  return (
    <div className="flex items-center justify-between gap-4 rounded-lg bg-gray-50 px-4 py-3">
      <div className="min-w-0">
        <p className="text-sm font-medium text-gray-900">{label}</p>
        <p className="truncate text-xs text-gray-500">{path || 'Location unavailable'}</p>
      </div>
      <button type="button" onClick={onOpen} className="inline-flex shrink-0 items-center gap-2 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100">
        <FolderOpen className="h-4 w-4" aria-hidden="true" />
        Open
      </button>
    </div>
  );
}
