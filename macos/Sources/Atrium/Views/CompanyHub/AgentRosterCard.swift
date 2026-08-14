import AtriumCore
import SwiftUI

/// One selectable agent card in the roster.
struct AgentRosterCard: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let agent: HubAgent
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    HubAvatar(initials: agent.initials, tint: agent.tint, size: 34, cornerRadius: 8)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(agent.name)
                            .font(.subheadline.weight(.semibold))
                        Text(agent.role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 6)
                    HubStatusDot(title: agent.status.title, color: agent.status.color(palette))
                }

                Text(agent.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Text("\(agent.runsToday) runs today")
                    if let lastRun = agent.lastRun {
                        Text("Last run \(lastRun, format: .relative(presentation: .numeric))")
                    }
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? palette.secondaryAccent : palette.border, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
