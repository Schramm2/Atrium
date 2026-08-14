import NotiveCore
import SwiftUI

/// One row in the "Shared today" panel.
struct SharedTodayRow: View {
    let item: HubItem

    var body: some View {
        HStack(spacing: 12) {
            HubAvatar(
                initials: item.sharedByInitials,
                tint: .secondaryAccent,
                size: 28,
                cornerRadius: 8
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(item.excerpt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            HubTag(title: item.kind.title)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
