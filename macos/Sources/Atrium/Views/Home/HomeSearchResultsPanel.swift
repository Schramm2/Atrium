import AtriumCore
import SwiftUI

/// Transcript matches for the current sidebar search.
struct HomeSearchResultsPanel: View {
    @Bindable var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "Search results") {
                Text("\(store.searchResults.count) match\(store.searchResults.count == 1 ? "" : "es")")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HubRowPanel(items: store.searchResults) { result in
                HubRowButton(action: { store.select(.meeting(result.meetingID)) }) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(result.meetingTitle)
                            .font(.subheadline.weight(.semibold))
                        Text(result.context)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
