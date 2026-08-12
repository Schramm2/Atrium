import NotiveCore
import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Bindable var store: AppStore
    let theme: BrandTheme
    @Environment(CompanyHubStore.self) private var hub
    @State private var showsAudioImporter = false
    @State private var meetingToDelete: Meeting?
    @AppStorage("notive.appearance") private var appearance = "system"

    var body: some View {
        VStack(spacing: 0) {
            identity
            Divider()
            navigation
            Divider()
            captureControls
        }
        .fileImporter(
            isPresented: $showsAudioImporter,
            allowedContentTypes: [.audio, .mpeg4Movie],
            allowsMultipleSelection: false,
            onCompletion: importAudio
        )
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
            Text("This removes the meeting, transcript, summary, notes, and speaker names from Notive. Recording files remain on this Mac.")
        }
    }

    private var identity: some View {
        HStack(spacing: 10) {
            BrandMarkView(size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text("Notive")
                    .font(.headline)
                Text(theme.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            BrandStatusLabel(title: "On this Mac", systemImage: "lock.fill", kind: .local)
                .labelStyle(.iconOnly)
                .help("Private workspace on this Mac")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
    }

    private var navigation: some View {
        List(selection: Binding(
            get: { store.selection },
            set: { store.select($0) }
        )) {
            Section("Workspace") {
                Label("Home", systemImage: "square.grid.2x2")
                    .tag(WorkspaceSelection.home)
                Label("Ask Notive", systemImage: "bubble.left.and.text.bubble.right")
                    .tag(WorkspaceSelection.ask)
                Label("Dictation", systemImage: "waveform")
                    .tag(WorkspaceSelection.dictation)
                Label("Meeting Notes", systemImage: "note.text")
                    .tag(WorkspaceSelection.notes)
            }

            Section {
                Label("Company", systemImage: "chart.line.uptrend.xyaxis")
                    .tag(WorkspaceSelection.company)
                Label("Agents", systemImage: "bolt.fill")
                    .badge(hub.runningAgentCount)
                    .tag(WorkspaceSelection.agents)
                Label("Shared Context", systemImage: "square.stack.3d.up")
                    .tag(WorkspaceSelection.sharedContext)
                Label("People", systemImage: "person.2")
                    .tag(WorkspaceSelection.people)
                Label("Search", systemImage: "magnifyingglass")
                    .tag(WorkspaceSelection.search)
                Label("Activity", systemImage: "bell")
                    .badge(hub.unreadActivityCount)
                    .tag(WorkspaceSelection.activity)
            } header: {
                HStack(spacing: 6) {
                    Text("Company Hub")
                    Text("SHARED")
                        .font(.caption2.weight(.heavy))
                        .tracking(0.4)
                        .foregroundStyle(.tint)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .overlay { Capsule().stroke(.tint.opacity(0.4), lineWidth: 1) }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Company Hub, shared with the team")
            }

            Section("Recent Meetings") {
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
        .searchable(text: $store.searchText, prompt: "Search meetings")
        .onSubmit(of: .search) { store.search() }
        .onChange(of: store.searchText) { _, value in
            if value.isEmpty { store.reloadMeetings() }
        }
    }

    private var captureControls: some View {
        VStack(spacing: 9) {
            recordingControl

            Button {
                showsAudioImporter = true
            } label: {
                Label("Import Audio", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(store.isImportingAudio)

            HStack(spacing: 8) {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .fixedSize()

                Spacer()

                Menu {
                    ForEach(BrandTheme.allCases) { option in
                        Button {
                            UserDefaults.standard.set(
                                option.rawValue,
                                forKey: "ubundi-meet-brand-theme"
                            )
                        } label: {
                            if option == theme {
                                Label(option.title, systemImage: "checkmark")
                            } else {
                                Text(option.title)
                            }
                        }
                    }
                } label: {
                    Label(theme.title, systemImage: "paintpalette")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Menu {
                    appearanceButton("System", value: "system", icon: "circle.lefthalf.filled")
                    appearanceButton("Light", value: "light", icon: "sun.max")
                    appearanceButton("Dark", value: "dark", icon: "moon")
                } label: {
                    Label("Appearance", systemImage: appearanceIcon)
                        .labelStyle(.iconOnly)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help(theme == .firstMotive ? "First Motive always uses its dark theme" : "Appearance")
            }
            .font(.callout)

            Text("Version \(AppVersion.current)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.bar)
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
    }

    @ViewBuilder
    private var recordingControl: some View {
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
            VStack(spacing: 8) {
                HStack {
                    Button("Pause", systemImage: "pause.fill") { store.pauseRecording() }
                    Button("Stop", systemImage: "stop.fill") {
                        Task { await store.stopRecording() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                RecordingMeter(elapsed: store.recordingElapsed, power: store.recordingPower)
            }
        case .paused:
            HStack {
                Button("Resume", systemImage: "play.fill") { store.resumeRecording() }
                Button("Stop", systemImage: "stop.fill") {
                    Task { await store.stopRecording() }
                }
                .buttonStyle(.borderedProminent)
            }
        case .transcribing:
            if store.isImportingAudio {
                VStack(spacing: 8) {
                    ProgressView("Importing audio")
                    Button("Cancel Import", role: .cancel) { store.cancelImport() }
                }
            } else {
                ProgressView("Transcribing")
            }
        }
    }

    private func appearanceButton(_ title: String, value: String, icon: String) -> some View {
        Button {
            appearance = value
        } label: {
            if appearance == value {
                Label(title, systemImage: "checkmark")
            } else {
                Label(title, systemImage: icon)
            }
        }
    }

    private var appearanceIcon: String {
        appearance == "dark" ? "moon.fill" : appearance == "light" ? "sun.max.fill" : "circle.lefthalf.filled"
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
