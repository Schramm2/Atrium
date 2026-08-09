import { invoke } from '@tauri-apps/api/core';
import { listen, type UnlistenFn } from '@tauri-apps/api/event';
import {
  DEFAULT_DICTATION_STATUS,
  type DictationResult,
  type DictationResultPayload,
  type DictationState,
  type DictationStatePayload,
  type DictationStatus,
} from '@/types/dictation';

class DictationService {
  start(): Promise<void> {
    return invoke<void>('start_dictation');
  }

  stop(): Promise<void> {
    return invoke<void>('stop_dictation');
  }

  cancel(): Promise<void> {
    return invoke<void>('cancel_dictation');
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
