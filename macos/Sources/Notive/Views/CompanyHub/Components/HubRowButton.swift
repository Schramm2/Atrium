import SwiftUI

/// Makes a whole row clickable while keeping its plain appearance.
struct HubRowButton<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            content
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
