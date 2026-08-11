#!/usr/bin/env node

import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const registryPath = resolve(root, "frontend/src-tauri/src/lib.rs");
const inventoryPath = resolve(root, "docs/TAURI_COMMAND_INVENTORY.md");
const expectedCommandCount = 189;

const dispositions = [
  {
    name: "Application identity",
    matches: (command) => command === "app_icon::set_app_icon",
    native: "Native theme and application icon services",
    status: "Verified",
  },
  {
    name: "Dictation",
    matches: (command) => command.startsWith("dictation_integration::"),
    native: "GlobalDictationShortcut, DictationView, Apple Speech, clipboard, and Accessibility paste",
    status: "Blocked",
  },
  {
    name: "Legacy transcription models",
    matches: (command) =>
      command.startsWith("whisper_engine::commands::whisper_")
      || command.startsWith("parakeet_engine::commands::")
      || command.startsWith("whisper_engine::parallel_commands::"),
    native: "Apple on-device Speech; downloaded model and worker-pool management removed",
    status: "Intentionally changed",
  },
  {
    name: "Recording recovery",
    matches: (command) => command.startsWith("audio::incremental_saver::"),
    native: "Incremental native audio files and Retranscribe recovery",
    status: "Intentionally changed",
  },
  {
    name: "Audio routing",
    matches: (command) => [
      "audio::recording_commands::poll_audio_device_events",
      "audio::recording_commands::get_reconnection_status",
      "audio::recording_commands::attempt_device_reconnect",
      "audio::recording_commands::get_active_audio_output",
    ].includes(command),
    native: "CoreAudio and ScreenCaptureKit routing without legacy Bluetooth controls",
    status: "Intentionally changed",
  },
  {
    name: "Recording and transcription",
    matches: (command) => [
      "start_recording",
      "stop_recording",
      "is_recording",
      "get_transcription_status",
      "read_audio_file",
      "save_transcript",
      "get_audio_devices",
      "trigger_microphone_permission",
      "start_recording_with_devices",
      "start_recording_with_devices_and_meeting",
      "start_audio_level_monitoring",
      "stop_audio_level_monitoring",
      "is_audio_level_monitoring",
    ].includes(command) || (
      command.startsWith("audio::recording_commands::")
      && ![
        "audio::recording_commands::poll_audio_device_events",
        "audio::recording_commands::get_reconnection_status",
        "audio::recording_commands::attempt_device_reconnect",
        "audio::recording_commands::get_active_audio_output",
      ].includes(command)
    ),
    native: "LiveMeetingCaptureService, AudioDeviceService, Apple Speech, and AppStore",
    status: "Verified",
  },
  {
    name: "Internal diagnostics",
    matches: (command) =>
      command.startsWith("console_utils::")
      || ["api::debug_backend_connection", "api::open_external_url"].includes(command),
    native: "No supported native product workflow",
    status: "Intentionally changed",
  },
  {
    name: "Legacy remote backend",
    matches: (command) => [
      "api::api_get_profile",
      "api::api_save_profile",
      "api::api_update_profile",
      "api::test_backend_connection",
    ].includes(command),
    native: "The retired profile, license, and backend-connectivity API has no native workflow",
    status: "Intentionally changed",
  },
  {
    name: "Legacy transcription configuration",
    matches: (command) => [
      "api::api_get_transcript_config",
      "api::api_save_transcript_config",
      "api::api_get_transcript_api_key",
    ].includes(command),
    native: "Apple on-device Speech replaces selectable Whisper, Parakeet, and cloud transcription providers",
    status: "Intentionally changed",
  },
  {
    name: "Optional AI providers",
    matches: (command) =>
      command.startsWith("ollama::")
      || command.startsWith("openai::")
      || command.startsWith("anthropic::")
      || command.startsWith("groq::")
      || command.startsWith("openrouter::")
      || [
        "api::api_get_model_config",
        "api::api_save_model_config",
        "api::api_get_api_key",
        "api::api_save_custom_openai_config",
        "api::api_get_custom_openai_config",
        "api::api_test_custom_openai_connection",
      ].includes(command),
    native: "AIConfiguration, provider services, Keychain secrets, and remote-evidence confirmation",
    status: "Implemented",
  },
  {
    name: "Ask",
    matches: (command) => command.startsWith("ask::"),
    native: "Bounded local FTS5 retrieval, evidence-bound answers, cancellation, and citation navigation",
    status: "Verified",
  },
  {
    name: "Speaker aliases",
    matches: (command) => command.startsWith("database::speaker_alias_commands::"),
    native: "Compatible meeting-scoped alias persistence",
    status: "Verified",
  },
  {
    name: "Meeting persistence",
    matches: (command) => [
      "api::api_get_meetings",
      "api::api_search_transcripts",
      "api::api_delete_meeting",
      "api::api_get_meeting",
      "api::api_get_meeting_metadata",
      "api::api_get_meeting_transcripts",
      "api::api_save_meeting_title",
      "api::api_save_transcript",
      "api::open_meeting_folder",
    ].includes(command),
    native: "Compatible SQLite storage, meeting detail workflows, and local folder access",
    status: "Verified",
  },
  {
    name: "Summaries",
    matches: (command) =>
      command.startsWith("summary::commands::")
      || command.startsWith("summary::template_commands::"),
    native: "Local intelligence service, templates, output languages, metadata, and cancellation",
    status: "Verified",
  },
  {
    name: "Legacy summary models",
    matches: (command) => command.startsWith("summary::summary_engine::commands::"),
    native: "Apple Intelligence when available with deterministic local fallback",
    status: "Intentionally changed",
  },
  {
    name: "Recording preferences",
    matches: (command) => [
      "audio::recording_preferences::get_recording_preferences",
      "audio::recording_preferences::set_recording_preferences",
      "audio::recording_preferences::get_default_recordings_folder_path",
      "audio::recording_preferences::open_recordings_folder",
      "audio::recording_preferences::select_recording_folder",
    ].includes(command),
    native: "Native recording folder, audio retention, microphone, and system-audio preferences",
    status: "Verified",
  },
  {
    name: "Legacy audio backends",
    matches: (command) => [
      "audio::recording_preferences::get_available_audio_backends",
      "audio::recording_preferences::get_current_audio_backend",
      "audio::recording_preferences::set_audio_backend",
      "audio::recording_preferences::get_audio_backend_info",
    ].includes(command),
    native: "CoreAudio and ScreenCaptureKit replace selectable legacy backends",
    status: "Intentionally changed",
  },
  {
    name: "Language preference",
    matches: (command) => command === "set_language_preference",
    native: "Native transcription and summary language preferences",
    status: "Verified",
  },
  {
    name: "Notifications",
    matches: (command) => [
      "notifications::commands::get_notification_settings",
      "notifications::commands::set_notification_settings",
      "notifications::commands::request_notification_permission",
      "notifications::commands::show_notification",
      "notifications::commands::show_test_notification",
    ].includes(command),
    native: "UserNotifications preferences, foreground presentation, permissions, and test delivery",
    status: "Verified",
  },
  {
    name: "Legacy notification controls",
    matches: (command) => [
      "notifications::commands::is_dnd_active",
      "notifications::commands::get_system_dnd_status",
      "notifications::commands::set_manual_dnd",
      "notifications::commands::set_notification_consent",
      "notifications::commands::clear_notifications",
      "notifications::commands::is_notification_system_ready",
      "notifications::commands::initialize_notification_manager_manual",
      "notifications::commands::test_notification_with_auto_consent",
      "notifications::commands::get_notification_stats",
    ].includes(command),
    native: "Native pause and system notification controls replace manual DND, consent, readiness, and statistics commands",
    status: "Intentionally changed",
  },
  {
    name: "System audio",
    matches: (command) =>
      command.startsWith("audio::system_audio_commands::")
      || command.startsWith("audio::permissions::"),
    native: "ScreenCaptureKit capture, monitoring state, and native Screen Recording permission controls",
    status: "Verified",
  },
  {
    name: "Database startup",
    matches: (command) => [
      "database::commands::check_first_launch",
      "database::commands::initialize_fresh_database",
    ].includes(command),
    native: "Compatible SQLite discovery, schema initialization, and native onboarding startup",
    status: "Verified",
  },
  {
    name: "Legacy database import",
    matches: (command) => [
      "database::commands::select_legacy_database_path",
      "database::commands::detect_legacy_database",
      "database::commands::check_default_legacy_database",
      "database::commands::check_homebrew_database",
      "database::commands::import_and_initialize_database",
    ].includes(command),
    native: "The supported com.ubundi.meet SQLite database opens in place; archived Python and Homebrew imports removed",
    status: "Intentionally changed",
  },
  {
    name: "Local data folders",
    matches: (command) => [
      "database::commands::get_database_directory",
      "database::commands::open_database_folder",
    ].includes(command),
    native: "Native Settings exposes the compatible application-support folder",
    status: "Verified",
  },
  {
    name: "Legacy model folder",
    matches: (command) => command === "whisper_engine::commands::open_models_folder",
    native: "No downloaded transcription-model folder in the Apple Speech architecture",
    status: "Intentionally changed",
  },
  {
    name: "Onboarding",
    matches: (command) => command.startsWith("onboarding::"),
    native: "Native three-step onboarding and AppStorage completion state",
    status: "Verified",
  },
  {
    name: "System Settings",
    matches: (command) => command === "utils::open_system_settings",
    native: "Direct native privacy and notification settings links",
    status: "Verified",
  },
  {
    name: "Retranscription",
    matches: (command) => command.startsWith("audio::retranscription::"),
    native: "Saved-audio retranscription, replacement, and cancellation",
    status: "Verified",
  },
  {
    name: "Audio import",
    matches: (command) => command.startsWith("audio::import::"),
    native: "Native picker and drop import with validation, progress, cancellation, and rollback",
    status: "Verified",
  },
];

