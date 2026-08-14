import NotiveCore
import SwiftUI

struct MeetingNotesView: View {
    @Bindable var store: AppStore

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    NotivePageHeader(
                        "Meeting Notes",
                        detail: "Open a saved conversation to review its transcript, summary, and working notes."
                    ) {
                        Text("\(store.meetings.count) meeting\(store.meetings.count == 1 ? "" : "s")")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    BrandPanel(padding: 0) {
                        if store.meetings.isEmpty {
                            ContentUnavailableView(
                                "No saved conversations",
                                systemImage: "note.text",
                                description: Text("Record a meeting or import audio to start a local meeting record.")
                            )
                            .frame(maxWidth: .infinity, minHeight: 320)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(store.meetings.enumerated()), id: \.element.id) { index, meeting in
                                    Button {
                                        store.select(.meeting(meeting.id))
                                    } label: {
                                        HStack(spacing: 16) {
                                            Image(systemName: meeting.folderPath == nil ? "text.bubble" : "waveform")
                                                .font(.title3)
                                                .foregroundStyle(.tint)
                                                .frame(width: 28)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(meeting.title)
                                                    .font(.headline)
                                                    .lineLimit(1)
                                                HStack(spacing: 12) {
                                                    Text(meeting.createdAt, format: .dateTime.weekday(.abbreviated).month(.wide).day().year())
                                                }
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            if meeting.folderPath != nil {
                                                Label("Audio", systemImage: "speaker.wave.2")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 14)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    if index < store.meetings.count - 1 { Divider() }
                                }
                            }
                        }
                    }
                    .frame(minHeight: 160)
                }
                .padding(32)
                .frame(maxWidth: 1_180, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Meeting Notes")
    }
}
