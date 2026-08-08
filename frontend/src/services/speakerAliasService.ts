import { invoke } from '@tauri-apps/api/core';
import { SpeakerAlias } from '@/types';

export interface SaveSpeakerAliasRequest {
  meeting_id: string;
  original_speaker_label: string;
  alias: string;
}

export interface ClearSpeakerAliasRequest {
  meeting_id: string;
  original_speaker_label: string;
}

export async function listSpeakerAliases(meetingId: string): Promise<SpeakerAlias[]> {
  return invoke<SpeakerAlias[]>('api_list_speaker_aliases', { meetingId });
}

export async function saveSpeakerAlias(
  request: SaveSpeakerAliasRequest,
): Promise<SpeakerAlias> {
  return invoke<SpeakerAlias>('api_save_speaker_alias', { request });
}

export async function clearSpeakerAlias(
  request: ClearSpeakerAliasRequest,
): Promise<boolean> {
  const response = await invoke<{ cleared: boolean }>('api_clear_speaker_alias', { request });
  return response.cleared;
}
