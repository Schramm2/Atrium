# Testing Notifications on macOS

Notifications use the Tauri notification plugin. The app requests the normal macOS permission; it does not grant notification permission or user consent for tests.

## Manual check

1. Run the app with `pnpm run tauri:dev` from `frontend/`.
2. In Settings, enable a notification category and make sure notification sound and Do Not Disturb settings permit the test.
3. Start and stop a short meeting recording, or complete a background transcription.
4. Confirm that the expected local macOS notification appears.

## Troubleshooting

- Open **System Settings > Notifications**, select Notive, and allow notifications.
- Check the app's **Settings > General** notification preferences.
- Turn off a macOS Focus mode or the app's **Pause non-critical notifications** setting.
- Check the desktop-app logs for notification permission or delivery errors.

The supported notification commands are registered in `src/lib.rs`; keep this document aligned with that registration rather than calling unregistered development-only commands from the web interface.
