import AtriumCore
import SwiftUI

/// The headline numbers at the top of the Company screen.
struct CompanyStatStrip: View {
    let stats: [HubStat]

    private var firstHalf: [HubStat] {
        Array(stats.prefix((stats.count + 1) / 2))
    }

    private var secondHalf: [HubStat] {
        Array(stats.dropFirst((stats.count + 1) / 2))
    }

    var body: some View {
        BrandPanel(padding: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    CompanyStatCells(stats: stats)
                }
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        CompanyStatCells(stats: firstHalf)
                    }
                    Divider()
                    HStack(spacing: 0) {
                        CompanyStatCells(stats: secondHalf)
                    }
                }
            }
        }
    }
}
