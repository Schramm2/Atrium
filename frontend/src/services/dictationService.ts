import { invoke } from '@tauri-apps/api/core';
import { listen, type UnlistenFn } from '@tauri-apps/api/event';
import {
  DEFAULT_DICTATION_STATUS,
  type DictationResult,
  type DictationPreferences,
  type DictationResultPayload,
  type DictationState,
  type DictationStatePayload,
  type DictationStatus,
} from '@/types/dictation';

class DictationService {
  getPreferences(): Promise<DictationPreferences> {
    return invoke<DictationPreferences>('get_dictation_preferences');
  }

  setPreferences(preferences: DictationPreferences): Promise<DictationPreferences> {
    return invoke<DictationPreferences>('set_dictation_preferences', { preferences });
  }

  start(): Promise<DictationStatus> {
    return invoke<DictationStatePayload>('start_dictation').then(normalizeStatus);
  }

  stop(): Promise<DictationResult> {
    return invoke<DictationResultPayload>('stop_dictation').then(normalizeResult);
  }

  cancel(): Promise<DictationStatus> {
    return invoke<DictationStatePayload>('cancel_dictation').then(normalizeStatus);
  }

  getStatus(): Promise<DictationStatus> {
    return invoke<DictationStatePayload>('get_dictation_status').then(normalizeStatus);
  }

  onStateChanged(callback: (status: DictationStatus) => void): Promise<UnlistenFn> {
    return listen<DictationStatePayload>('dictation-state-changed', (event) => {
      callback(normalizeStatus(event.payload));
    });
  }

  onResult(callback: (result: DictationResult) => void): Promise<UnlistenFn> {
    return listen<DictationResultPayload>('dictation-result', (event) => {
      callback(normalizeResult(event.payload));
    });
  }
}

export const dictationService = new DictationService();

function normalizeStatus(payload: DictationStatePayload): DictationStatus {
  if (typeof payload === 'string') {
    return { ...DEFAULT_DICTATION_STATUS, state: normalizeState(payload) };
  }

  const state = getPayloadState(payload);
  return {
    ...DEFAULT_DICTATION_STATUS,
    ...payload,
    state,
    accessibility_granted: payload.accessibility_granted ?? payload.accessibilityGranted ?? false,
    retains_audio: payload.retains_audio ?? payload.retainsAudio ?? false,
    error: payload.error ?? null,
  };
}

function getPayloadState(payload: Exclude<DictationStatePayload, string>): DictationState {
  if (payload.state) return normalizeState(payload.state);
  if ('status' in payload && payload.status) return normalizeState(payload.status);
  if ('Recording' in payload || 'recording' in payload) return 'recording';
  if ('Processing' in payload || 'processing' in payload) return 'transcribing';
  return 'idle';
}

function normalizeState(state: DictationState | 'processing'): DictationState {
  return state === 'processing' ? 'transcribing' : state;
}

function normalizeResult(payload: DictationResultPayload): DictationResult {
  const nestedResult = 'result' in payload ? payload.result : undefined;
  const transcript = 'transcript' in payload ? payload.transcript : undefined;
  const text = payload.text
    ?? transcript?.text
    ?? nestedResult?.text
    ?? nestedResult?.transcript?.text
    ?? '';

  return {
    text,
    duration_ms: payload.duration_ms,
    created_at: payload.created_at,
  };
}
