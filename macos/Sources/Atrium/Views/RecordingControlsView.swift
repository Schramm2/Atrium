import AppKit
import AtriumCore
import SwiftUI

struct RecordingControlsView: View {
    @Bindable var store: AppStore

    @ViewBuilder
    var body: some View {
        switch store.recordingState {
        case .idle, .failed:
            if store.recordingBlockedBySystemAudioAccess {
                HStack(spacing: 8) {
                    Button("Open Screen Recording settings", systemImage: "gearshape") {
                        openScreenRecordingSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    Button("Record microphone only", systemImage: "mic.fill") {
                        startMicrophoneOnlyRecording()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                Button("Start Recording", systemImage: "mic.fill", action: startRecording)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        case .recording:
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button("Pause", systemImage: "pause.fill", action: store.pauseRecording)
                    Button("Stop", systemImage: "stop.fill", action: stopRecording)
                        .buttonStyle(.borderedProminent)
                }
                RecordingMeterView(elapsed: store.recordingElapsed, power: store.recordingPower)
            }
        case .paused:
            HStack {
                Button("Resume", systemImage: "play.fill", action: store.resumeRecording)
                Button("Stop", systemImage: "stop.fill", action: stopRecording)
                    .buttonStyle(.borderedProminent)
            }
        case .transcribing:
            if store.isImportingAudio {
                HStack(spacing: 12) {
                    ProgressView("Importing audio")
                    Button("Cancel Import", role: .cancel, action: store.cancelImport)
                }
            } else {
                ProgressView("Transcribing")
            }
        }
    }

    private func startRecording() {
        store.resetRecordingError()
        Task { await store.startRecording() }
    }

    private func startMicrophoneOnlyRecording() {
        store.resetRecordingError()
        store.clearError()
        Task { await store.startMicrophoneOnlyRecording() }
    }

    private func openScreenRecordingSettings() {
        guard let url = URL(string: ScreenRecordingAuthorization.settingsURLString) else { return }
        NSWorkspace.shared.open(url)
    }

    private func stopRecording() {
        Task { await store.stopRecording() }
    }
}
