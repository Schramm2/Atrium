import SwiftUI

/// A rounded surface that stacks rows with dividers between them.
struct HubRowPanel<Item: Identifiable, Row: View>: View {
    let items: [Item]
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        BrandPanel(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    row(item)
                    if index < items.count - 1 { Divider() }
                }
            }
        }
    }
}
