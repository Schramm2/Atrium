import NotiveCore
import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Bindable var store: AppStore
    let theme: BrandTheme
    @State private var showsAudioImporter = false
    @State private var meetingToDelete: Meeting?
    @AppStorage("notive.appearance") private var appearance = "system"

    var body: some View {
        VStack(spacing: 0) {
            List(selection: Binding(
                get: { store.selection },
                set: { store.select($0) }
            )) {
                Section {
                    Label("Home", systemImage: "house")
                        .tag(WorkspaceSelection.home)
                    Label("Ask Notive", systemImage: "bubble.left.and.text.bubble.right")
                        .tag(WorkspaceSelection.ask)
                    Label("Dictation", systemImage: "waveform")
                        .tag(WorkspaceSelection.dictation)
                    Label("Meeting Notes", systemImage: "note.text")
                        .tag(WorkspaceSelection.notes)
                }

                Section("Meetings") {
                    ForEach(store.meetings) { meeting in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meeting.title)
                                .lineLimit(1)
                            Text(meeting.createdAt, format: .dateTime.month(.abbreviated).day())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(WorkspaceSelection.meeting(meeting.id))
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                meetingToDelete = meeting
                            }
                        }
                        .accessibilityAction(named: "Delete") {
                            meetingToDelete = meeting
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $store.searchText, prompt: "Search meeting content")
            .onSubmit(of: .search) { store.search() }
            .onChange(of: store.searchText) { _, value in
                if value.isEmpty { store.reloadMeetings() }
            }

            Divider()

            VStack(spacing: 8) {
                switch store.recordingState {
                case .idle, .failed:
                    Button {
                        store.resetRecordingError()
                        Task { await store.startRecording() }
                    } label: {
                        Label("Start Recording", systemImage: "mic.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                case .recording:
                    HStack {
                        Button("Pause", systemImage: "pause.fill") {
                            store.pauseRecording()
                        }
                        Button("Stop", systemImage: "stop.fill") {
                            Task { await store.stopRecording() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    RecordingMeter(
                        elapsed: store.recordingElapsed,
                        power: store.recordingPower
                    )
                case .paused:
                    HStack {
                        Button("Resume", systemImage: "play.fill") {
                            store.resumeRecording()
                        }
                        Button("Stop", systemImage: "stop.fill") {
                            Task { await store.stopRecording() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                case .transcribing:
                    if store.isImportingAudio {
                        VStack(spacing: 8) {
                            ProgressView("Importing audio")
                                .frame(maxWidth: .infinity)
                            Button("Cancel Import", role: .cancel) {
                                store.cancelImport()
                            }
                        }
                    } else {
                        ProgressView("Transcribing")
                            .frame(maxWidth: .infinity)
                    }
                }

                Button {
                    showsAudioImporter = true
                } label: {
                    Label("Import Audio", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(store.isImportingAudio)

                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                HStack {
                    Picker("Theme", selection: Binding(
                        get: { theme.rawValue },
                        set: { UserDefaults.standard.set($0, forKey: "ubundi-meet-brand-theme") }
                    )) {
                        ForEach(BrandTheme.allCases) { theme in
                            Text(theme.title).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    Button("Appearance", systemImage: appearanceIcon) {
                        appearance = appearance == "dark" ? "light" : "dark"
                    }
                    .labelStyle(.iconOnly)
                }

                Text("Notive · v\(AppVersion.current)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
        .fileImporter(
            isPresented: $showsAudioImporter,
            allowedContentTypes: [.audio, .mpeg4Movie],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            Task {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                await store.importAudio(from: url)
            }
        }
        .confirmationDialog(
            "Delete \(meetingToDelete?.title ?? "this meeting")?",
            isPresented: Binding(
                get: { meetingToDelete != nil },
                set: { if !$0 { meetingToDelete = nil } }
            )
        ) {
            Button("Delete meeting", role: .destructive) {
                if let meetingToDelete {
                    store.deleteMeeting(id: meetingToDelete.id)
                }
                meetingToDelete = nil
            }
            Button("Cancel", role: .cancel) { meetingToDelete = nil }
        } message: {
            Text("This removes the meeting, transcript, summary, notes, and speaker aliases from the local database. Recording files remain on this Mac.")
        }
    }

    private var appearanceIcon: String {
        appearance == "dark" ? "moon.fill" : appearance == "light" ? "sun.max.fill" : "circle.lefthalf.filled"
    }
}

private struct RecordingMeter: View {
    let elapsed: TimeInterval
    let power: Float

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.red)
                .frame(width: 7, height: 7)
            Text(Self.time(elapsed))
                .font(.caption.monospacedDigit())
            ProgressView(value: normalizedPower)
                .progressViewStyle(.linear)
        }
    }

    private var normalizedPower: Double {
        min(1, max(0, Double((power + 60) / 60)))
    }

    private static func time(_ value: TimeInterval) -> String {
        let seconds = Int(value)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
