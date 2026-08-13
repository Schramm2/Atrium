import NotiveCore
import SwiftUI

/// Agent summary and latest activity, shown beside "Shared today".
struct CompanyAgentColumn: View {
    @Bindable var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CompanyAgentPanel(store: store)
            LatestActivityPanel(store: store)
        }
    }
}
