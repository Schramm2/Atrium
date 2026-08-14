import AtriumCore
import SwiftUI
import UniformTypeIdentifiers

/// Capture controls shown beside the Home heading.
struct HomeCaptureView: View {
    @Bindable var store: AppStore
    @State private var showsAudioImporter = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            BrandStatusLabel(
                title: "On-device by default",
                systemImage: "lock.fill",
                kind: .local
            )

            Button("Import Audio", systemImage: "square.and.arrow.down") {
                store.resetRecordingError()
                showsAudioImporter = true
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(store.isImportingAudio || !canImportAudio)

            RecordingControlsView(store: store)
        }
        .fixedSize(horizontal: false, vertical: true)
        .fileImporter(
            isPresented: $showsAudioImporter,
            allowedContentTypes: [.audio, .mpeg4Movie],
            allowsMultipleSelection: false,
            onCompletion: importAudio
        )
    }

    private var canImportAudio: Bool {
        switch store.recordingState {
        case .idle, .failed:
            true
        case .recording, .paused, .transcribing:
            false
        }
    }

    private func importAudio(_ result: Result<[URL], any Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            Task {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                await store.importAudio(from: url)
            }
        case let .failure(error):
            guard (error as? CocoaError)?.code != .userCancelled else { return }
            DiagnosticLogger.failure(operation: "audio_file_select", error: error)
            store.errorMessage = "Atrium could not open the selected audio. Choose another file and try again."
        }
    }
}
