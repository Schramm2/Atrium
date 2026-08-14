import AtriumCore
import SwiftUI

/// People directory across both companies.
struct PeopleView: View {
    @Environment(CompanyHubStore.self) private var hub
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AtriumPageHeader(
                        "People",
                        detail: "Everyone across Ubundi and First Motive, with what they work on now."
                    ) {
                        Text(headcountSummary)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    if hub.people.isEmpty {
                        HubEmptyState.notConnected(
                            "No people",
                            systemImage: "person.2",
                            appears: "Everyone in the shared workspace, their role, and their current focus appear here.",
                            minHeight: 300
                        )
                    } else {
                        directory
                    }
                }
                .padding(32)
                .frame(maxWidth: 1_180, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("People")
        .task { await hub.loadPeople() }
    }

    private var headcountSummary: String {
        guard !hub.people.isEmpty else { return "Not connected" }
        let agents = hub.people.count(where: \.isAgent)
        return "\(hub.people.count - agents) people · \(agents) agents"
    }

    private var directory: some View {
        VStack(spacing: 0) {
            HubTableHeader(
                columns: ["Name", "Role", "Company", "Focus this week", "Status"],
                widths: [nil, 160, 120, 200, 110]
            )
            Divider()
            ForEach(Array(hub.people.enumerated()), id: \.element.id) { index, person in
                PersonRow(person: person)
                if index < hub.people.count - 1 { Divider() }
            }
        }
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1)
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
