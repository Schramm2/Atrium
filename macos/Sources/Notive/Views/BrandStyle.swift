import AppKit
import NotiveCore
import SwiftUI

struct BrandPalette {
    let accent: Color
    let secondaryAccent: Color
    let ai: Color
    let warning: Color
    let success: Color
    let detailBackground: Color
    let surface: Color
    let raisedSurface: Color
    let border: Color
    let text: Color
    let secondaryText: Color
    let onAccent: Color

    static func palette(for theme: BrandTheme, colorScheme: ColorScheme) -> BrandPalette {
        switch theme {
        case .ubundi:
            let isDark = colorScheme == .dark
            return BrandPalette(
                accent: Color(red: 0.184, green: 0.204, blue: 0.596),
                secondaryAccent: Color(red: 0.443, green: 0.533, blue: 0.745),
                ai: Color(red: 0.757, green: 0.514, blue: 0.902),
                warning: Color(red: 0.843, green: 0.478, blue: 0.522),
                success: Color(red: 0.31, green: 0.56, blue: 0.46),
                detailBackground: isDark
                    ? Color(red: 0.055, green: 0.063, blue: 0.12)
                    : Color(red: 0.973, green: 0.976, blue: 0.988),
                surface: isDark
                    ? Color(red: 0.085, green: 0.094, blue: 0.16)
                    : .white,
                raisedSurface: isDark
                    ? Color(red: 0.115, green: 0.125, blue: 0.20)
                    : Color(red: 0.956, green: 0.96, blue: 0.976),
                border: isDark ? Color.white.opacity(0.13) : Color.black.opacity(0.11),
                text: isDark ? .white.opacity(0.95) : Color(red: 0.07, green: 0.07, blue: 0.08),
                secondaryText: isDark ? .white.opacity(0.68) : .black.opacity(0.62),
                onAccent: .white
            )
        case .firstMotive:
            let ivory = Color(red: 0.91, green: 0.886, blue: 0.843)
            return BrandPalette(
                accent: Color(red: 0.612, green: 0.722, blue: 0.62),
                secondaryAccent: Color(red: 0.498, green: 0.663, blue: 0.722),
                ai: Color(red: 0.608, green: 0.561, blue: 0.722),
                warning: Color(red: 0.847, green: 0.608, blue: 0.624),
                success: Color(red: 0.612, green: 0.722, blue: 0.62),
                detailBackground: Color(red: 0.263, green: 0.231, blue: 0.278),
                surface: Color.white.opacity(0.045),
                raisedSurface: Color.white.opacity(0.075),
                border: ivory.opacity(0.14),
                text: ivory,
                secondaryText: ivory.opacity(0.72),
                onAccent: Color(red: 0.165, green: 0.227, blue: 0.173)
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

struct BrandScreen<Content: View>: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .foregroundStyle(palette.text)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(palette.detailBackground)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}

struct NotivePageHeader<Trailing: View>: View {
    let title: String
    let detail: String
    private let trailing: Trailing

    init(
        _ title: String,
        detail: String,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.detail = detail
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                    .tracking(-0.5)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 720, alignment: .leading)
            Spacer(minLength: 12)
            trailing
        }
        .accessibilityElement(children: .contain)
    }
}

extension NotivePageHeader where Trailing == EmptyView {
    init(_ title: String, detail: String) {
        self.init(title, detail: detail) { EmptyView() }
    }
}

struct BrandPanel<Content: View>: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(palette.border, lineWidth: 1)
            }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}

struct BrandStatusLabel: View {
    enum Kind {
        case local, processing, warning, success
    }

    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let systemImage: String
    let kind: Kind

    var body: some View {
        // The tint carries the state on the icon, fill, and border. The title uses the
        // theme text color, because tinted caption text does not reach WCAG AA on either
        // theme surface.
        Label {
            Text(title)
                .foregroundStyle(palette.text)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(color)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.13), in: Capsule())
        .overlay { Capsule().stroke(color.opacity(0.24), lineWidth: 1) }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }

    private var color: Color {
        switch kind {
        case .local: palette.secondaryAccent
        case .processing: palette.ai
        case .warning: palette.warning
        case .success: palette.success
        }
    }
}

struct BrandMarkView: View {
    @Environment(\.brandTheme) private var theme
    let size: CGFloat

    var body: some View {
        Group {
            if let image = BrandAssets.image(named: theme == .ubundi ? "ubundi-mark" : "first-motive-mark") {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "waveform.badge.mic")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.2)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        .accessibilityHidden(true)
    }
}

struct BrandAtmosphere: View {
    @Environment(\.brandTheme) private var theme

    var body: some View {
        if theme == .firstMotive,
           let image = BrandAssets.image(named: "first-motive-atmosphere") {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .opacity(0.34)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

@MainActor
enum BrandAssets {
    private static let cache = NSCache<NSString, NSImage>()

    static func image(named name: String) -> NSImage? {
        if let image = cache.object(forKey: name as NSString) { return image }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else {
            return nil
        }
        guard let image = NSImage(contentsOf: url) else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}
