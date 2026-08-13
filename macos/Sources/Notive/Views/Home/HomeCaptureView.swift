import NotiveCore
import SwiftUI
import UniformTypeIdentifiers

struct HomeCaptureView: View {
    @Bindable var store: AppStore
    @State private var showsAudioImporter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Capture")
                    .font(.title2.weight(.semibold))
                Spacer()
                BrandStatusLabel(
                    title: "Processed on this Mac",
                    systemImage: "lock.fill",
                    kind: .local
                )
            }

            BrandPanel {
                HStack(spacing: 20) {
                    RecordingControlsView(store: store)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    Button("Import Audio", systemImage: "square.and.arrow.down") {
                        store.resetRecordingError()
                        showsAudioImporter = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(store.isImportingAudio || !canImportAudio)
                }
            }
        }
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
            store.errorMessage = "Notive could not open the selected audio. Choose another file and try again."
        }
    }
}
