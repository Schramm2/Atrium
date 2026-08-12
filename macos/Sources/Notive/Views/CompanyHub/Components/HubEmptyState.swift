import NotiveCore
import SwiftUI

/// Empty state for a Company Hub screen or section.
///
/// While no shared workspace is connected, this explains why the screen is empty instead of
/// showing an unexplained blank surface.
struct HubEmptyState: View {
    let title: String
    let systemImage: String
    let description: String
    var minHeight: CGFloat = 240

    var body: some View {
        BrandPanel(padding: 0) {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(description)
            )
            .frame(maxWidth: .infinity, minHeight: minHeight)
        }
    }
}

extension HubEmptyState {
    /// The standard explanation while the hub has no shared workspace behind it.
    static func notConnected(
        _ title: String,
        systemImage: String,
        appears: String,
        minHeight: CGFloat = 240
    ) -> HubEmptyState {
        HubEmptyState(
            title: title,
            systemImage: systemImage,
            description: "\(appears) The Company Hub is not connected, so nothing is shared yet.",
            minHeight: minHeight
        )
    }
}
