import AtriumCore
import SwiftUI

struct SidebarView: View {
    @Bindable var store: AppStore
    @Environment(CompanyHubStore.self) private var hub
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @State private var meetingToDelete: Meeting?

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            identity
            Divider()
                .overlay(palette.border)
            navigation
            Divider()
                .overlay(palette.border)
            SidebarProfileView()
        }
        .background(palette.raisedSurface)
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
            Text("This removes the meeting, transcript, summary, notes, and speaker names from Atrium. Recording files remain on this Mac.")
        }
    }

    private var identity: some View {
        HStack(spacing: 12) {
            BrandMarkView(size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text("Atrium")
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
                Label("Ask Atrium", systemImage: "bubble.left.and.text.bubble.right")
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
        .scrollContentBackground(.hidden)
        .background(palette.raisedSurface)
        .searchable(text: $store.searchText, prompt: "Search meetings")
        .onSubmit(of: .search) { store.search() }
        .onChange(of: store.searchText) { _, value in
            if value.isEmpty { store.reloadMeetings() }
        }
    }

}
