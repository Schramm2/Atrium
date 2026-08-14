import NotiveCore
import SwiftUI

struct SidebarProfileView: View {
    @AppStorage("notive.hub.profile-name") private var profileName = ""
    @AppStorage("notive.hub.profile-role") private var profileRole = ""
    @AppStorage("notive.hub.github-login") private var githubLogin = ""
    @AppStorage("ubundi-meet-brand-theme") private var themeRaw = BrandTheme.firstMotive.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private var palette: BrandPalette {
        BrandPalette.palette(for: activeTheme, colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profile")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 1) {
                    Text(displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(profileDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Button(
                    "Switch to \(nextTheme.title) theme",
                    systemImage: "paintpalette.fill",
                    action: switchTheme
                )
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .help("Switch to \(nextTheme.title) theme")

                SettingsLink {
                    Label("Open Settings", systemImage: "gearshape")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .help("Open Settings")
            }
        }
        .padding(12)
        .background(palette.raisedSurface)
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
    }

    @ViewBuilder
    private var avatar: some View {
        if initials.isEmpty {
            Image(systemName: "person.fill")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.quaternary, in: Circle())
                .accessibilityHidden(true)
        } else {
            Text(initials)
                .font(.caption.bold())
                .foregroundStyle(.tint)
                .frame(width: 34, height: 34)
                .background(.tint.opacity(0.14), in: Circle())
                .accessibilityHidden(true)
        }
    }

    private var activeTheme: BrandTheme {
        BrandTheme(rawValue: themeRaw) ?? .firstMotive
    }

    private var nextTheme: BrandTheme {
        activeTheme == .ubundi ? .firstMotive : .ubundi
    }

    private var displayName: String {
        let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }
        if !githubLogin.isEmpty { return "@\(githubLogin)" }
        return "Local user"
    }

    private var profileDetail: String {
        let role = profileRole.trimmingCharacters(in: .whitespacesAndNewlines)
        if !role.isEmpty { return role }
        if !githubLogin.isEmpty, displayName != "@\(githubLogin)" { return "@\(githubLogin)" }
        return "Private workspace"
    }

    private var initials: String {
        profileName
            .split(whereSeparator: \Character.isWhitespace)
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    private func switchTheme() {
        themeRaw = nextTheme.rawValue
    }
}
