import AtriumCore
import SwiftUI

/// The row of workspace entry points below the Home heading.
struct HomeWorkflowStrip: View {
    @Bindable var store: AppStore

    private var actions: [HomeWorkflowAction] { HomeWorkflowAction.all }

    private var firstHalf: [HomeWorkflowAction] {
        Array(actions.prefix((actions.count + 1) / 2))
    }

    private var secondHalf: [HomeWorkflowAction] {
        Array(actions.dropFirst((actions.count + 1) / 2))
    }

    var body: some View {
        BrandPanel(padding: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    HomeWorkflowTiles(actions: actions, store: store)
                }
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        HomeWorkflowTiles(actions: firstHalf, store: store)
                    }
                    Divider()
                    HStack(spacing: 0) {
                        HomeWorkflowTiles(actions: secondHalf, store: store)
                    }
                }
            }
        }
    }
}
