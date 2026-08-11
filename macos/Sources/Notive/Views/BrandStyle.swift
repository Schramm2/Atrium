import NotiveCore
import SwiftUI

struct BrandPalette {
    let accent: Color
    let secondaryAccent: Color
    let warning: Color
    let detailBackground: Color

    static func palette(for theme: BrandTheme, colorScheme: ColorScheme) -> BrandPalette {
        switch theme {
        case .ubundi:
            BrandPalette(
                accent: Color(red: 0.18, green: 0.20, blue: 0.60),
                secondaryAccent: Color(red: 0.20, green: 0.45, blue: 0.72),
                warning: Color(red: 0.75, green: 0.24, blue: 0.28),
                detailBackground: colorScheme == .dark
                    ? Color(nsColor: .windowBackgroundColor)
                    : Color(red: 0.97, green: 0.97, blue: 0.99)
            )
        case .firstMotive:
            BrandPalette(
                accent: Color(red: 0.61, green: 0.72, blue: 0.62),
                secondaryAccent: Color(red: 0.50, green: 0.66, blue: 0.72),
                warning: Color(red: 0.85, green: 0.61, blue: 0.62),
                detailBackground: colorScheme == .dark
                    ? Color(red: 0.20, green: 0.17, blue: 0.22)
                    : Color(red: 0.96, green: 0.94, blue: 0.96)
            )
        }
    }
}

struct BrandThemeKey: EnvironmentKey {
    static let defaultValue = BrandTheme.firstMotive
}

extension EnvironmentValues {
    var brandTheme: BrandTheme {
        get { self[BrandThemeKey.self] }
        set { self[BrandThemeKey.self] = newValue }
    }
}
