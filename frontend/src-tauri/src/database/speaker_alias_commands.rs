use serde::{Deserialize, Serialize};
use tauri::{AppHandle, Runtime};

use crate::{
    database::{models::SpeakerAlias, repositories::speaker_alias::SpeakerAliasesRepository},
    state::AppState,
};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SaveSpeakerAliasRequest {
    pub meeting_id: String,
    pub original_speaker_label: String,
    pub alias: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClearSpeakerAliasRequest {
    pub meeting_id: String,
    pub original_speaker_label: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClearSpeakerAliasResponse {
    pub cleared: bool,
}

#[tauri::command]
pub async fn api_list_speaker_aliases<R: Runtime>(
    _app: AppHandle<R>,
    state: tauri::State<'_, AppState>,
    meeting_id: String,
) -> Result<Vec<SpeakerAlias>, String> {
    SpeakerAliasesRepository::list(state.db_manager.pool(), &meeting_id)
        .await
        .map_err(|error| error.to_string())
}

#[tauri::command]
pub async fn api_get_speaker_alias<R: Runtime>(
    _app: AppHandle<R>,
    state: tauri::State<'_, AppState>,
    meeting_id: String,
    original_speaker_label: String,
) -> Result<Option<SpeakerAlias>, String> {
    SpeakerAliasesRepository::get(
        state.db_manager.pool(),
        &meeting_id,
        &original_speaker_label,
    )
    .await
    .map_err(|error| error.to_string())
}

#[tauri::command]
pub async fn api_save_speaker_alias<R: Runtime>(
    _app: AppHandle<R>,
    state: tauri::State<'_, AppState>,
    request: SaveSpeakerAliasRequest,
) -> Result<SpeakerAlias, String> {
    SpeakerAliasesRepository::upsert(
        state.db_manager.pool(),
        &request.meeting_id,
        &request.original_speaker_label,
        &request.alias,
    )
    .await
    .map_err(|error| error.to_string())
}

#[tauri::command]
pub async fn api_clear_speaker_alias<R: Runtime>(
    _app: AppHandle<R>,
    state: tauri::State<'_, AppState>,
    request: ClearSpeakerAliasRequest,
) -> Result<ClearSpeakerAliasResponse, String> {
    SpeakerAliasesRepository::clear(
        state.db_manager.pool(),
        &request.meeting_id,
        &request.original_speaker_label,
    )
    .await
    .map(|cleared| ClearSpeakerAliasResponse { cleared })
    .map_err(|error| error.to_string())
}
