import NotiveCore
import SwiftUI

struct HomeView: View {
    @Bindable var store: AppStore

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    NotivePageHeader(
                        "Your conversation workspace",
                        detail: "Record, review, ask, and dictate from one private workspace."
                    ) {
                        BrandStatusLabel(
                            title: "On-device by default",
                            systemImage: "lock.fill",
                            kind: .local
                        )
                    }

                    workflowStrip

                    if !store.searchResults.isEmpty {
                        searchResults
                    } else {
                        recentMeetings
                    }

                    privacySummary
                }
                .padding(32)
                .frame(maxWidth: 1_280, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Home")
    }

    private var workflowStrip: some View {
        BrandPanel(padding: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    WorkspaceAction(
                        title: "Capture",
                        detail: "Record a meeting",
                        systemImage: "mic.fill",
                        emphasized: true
                    ) {
                        Task { await store.startRecording() }
                    }
                    Divider().padding(.vertical, 16)
                    WorkspaceAction(
                        title: "Ask",
                        detail: "Get cited answers",
                        systemImage: "bubble.left.and.text.bubble.right"
                    ) { store.select(.ask) }
                    Divider().padding(.vertical, 16)
                    WorkspaceAction(
                        title: "Dictate",
                        detail: "Write with your voice",
                        systemImage: "waveform"
                    ) { store.select(.dictation) }
                    Divider().padding(.vertical, 16)
                    WorkspaceAction(
                        title: "Review",
                        detail: "Open meeting notes",
                        systemImage: "note.text"
                    ) { store.select(.notes) }
                }

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        WorkspaceAction(
                            title: "Capture",
                            detail: "Record a meeting",
                            systemImage: "mic.fill",
                            emphasized: true
                        ) { Task { await store.startRecording() } }
                        Divider().padding(.vertical, 12)
                        WorkspaceAction(
                            title: "Ask",
                            detail: "Get cited answers",
                            systemImage: "bubble.left.and.text.bubble.right"
                        ) { store.select(.ask) }
                    }
                    Divider()
                    HStack(spacing: 0) {
                        WorkspaceAction(
                            title: "Dictate",
                            detail: "Write with your voice",
                            systemImage: "waveform"
                        ) { store.select(.dictation) }
                        Divider().padding(.vertical, 12)
                        WorkspaceAction(
                            title: "Review",
                            detail: "Open meeting notes",
                            systemImage: "note.text"
                        ) { store.select(.notes) }
                    }
                }
            }
        }
    }

    private var recentMeetings: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent meetings")
                    .font(.title2.weight(.semibold))
                Spacer()
                Text("\(store.meetings.count) meeting\(store.meetings.count == 1 ? "" : "s") saved on this Mac")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            BrandPanel(padding: 0) {
                if store.meetings.isEmpty {
                    ContentUnavailableView(
                        "No meetings yet",
                        systemImage: "waveform.badge.mic",
                        description: Text("Start a recording or import audio to build your local workspace.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(store.meetings.prefix(6).enumerated()), id: \.element.id) { index, meeting in
                            Button {
                                store.select(.meeting(meeting.id))
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "text.bubble")
                                        .font(.title3)
                                        .foregroundStyle(.tint)
                                        .frame(width: 26)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(meeting.title)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(meeting.createdAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 13)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if index < min(store.meetings.count, 6) - 1 { Divider() }
                        }
                    }
                }
            }
        }
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search results")
                .font(.title2.weight(.semibold))
            BrandPanel(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(store.searchResults.enumerated()), id: \.element.id) { index, result in
                        Button {
                            store.select(.meeting(result.meetingID))
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(result.meetingTitle)
                                    .font(.headline)
                                Text(result.context)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                        }
                        .buttonStyle(.plain)
                        if index < store.searchResults.count - 1 { Divider() }
                    }
                }
            }
        }
    }

    private var privacySummary: some View {
        HStack(spacing: 10) {
            Image(systemName: "internaldrive")
                .foregroundStyle(.tint)
            Text("Recordings, transcripts, notes, searches, and citations stay on this Mac.")
                .font(.callout)
            Spacer()
            Text("Notive asks before sending anything outside this Mac")
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}

private struct WorkspaceAction: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let detail: String
    let systemImage: String
    var emphasized = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(emphasized ? palette.onAccent : palette.secondaryAccent)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(emphasized ? palette.onAccent.opacity(0.78) : palette.secondaryText)
                }
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(emphasized ? palette.accent : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
