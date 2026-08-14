import NotiveCore
import SwiftUI

/// The newest meetings held on this Mac.
struct HomeRecentMeetingsPanel: View {
    @Bindable var store: AppStore

    private var meetings: [Meeting] {
        Array(store.meetings.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "Recent meetings") {
                Button("All meetings") { store.select(.notes) }
                    .buttonStyle(.link)
                    .font(.callout.weight(.semibold))
            }

            if meetings.isEmpty {
                BrandPanel(padding: 0) {
                    ContentUnavailableView(
                        "No meetings yet",
                        systemImage: "waveform.badge.mic",
                        description: Text("Start a recording or import audio to build your local workspace.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 220)
                }
            } else {
                HubRowPanel(items: meetings) { meeting in
                    HubRowButton(action: { store.select(.meeting(meeting.id)) }) {
                        HStack(spacing: 12) {
                            Image(systemName: "text.bubble")
                                .font(.body)
                                .foregroundStyle(.tint)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(meeting.title)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text(
                                    meeting.createdAt,
                                    format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
