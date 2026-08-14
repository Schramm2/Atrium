import AppKit
import NotiveCore
import SwiftUI

struct MeetingDetailView: View {
    @Bindable var store: AppStore
    let meetingID: String
    @State private var title = ""
    @State private var summaryDraft = ""
    @State private var noteDraft = ""
    @State private var summaryLanguage = "auto"
    @State private var customSummaryInstruction = ""
    @State private var selectedTab = DetailTab.transcript
    @State private var showsDeleteConfirmation = false
    @State private var isSharedToHub = false
    @Environment(CompanyHubStore.self) private var hub

    var body: some View {
        Group {
            if let workspace = store.workspace,
               workspace.meeting.id == meetingID {
                BrandScreen {
                    VStack(spacing: 16) {
                        header(workspace)
                        if store.activeRecordingMeetingID == meetingID || store.isImportingAudio {
                            BrandPanel(padding: 12) {
                                RecordingControlsView(store: store)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        if store.playbackMeetingID == meetingID {
                            BrandPanel(padding: 12) {
                                PlaybackBar(store: store, meeting: workspace.meeting)
                            }
                        }
                        BrandPanel(padding: 0) {
                            TabView(selection: $selectedTab) {
                                TranscriptView(
                                    store: store,
                                    meeting: workspace.meeting,
                                    segments: store.activeRecordingMeetingID == meetingID && !store.liveTranscriptSegments.isEmpty
                                        ? store.liveTranscriptSegments
                                        : workspace.transcripts
                                )
                                    .tabItem { Label("Transcript", systemImage: "text.quote") }
                                    .tag(DetailTab.transcript)
                                SummaryEditor(
                                    markdown: $summaryDraft,
                                    language: $summaryLanguage,
                                    customInstruction: $customSummaryInstruction,
                                    isGenerating: store.isGeneratingSummary,
                                    onSave: { store.saveSummary(markdown: summaryDraft) },
                                    onLanguageChange: { language in
                                        store.saveSummaryLanguage(language, for: workspace.meeting)
                                    },
                                    onGenerate: {
                                        store.beginSummaryGeneration(customPrompt: customSummaryInstruction)
                                    },
                                    onCancel: { store.cancelSummary() }
                                )
                                .tabItem { Label("Summary", systemImage: "sparkles") }
                                .tag(DetailTab.summary)
                                NotesEditor(
                                    markdown: $noteDraft,
                                    onSave: { store.saveNote(markdown: noteDraft) }
                                )
                                .tabItem { Label("Notes", systemImage: "note.text") }
                                .tag(DetailTab.notes)
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .padding(24)
                    .frame(maxWidth: 1_360, maxHeight: .infinity)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .onAppear { setDrafts(from: workspace) }
                .onChange(of: workspace.summary?.markdown) { _, value in
                    summaryDraft = value ?? ""
                }
                .onChange(of: workspace.note.markdown) { _, value in
                    noteDraft = value
                }
            } else {
                ProgressView("Loading meeting")
                    .task { store.loadWorkspace(meetingID: meetingID) }
            }
        }
        .confirmationDialog(
            "Delete this meeting?",
            isPresented: $showsDeleteConfirmation
        ) {
            Button("Delete meeting", role: .destructive) {
                store.deleteMeeting(id: meetingID)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the meeting, transcript, summary, notes, and speaker names from Notive. Recording files remain on this Mac.")
        }
    }

    /// Sharing is a per-meeting choice by its owner. The control stays disabled until a shared
    /// workspace is connected, because nothing may leave this Mac without one.
    private var shareToHubButton: some View {
        Button(
            isSharedToHub ? "Shared to hub" : "Share to hub",
            systemImage: "square.stack.3d.up"
        ) {
            isSharedToHub.toggle()
            Task { await hub.setShared(isSharedToHub, meetingID: meetingID) }
        }
        .buttonStyle(.bordered)
        .disabled(!hub.isConnected)
        .accessibilityAddTraits(isSharedToHub ? [.isSelected] : [])
        .help(
            hub.isConnected
                ? "Share this meeting with the company."
                : "Connect the Company Hub to share a meeting. This meeting stays on this Mac."
        )
    }

    private func header(_ workspace: MeetingWorkspace) -> some View {
        let status = recordingStatus(for: workspace.meeting.id)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                TextField("Meeting title", text: $title)
                    .font(.system(size: 27, weight: .semibold))
                    .textFieldStyle(.plain)
                    .lineLimit(1)
                    .onSubmit { store.renameMeeting(id: meetingID, title: title) }
                Spacer(minLength: 18)
                Button("Save") {
                    store.renameMeeting(id: meetingID, title: title)
                }
                .keyboardShortcut("s")
                Button(
                    store.playbackMeetingID == meetingID && store.isPlaying ? "Pause" : "Play",
                    systemImage: store.playbackMeetingID == meetingID && store.isPlaying ? "pause.fill" : "play.fill"
                ) {
                    store.togglePlayback(for: workspace.meeting)
                }
                .buttonStyle(.borderedProminent)
                .disabled(MeetingAudioFiles.primary(in: workspace.meeting.folderPath) == nil)
                shareToHubButton
                Menu {
                    if store.isRetranscribing {
                        Button("Cancel transcription", systemImage: "xmark", role: .cancel) {
                            store.cancelRetranscription()
                        }
                    } else {
                        Button("Transcribe again", systemImage: "arrow.triangle.2.circlepath") {
                            store.beginRetranscription()
                        }
                        .disabled(MeetingAudioFiles.primary(in: workspace.meeting.folderPath) == nil)
                    }
                    Button("Open Recording", systemImage: "folder") {
                        openRecordingFolder(workspace.meeting.folderPath)
                    }
                    .disabled(workspace.meeting.folderPath == nil)
                    Divider()
                    Button("Delete Meeting", systemImage: "trash", role: .destructive) {
                        showsDeleteConfirmation = true
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
            HStack(spacing: 12) {
                Text(workspace.meeting.createdAt, format: .dateTime.weekday(.wide).month(.wide).day().year().hour().minute())
                if !workspace.transcripts.isEmpty {
                    Text("\(workspace.transcripts.count) transcript excerpt\(workspace.transcripts.count == 1 ? "" : "s")")
                }
                Spacer()
                BrandStatusLabel(
                    title: status.title,
                    systemImage: status.systemImage,
                    kind: status.isActive ? .processing : .local
                )
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    private func recordingStatus(for meetingID: String) -> (
        title: String,
        systemImage: String,
        isActive: Bool
    ) {
        guard store.activeRecordingMeetingID == meetingID else {
            return ("Saved locally", "internaldrive", false)
        }
        switch store.recordingState {
        case .recording:
            return ("Recording", "record.circle", true)
        case .paused:
            return ("Recording paused", "pause.circle", true)
        case .transcribing:
            return ("Transcribing", "waveform", true)
        case .idle, .failed:
            return ("Saved locally", "internaldrive", false)
        }
    }

    private func setDrafts(from workspace: MeetingWorkspace) {
        title = workspace.meeting.title
        summaryDraft = workspace.summary?.markdown ?? ""
        noteDraft = workspace.note.markdown
        summaryLanguage = store.summaryLanguage(for: workspace.meeting)
        customSummaryInstruction = ""
    }

    private func openRecordingFolder(_ path: String?) {
        guard let path else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    private enum DetailTab: Hashable {
        case transcript
        case summary
        case notes
    }
}

private struct PlaybackBar: View {
    @Bindable var store: AppStore
    let meeting: Meeting

    var body: some View {
        HStack(spacing: 12) {
            Button(store.isPlaying ? "Pause" : "Play", systemImage: store.isPlaying ? "pause.fill" : "play.fill") {
                store.togglePlayback(for: meeting)
            }
            .labelStyle(.iconOnly)
            Text(Self.time(store.playbackTime))
                .font(.caption.monospacedDigit())
            Slider(
                value: Binding(
                    get: { store.playbackTime },
                    set: { store.seekPlayback(to: $0) }
                ),
                in: 0...max(1, store.playbackDuration)
            )
            Text(Self.time(store.playbackDuration))
                .font(.caption.monospacedDigit())
        }
    }

    private static func time(_ value: TimeInterval) -> String {
        let seconds = max(0, Int(value))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct TranscriptView: View {
    @Bindable var store: AppStore
    let meeting: Meeting
    let segments: [TranscriptSegment]

    var body: some View {
        if segments.isEmpty {
            ContentUnavailableView(
                "No transcript",
                systemImage: "text.quote",
                description: Text(
                    MeetingAudioFiles.primary(in: meeting.folderPath) == nil
                        ? "Record or import audio to add a transcript."
                        : "Select Transcribe again to recover it from the saved audio."
                )
            )
        } else {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Copy transcript", systemImage: "doc.on.doc") {
                            let text = segments.map { segment in
                                let speaker = segment.resolvedSpeaker.map { "\($0): " } ?? ""
                                return "[\(Self.timeLabel(segment.audioStartTime))] \(speaker)\(segment.text)"
                            }.joined(separator: "\n")
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(text, forType: .string)
                        }
                        .padding(.trailing, 8)
                    }
                    List(segments) { segment in
                    HStack(alignment: .top, spacing: 16) {
                        Button(Self.timeLabel(segment.audioStartTime)) {
                            if let time = segment.audioStartTime {
                                store.play(meeting, at: time)
                            }
                        }
                        .buttonStyle(.borderless)
                        .font(.caption.monospacedDigit())
                        VStack(alignment: .leading, spacing: 5) {
                            if segment.speaker != nil {
                                SpeakerLabelEditor(store: store, segment: segment)
                            }
                            Text(segment.text)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.vertical, 5)
                    .listRowBackground(
                        store.highlightedTranscriptID == segment.id
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear
                    )
                    .id(segment.id)
                    }
                    .listStyle(.inset)
                    .onAppear {
                        if let id = store.highlightedTranscriptID {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private static func timeLabel(_ value: Double?) -> String {
        guard let value else { return "--:--" }
        let seconds = max(0, Int(value))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct SpeakerLabelEditor: View {
    @Bindable var store: AppStore
    let segment: TranscriptSegment
    @State private var isEditing = false
    @State private var alias = ""

    var body: some View {
        Button(segment.resolvedSpeaker ?? "Speaker") {
            alias = segment.speakerDisplayName ?? ""
            isEditing = true
        }
        .buttonStyle(.plain)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .popover(isPresented: $isEditing) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Speaker name")
                    .font(.headline)
                TextField("Name", text: $alias)
                    .frame(width: 220)
                    .onSubmit(save)
                HStack {
                    if segment.speakerDisplayName != nil {
                        Button("Clear") {
                            if let speaker = segment.speaker {
                                store.clearSpeakerAlias(originalLabel: speaker)
                            }
                            isEditing = false
                        }
                    }
                    Spacer()
                    Button("Save", action: save)
                        .buttonStyle(.borderedProminent)
                        .disabled(alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
    }

    private func save() {
        guard let speaker = segment.speaker else { return }
        store.saveSpeakerAlias(originalLabel: speaker, alias: alias)
        isEditing = false
    }
}

private struct SummaryEditor: View {
    @Binding var markdown: String
    @Binding var language: String
    @Binding var customInstruction: String
    let isGenerating: Bool
    let onSave: () -> Void
    let onLanguageChange: (String) -> Void
    let onGenerate: () -> Void
    let onCancel: () -> Void
    @AppStorage("notive.summary.template") private var template = SummaryTemplate.standard.rawValue

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Summary")
                    .font(.headline)
                Picker("Template", selection: $template) {
                    ForEach(SummaryTemplate.allCases) { template in
                        Text(template.title).tag(template.rawValue)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 190)
                Picker(
                    "Language",
                    selection: Binding(
                        get: { language },
                        set: { value in
                            language = value
                            onLanguageChange(value)
                        }
                    )
                ) {
                    Text("Auto").tag("auto")
                    ForEach(MeetingSummaryPreferenceStore.supportedLanguages) { language in
                        Text(language.title).tag(language.code)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 180)
                Spacer()
                if isGenerating {
                    ProgressView().controlSize(.small)
                    Button("Cancel", systemImage: "xmark", role: .cancel, action: onCancel)
                } else {
                    Button("Generate", systemImage: "sparkles", action: onGenerate)
                }
                Button("Copy", systemImage: "doc.on.doc") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(markdown, forType: .string)
                }
                Button("Save", action: onSave)
            }
            TextField("Additional summary instruction", text: $customInstruction)
                .textFieldStyle(.roundedBorder)
                .disabled(isGenerating)
            TextEditor(text: $markdown)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 16)
    }
}

private struct NotesEditor: View {
    @Binding var markdown: String
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Meeting notes")
                    .font(.headline)
                Spacer()
                Button("Save", action: onSave)
            }
            TextEditor(text: $markdown)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 16)
    }
}
