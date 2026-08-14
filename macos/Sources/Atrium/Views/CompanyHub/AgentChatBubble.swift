import AtriumCore
import SwiftUI

/// One message in an agent thread.
struct AgentChatBubble: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let message: HubAgentMessage

    private var isMine: Bool { message.origin == .you }

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            Text("\(message.author) · \(message.sentAt, format: .dateTime.hour().minute())")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 4)
            Text(message.text)
                .font(.callout)
                .foregroundStyle(isMine ? palette.onAccent : palette.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(background, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isMine ? .clear : palette.border, lineWidth: 1)
                }
        }
        .frame(maxWidth: 560, alignment: isMine ? .trailing : .leading)
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
        .accessibilityElement(children: .combine)
    }

    private var background: Color {
        switch message.origin {
        case .you: palette.accent
        case .agent: palette.raisedSurface
        case .teammate: .clear
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