function registeredCommands(source) {
  const startMarker = ".invoke_handler(tauri::generate_handler![";
  const start = source.indexOf(startMarker);
  if (start === -1) throw new Error(`Could not find ${startMarker}`);
  const bodyStart = start + startMarker.length;
  const endMarker = "\n        ])\n        .build";
  const end = source.indexOf(endMarker, bodyStart);
  if (end === -1) throw new Error("Could not find the end of the Tauri command registry");

  return source
    .slice(bodyStart, end)
    .replaceAll(/\/\*[\s\S]*?\*\//g, "")
    .split("\n")
    .map((line) => line.replace(/\/\/.*$/, "").trim())
    .filter((line) => line && !line.startsWith("#["))
    .join("\n")
    .split(",")
    .map((command) => command.trim())
    .filter(Boolean);
}

function dispositionFor(command) {
  const matches = dispositions.filter((disposition) => disposition.matches(command));
  if (matches.length !== 1) {
    throw new Error(
      `${command} matched ${matches.length} dispositions: ${matches.map((match) => match.name).join(", ")}`
    );
  }
  return matches[0];
}

function render(commands) {
  const rows = commands.map((command) => {
    const disposition = dispositionFor(command);
    return `| \`${command}\` | ${disposition.name} | ${disposition.native} | ${disposition.status} |`;
  });
  const statusCounts = commands.reduce((counts, command) => {
    const status = dispositionFor(command).status;
    counts.set(status, (counts.get(status) ?? 0) + 1);
    return counts;
  }, new Map());
  const statusSummary = ["Verified", "Implemented", "Intentionally changed", "Blocked"]
    .map((status) => `${statusCounts.get(status) ?? 0} ${status.toLowerCase()}`)
    .join(", ");

  return `${`# Registered Tauri command migration inventory

This generated inventory maps every active command in the supported Tauri \`tauri::generate_handler!\` registry to its native Swift disposition. Commented commands and unregistered backup sources are excluded. Run \`node scripts/check-swift-migration-inventory.mjs --check\` after a registry or migration change.

Registered commands: **${commands.length}**

Disposition summary: **${statusSummary}**

| Registered Rust command | Capability | Native disposition | Status |
|---|---|---|---|
${rows.join("\n")}
`}`;
}

const commands = registeredCommands(readFileSync(registryPath, "utf8"));
if (commands.length !== expectedCommandCount) {
  throw new Error(`Expected ${expectedCommandCount} registered commands, found ${commands.length}`);
}
if (new Set(commands).size !== commands.length) {
  throw new Error("The Tauri command registry contains duplicate entries");
}

const output = render(commands);
if (process.argv.includes("--write")) {
  writeFileSync(inventoryPath, output);
  console.log(`Wrote ${commands.length} commands to ${inventoryPath}`);
} else if (process.argv.includes("--check")) {
  const current = readFileSync(inventoryPath, "utf8");
  if (current !== output) {
    throw new Error(
      "The migration inventory is stale. Run node scripts/check-swift-migration-inventory.mjs --write"
    );
  }
  console.log(`Migration inventory is current: ${commands.length} registered commands`);
} else {
  process.stdout.write(output);
}
