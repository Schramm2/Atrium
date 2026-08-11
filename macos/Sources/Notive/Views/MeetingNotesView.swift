import NotiveCore
import SwiftUI

struct MeetingNotesView: View {
    @Bindable var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meeting Notes")
                .font(.largeTitle.weight(.semibold))
            Text("Open a meeting to review or edit its notes.")
                .foregroundStyle(.secondary)
            List(store.meetings) { meeting in
                Button {
                    store.select(.meeting(meeting.id))
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(meeting.title)
                                .font(.headline)
                            Text(meeting.createdAt, format: .dateTime.year().month().day())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
        }
        .padding(32)
        .navigationTitle("Meeting Notes")
    }
}
