export type DictationState =
  | 'idle'
  | 'starting'
  | 'recording'
  | 'transcribing'
  | 'completed'
  | 'cancelled'
  | 'error';

export interface DictationStatus {
  state: DictationState;
  shortcut: string;
  microphone: string;
  model: string;
  accessibility_granted: boolean;
  retains_audio: boolean;
  error: string | null;
}

export interface DictationResult {
  text: string;
  duration_ms?: number | null;
  created_at?: string | null;
}

export interface DictationPreferences {
  shortcut: string;
  microphone: string | null;
}

export type DictationStatePayload =
  | DictationStatus
  | DictationState
  | 'processing'
  | {
      state?: DictationState | 'processing';
      status?: DictationState | 'processing';
      shortcut?: string;
      microphone?: string;
      model?: string;
      accessibility_granted?: boolean;
      accessibilityGranted?: boolean;
      retains_audio?: boolean;
      retainsAudio?: boolean;
      error?: string | null;
      sessionId?: number | null;
      Idle?: unknown;
      Recording?: unknown;
      Processing?: unknown;
      idle?: unknown;
      recording?: unknown;
      processing?: unknown;
    };

export type DictationResultPayload =
  | DictationResult
  | {
      text?: string;
      transcript?: { text: string };
      result?: { text?: string; transcript?: { text: string } };
      duration_ms?: number | null;
      created_at?: string | null;
      sessionId?: number;
      confidence?: number | null;
    };

export const DEFAULT_DICTATION_STATUS: DictationStatus = {
  state: 'idle',
  shortcut: '⌥ Space',
  microphone: 'System default',
  model: 'Local speech model',
  accessibility_granted: false,
  retains_audio: false,
  error: null,
};
