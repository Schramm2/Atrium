import NotiveCore
import SwiftUI

struct RecordingControlsView: View {
    @Bindable var store: AppStore

    @ViewBuilder
    var body: some View {
        switch store.recordingState {
        case .idle, .failed:
            Button("Start Recording", systemImage: "mic.fill", action: startRecording)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        case .recording:
            VStack(alignment: .leading, spacing: 10) {
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

    private func stopRecording() {
        Task { await store.stopRecording() }
    }
}
