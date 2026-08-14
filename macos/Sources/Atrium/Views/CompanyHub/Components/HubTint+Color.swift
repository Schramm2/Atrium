import AtriumCore
import SwiftUI

extension HubTint {
    func color(_ palette: BrandPalette) -> Color {
        switch self {
        case .accent: palette.accent
        case .secondaryAccent: palette.secondaryAccent
        case .ai: palette.ai
        }
    }
}

extension HubTone {
    func color(_ palette: BrandPalette) -> Color {
        switch self {
        case .success: palette.success
        case .warning: palette.warning
        case .neutral: palette.secondaryText
        }
    }
}

extension HubAgentStatus {
    func color(_ palette: BrandPalette) -> Color {
        switch self {
        case .running: palette.success
        case .idle: palette.secondaryText
        }
    }
}
