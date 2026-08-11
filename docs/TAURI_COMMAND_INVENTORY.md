# Registered Tauri command migration inventory

This generated inventory maps every active command in the supported Tauri `tauri::generate_handler!` registry to its native Swift disposition. Commented commands and unregistered backup sources are excluded. Run `node scripts/check-swift-migration-inventory.mjs --check` after a registry or migration change.

Registered commands: **189**

Disposition summary: **86 verified, 14 implemented, 83 intentionally changed, 6 blocked**

| Registered Rust command | Capability | Native disposition | Status |
|---|---|---|---|
| `app_icon::set_app_icon` | Application identity | Native theme and application icon services | Verified |
| `start_recording` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `stop_recording` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `is_recording` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `dictation_integration::start_dictation` | Dictation | GlobalDictationShortcut, DictationView, Apple Speech, clipboard, and Accessibility paste | Blocked |
| `dictation_integration::stop_dictation` | Dictation | GlobalDictationShortcut, DictationView, Apple Speech, clipboard, and Accessibility paste | Blocked |
| `dictation_integration::cancel_dictation` | Dictation | GlobalDictationShortcut, DictationView, Apple Speech, clipboard, and Accessibility paste | Blocked |
| `dictation_integration::get_dictation_status` | Dictation | GlobalDictationShortcut, DictationView, Apple Speech, clipboard, and Accessibility paste | Blocked |
| `dictation_integration::get_dictation_preferences` | Dictation | GlobalDictationShortcut, DictationView, Apple Speech, clipboard, and Accessibility paste | Blocked |
| `dictation_integration::set_dictation_preferences` | Dictation | GlobalDictationShortcut, DictationView, Apple Speech, clipboard, and Accessibility paste | Blocked |
| `get_transcription_status` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `read_audio_file` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `save_transcript` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `whisper_engine::commands::whisper_init` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_get_available_models` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_load_model` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_get_current_model` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_is_model_loaded` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_has_available_models` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_validate_model_ready` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_transcribe_audio` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_get_models_directory` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_download_model` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_cancel_download` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::commands::whisper_delete_corrupted_model` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_init` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_get_available_models` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_load_model` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_get_current_model` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_is_model_loaded` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_has_available_models` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_validate_model_ready` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_transcribe_audio` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_get_models_directory` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_download_model` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_retry_download` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_cancel_download` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::parakeet_delete_corrupted_model` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `parakeet_engine::commands::open_parakeet_models_folder` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::initialize_parallel_processor` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::start_parallel_processing` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::pause_parallel_processing` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::resume_parallel_processing` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::stop_parallel_processing` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::get_parallel_processing_status` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::get_system_resources` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::check_resource_constraints` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::calculate_optimal_workers` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::prepare_audio_chunks` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `whisper_engine::parallel_commands::test_parallel_processing_setup` | Legacy transcription models | Apple on-device Speech; downloaded model and worker-pool management removed | Intentionally changed |
| `get_audio_devices` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `trigger_microphone_permission` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `start_recording_with_devices` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `start_recording_with_devices_and_meeting` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `start_audio_level_monitoring` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `stop_audio_level_monitoring` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `is_audio_level_monitoring` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `audio::recording_commands::pause_recording` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `audio::recording_commands::resume_recording` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `audio::recording_commands::is_recording_paused` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `audio::recording_commands::get_recording_state` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `audio::recording_commands::get_meeting_folder_path` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `audio::recording_commands::get_transcript_history` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `audio::recording_commands::get_recording_meeting_name` | Recording and transcription | LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore | Verified |
| `audio::recording_commands::poll_audio_device_events` | Audio routing | CoreAudio and ScreenCaptureKit routing without legacy Bluetooth controls | Intentionally changed |
| `audio::recording_commands::get_reconnection_status` | Audio routing | CoreAudio and ScreenCaptureKit routing without legacy Bluetooth controls | Intentionally changed |
| `audio::recording_commands::attempt_device_reconnect` | Audio routing | CoreAudio and ScreenCaptureKit routing without legacy Bluetooth controls | Intentionally changed |
| `audio::recording_commands::get_active_audio_output` | Audio routing | CoreAudio and ScreenCaptureKit routing without legacy Bluetooth controls | Intentionally changed |
| `audio::incremental_saver::recover_audio_from_checkpoints` | Recording recovery | Incremental native audio files and Retranscribe recovery | Intentionally changed |
| `audio::incremental_saver::cleanup_checkpoints` | Recording recovery | Incremental native audio files and Retranscribe recovery | Intentionally changed |
| `audio::incremental_saver::has_audio_checkpoints` | Recording recovery | Incremental native audio files and Retranscribe recovery | Intentionally changed |
| `console_utils::show_console` | Internal diagnostics | No supported native product workflow | Intentionally changed |
| `console_utils::hide_console` | Internal diagnostics | No supported native product workflow | Intentionally changed |
| `console_utils::toggle_console` | Internal diagnostics | No supported native product workflow | Intentionally changed |
| `ollama::get_ollama_models` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `ollama::pull_ollama_model` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `ollama::delete_ollama_model` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `ollama::get_ollama_model_context` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `openai::openai::get_openai_models` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `anthropic::anthropic::get_anthropic_models` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `groq::groq::get_groq_models` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `api::api_get_meetings` | Meeting persistence | Compatible SQLite storage, meeting detail workflows, and local folder access | Verified |
| `api::api_search_transcripts` | Meeting persistence | Compatible SQLite storage, meeting detail workflows, and local folder access | Verified |
| `ask::api_retrieve_ask_evidence` | Ask | Bounded local FTS5 retrieval, evidence-bound answers, cancellation, and citation navigation | Verified |
| `ask::api_generate_ask_answer` | Ask | Bounded local FTS5 retrieval, evidence-bound answers, cancellation, and citation navigation | Verified |
| `ask::api_cancel_ask` | Ask | Bounded local FTS5 retrieval, evidence-bound answers, cancellation, and citation navigation | Verified |
| `api::api_get_profile` | Legacy remote backend | The retired profile, license, and backend-connectivity API has no native workflow | Intentionally changed |
| `api::api_save_profile` | Legacy remote backend | The retired profile, license, and backend-connectivity API has no native workflow | Intentionally changed |
| `api::api_update_profile` | Legacy remote backend | The retired profile, license, and backend-connectivity API has no native workflow | Intentionally changed |
| `api::api_get_model_config` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `api::api_save_model_config` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `api::api_get_api_key` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `api::api_get_transcript_config` | Legacy transcription configuration | Apple on-device Speech replaces selectable Whisper, Parakeet, and cloud transcription providers | Intentionally changed |
| `api::api_save_transcript_config` | Legacy transcription configuration | Apple on-device Speech replaces selectable Whisper, Parakeet, and cloud transcription providers | Intentionally changed |
| `api::api_get_transcript_api_key` | Legacy transcription configuration | Apple on-device Speech replaces selectable Whisper, Parakeet, and cloud transcription providers | Intentionally changed |
| `api::api_delete_meeting` | Meeting persistence | Compatible SQLite storage, meeting detail workflows, and local folder access | Verified |
| `api::api_get_meeting` | Meeting persistence | Compatible SQLite storage, meeting detail workflows, and local folder access | Verified |
| `api::api_get_meeting_metadata` | Meeting persistence | Compatible SQLite storage, meeting detail workflows, and local folder access | Verified |
| `api::api_get_meeting_transcripts` | Meeting persistence | Compatible SQLite storage, meeting detail workflows, and local folder access | Verified |
| `database::speaker_alias_commands::api_list_speaker_aliases` | Speaker aliases | Compatible meeting-scoped alias persistence | Verified |
| `database::speaker_alias_commands::api_get_speaker_alias` | Speaker aliases | Compatible meeting-scoped alias persistence | Verified |
| `database::speaker_alias_commands::api_save_speaker_alias` | Speaker aliases | Compatible meeting-scoped alias persistence | Verified |
| `database::speaker_alias_commands::api_clear_speaker_alias` | Speaker aliases | Compatible meeting-scoped alias persistence | Verified |
| `api::api_save_meeting_title` | Meeting persistence | Compatible SQLite storage, meeting detail workflows, and local folder access | Verified |
| `api::api_save_transcript` | Meeting persistence | Compatible SQLite storage, meeting detail workflows, and local folder access | Verified |
| `api::open_meeting_folder` | Meeting persistence | Compatible SQLite storage, meeting detail workflows, and local folder access | Verified |
| `api::test_backend_connection` | Legacy remote backend | The retired profile, license, and backend-connectivity API has no native workflow | Intentionally changed |
| `api::debug_backend_connection` | Internal diagnostics | No supported native product workflow | Intentionally changed |
| `api::open_external_url` | Internal diagnostics | No supported native product workflow | Intentionally changed |
| `api::api_save_custom_openai_config` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `api::api_get_custom_openai_config` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `api::api_test_custom_openai_connection` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `summary::commands::api_process_transcript` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::commands::api_get_summary` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::commands::api_save_meeting_summary` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::commands::api_get_meeting_summary_language` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::commands::api_save_meeting_summary_language` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::commands::api_get_meeting_detected_summary_language` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::commands::api_save_meeting_detected_summary_language` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::commands::api_detect_transcript_summary_language` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::commands::api_cancel_summary` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::template_commands::api_list_templates` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::template_commands::api_get_template_details` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::template_commands::api_validate_template` | Summaries | Local intelligence service, templates, output languages, metadata, and cancellation | Verified |
| `summary::summary_engine::commands::builtin_ai_list_models` | Legacy summary models | Apple Intelligence when available with deterministic local fallback | Intentionally changed |
| `summary::summary_engine::commands::builtin_ai_get_model_info` | Legacy summary models | Apple Intelligence when available with deterministic local fallback | Intentionally changed |
| `summary::summary_engine::commands::builtin_ai_download_model` | Legacy summary models | Apple Intelligence when available with deterministic local fallback | Intentionally changed |
| `summary::summary_engine::commands::builtin_ai_cancel_download` | Legacy summary models | Apple Intelligence when available with deterministic local fallback | Intentionally changed |
| `summary::summary_engine::commands::builtin_ai_delete_model` | Legacy summary models | Apple Intelligence when available with deterministic local fallback | Intentionally changed |
| `summary::summary_engine::commands::builtin_ai_is_model_ready` | Legacy summary models | Apple Intelligence when available with deterministic local fallback | Intentionally changed |
| `summary::summary_engine::commands::builtin_ai_get_available_summary_model` | Legacy summary models | Apple Intelligence when available with deterministic local fallback | Intentionally changed |
| `summary::summary_engine::commands::builtin_ai_get_recommended_model` | Legacy summary models | Apple Intelligence when available with deterministic local fallback | Intentionally changed |
| `openrouter::get_openrouter_models` | Optional AI providers | AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation | Implemented |
| `audio::recording_preferences::get_recording_preferences` | Recording preferences | Native recording folder, audio retention, microphone, and system-audio preferences | Verified |
| `audio::recording_preferences::set_recording_preferences` | Recording preferences | Native recording folder, audio retention, microphone, and system-audio preferences | Verified |
| `audio::recording_preferences::get_default_recordings_folder_path` | Recording preferences | Native recording folder, audio retention, microphone, and system-audio preferences | Verified |
| `audio::recording_preferences::open_recordings_folder` | Recording preferences | Native recording folder, audio retention, microphone, and system-audio preferences | Verified |
| `audio::recording_preferences::select_recording_folder` | Recording preferences | Native recording folder, audio retention, microphone, and system-audio preferences | Verified |
| `audio::recording_preferences::get_available_audio_backends` | Legacy audio backends | CoreAudio and ScreenCaptureKit replace selectable legacy backends | Intentionally changed |
| `audio::recording_preferences::get_current_audio_backend` | Legacy audio backends | CoreAudio and ScreenCaptureKit replace selectable legacy backends | Intentionally changed |
| `audio::recording_preferences::set_audio_backend` | Legacy audio backends | CoreAudio and ScreenCaptureKit replace selectable legacy backends | Intentionally changed |
| `audio::recording_preferences::get_audio_backend_info` | Legacy audio backends | CoreAudio and ScreenCaptureKit replace selectable legacy backends | Intentionally changed |
| `set_language_preference` | Language preference | Native transcription and summary language preferences | Verified |
| `notifications::commands::get_notification_settings` | Notifications | UserNotifications preferences, foreground presentation, permissions, and test delivery | Verified |
| `notifications::commands::set_notification_settings` | Notifications | UserNotifications preferences, foreground presentation, permissions, and test delivery | Verified |
| `notifications::commands::request_notification_permission` | Notifications | UserNotifications preferences, foreground presentation, permissions, and test delivery | Verified |
| `notifications::commands::show_notification` | Notifications | UserNotifications preferences, foreground presentation, permissions, and test delivery | Verified |
| `notifications::commands::show_test_notification` | Notifications | UserNotifications preferences, foreground presentation, permissions, and test delivery | Verified |
| `notifications::commands::is_dnd_active` | Legacy notification controls | Native pause and system notification controls replace manual DND, consent, readiness, and statistics commands | Intentionally changed |
| `notifications::commands::get_system_dnd_status` | Legacy notification controls | Native pause and system notification controls replace manual DND, consent, readiness, and statistics commands | Intentionally changed |
| `notifications::commands::set_manual_dnd` | Legacy notification controls | Native pause and system notification controls replace manual DND, consent, readiness, and statistics commands | Intentionally changed |
| `notifications::commands::set_notification_consent` | Legacy notification controls | Native pause and system notification controls replace manual DND, consent, readiness, and statistics commands | Intentionally changed |
| `notifications::commands::clear_notifications` | Legacy notification controls | Native pause and system notification controls replace manual DND, consent, readiness, and statistics commands | Intentionally changed |
| `notifications::commands::is_notification_system_ready` | Legacy notification controls | Native pause and system notification controls replace manual DND, consent, readiness, and statistics commands | Intentionally changed |
| `notifications::commands::initialize_notification_manager_manual` | Legacy notification controls | Native pause and system notification controls replace manual DND, consent, readiness, and statistics commands | Intentionally changed |
| `notifications::commands::test_notification_with_auto_consent` | Legacy notification controls | Native pause and system notification controls replace manual DND, consent, readiness, and statistics commands | Intentionally changed |
| `notifications::commands::get_notification_stats` | Legacy notification controls | Native pause and system notification controls replace manual DND, consent, readiness, and statistics commands | Intentionally changed |
| `audio::system_audio_commands::start_system_audio_capture_command` | System audio | ScreenCaptureKit capture, monitoring state, and native Screen Recording permission controls | Verified |
| `audio::system_audio_commands::list_system_audio_devices_command` | System audio | ScreenCaptureKit capture, monitoring state, and native Screen Recording permission controls | Verified |
| `audio::system_audio_commands::check_system_audio_permissions_command` | System audio | ScreenCaptureKit capture, monitoring state, and native Screen Recording permission controls | Verified |
| `audio::system_audio_commands::start_system_audio_monitoring` | System audio | ScreenCaptureKit capture, monitoring state, and native Screen Recording permission controls | Verified |
| `audio::system_audio_commands::stop_system_audio_monitoring` | System audio | ScreenCaptureKit capture, monitoring state, and native Screen Recording permission controls | Verified |
| `audio::system_audio_commands::get_system_audio_monitoring_status` | System audio | ScreenCaptureKit capture, monitoring state, and native Screen Recording permission controls | Verified |
| `audio::permissions::check_screen_recording_permission_command` | System audio | ScreenCaptureKit capture, monitoring state, and native Screen Recording permission controls | Verified |
| `audio::permissions::request_screen_recording_permission_command` | System audio | ScreenCaptureKit capture, monitoring state, and native Screen Recording permission controls | Verified |
| `audio::permissions::trigger_system_audio_permission_command` | System audio | ScreenCaptureKit capture, monitoring state, and native Screen Recording permission controls | Verified |
| `database::commands::check_first_launch` | Database startup | Compatible SQLite discovery, schema initialization, and native onboarding startup | Verified |
| `database::commands::select_legacy_database_path` | Legacy database import | The supported com.ubundi.meet SQLite database opens in place; archived Python and Homebrew imports removed | Intentionally changed |
| `database::commands::detect_legacy_database` | Legacy database import | The supported com.ubundi.meet SQLite database opens in place; archived Python and Homebrew imports removed | Intentionally changed |
| `database::commands::check_default_legacy_database` | Legacy database import | The supported com.ubundi.meet SQLite database opens in place; archived Python and Homebrew imports removed | Intentionally changed |
| `database::commands::check_homebrew_database` | Legacy database import | The supported com.ubundi.meet SQLite database opens in place; archived Python and Homebrew imports removed | Intentionally changed |
| `database::commands::import_and_initialize_database` | Legacy database import | The supported com.ubundi.meet SQLite database opens in place; archived Python and Homebrew imports removed | Intentionally changed |
| `database::commands::initialize_fresh_database` | Database startup | Compatible SQLite discovery, schema initialization, and native onboarding startup | Verified |
| `database::commands::get_database_directory` | Local data folders | Native Settings exposes the compatible application-support folder | Verified |
| `database::commands::open_database_folder` | Local data folders | Native Settings exposes the compatible application-support folder | Verified |
| `whisper_engine::commands::open_models_folder` | Legacy model folder | No downloaded transcription-model folder in the Apple Speech architecture | Intentionally changed |
| `onboarding::get_onboarding_status` | Onboarding | Native three-step onboarding and AppStorage completion state | Verified |
| `onboarding::save_onboarding_status_cmd` | Onboarding | Native three-step onboarding and AppStorage completion state | Verified |
| `onboarding::reset_onboarding_status_cmd` | Onboarding | Native three-step onboarding and AppStorage completion state | Verified |
| `onboarding::complete_onboarding` | Onboarding | Native three-step onboarding and AppStorage completion state | Verified |
| `utils::open_system_settings` | System Settings | Direct native privacy and notification settings links | Verified |
| `audio::retranscription::start_retranscription_command` | Retranscription | Saved-audio retranscription, replacement, and cancellation | Verified |
| `audio::retranscription::cancel_retranscription_command` | Retranscription | Saved-audio retranscription, replacement, and cancellation | Verified |
| `audio::retranscription::is_retranscription_in_progress_command` | Retranscription | Saved-audio retranscription, replacement, and cancellation | Verified |
| `audio::import::select_and_validate_audio_command` | Audio import | Native picker and drop import with validation, progress, cancellation, and rollback | Verified |
| `audio::import::validate_audio_file_command` | Audio import | Native picker and drop import with validation, progress, cancellation, and rollback | Verified |
| `audio::import::start_import_audio_command` | Audio import | Native picker and drop import with validation, progress, cancellation, and rollback | Verified |
| `audio::import::cancel_import_command` | Audio import | Native picker and drop import with validation, progress, cancellation, and rollback | Verified |
| `audio::import::is_import_in_progress_command` | Audio import | Native picker and drop import with validation, progress, cancellation, and rollback | Verified |
