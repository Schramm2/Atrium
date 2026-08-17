import AtriumCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var store: AppStore
    @Bindable var updater: UpdaterService
    @AppStorage("ubundi-meet-brand-theme") private var themeRaw = BrandTheme.ubundi.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("notive.onboarding.complete") private var onboardingComplete = false
    @AppStorage("notive.appearance") private var appearance = "system"
    @State private var isAudioDropTargeted = false
    @State private var didPresentOnboardingThisLaunch = false
    @State private var dismissedPreviousInstallationNotice = false
    /// No shared workspace is connected yet, so this holds the disconnected provider.
    @State private var hub = CompanyHubStore()
    @State private var github = GitHubRepositoryStore()

    private var theme: BrandTheme {
        BrandTheme(rawValue: themeRaw) ?? .ubundi
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 240, ideal: 268, max: 320)
        } detail: {
            VStack(spacing: 0) {
                if updater.updateNoticeVersion != nil {
                    UpdateBanner(updater: updater)
                }
                if let installation = store.previousInstallation,
                   onboardingComplete,
                   !didPresentOnboardingThisLaunch,
                   !dismissedPreviousInstallationNotice {
                    PreviousInstallationBanner(store: store, installation: installation) {
                        dismissedPreviousInstallationNotice = true
                    }
                }
                if let message = store.errorMessage {
                    ErrorBanner(message: message) {
                        store.clearError()
                    }
                }
                if let message = hub.errorMessage {
                    ErrorBanner(message: message) {
                        hub.clearError()
                    }
                }
                detail
            }
        }
        .environment(hub)
        .environment(github)
        .environment(\.brandTheme, theme)
        .tint(palette.accent)
        .preferredColorScheme(
            theme.isDarkOnly
                ? .dark
                : appearance == "light" ? .light : appearance == "dark" ? .dark : nil
        )
        .toolbarBackground(palette.raisedSurface, for: .windowToolbar)
        .modifier(VisibleToolbarBackground())
        .onAppear {
            if BrandTheme(rawValue: themeRaw) == nil {
                themeRaw = BrandTheme.ubundi.rawValue
            }
            if !onboardingComplete {
                didPresentOnboardingThisLaunch = true
            }
            GlobalDictationShortcut.shared.install(store: store)
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first(where: isSupportedAudio) else { return false }
            Task {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                await store.importAudio(from: url)
            }
            return true
        } isTargeted: { isAudioDropTargeted = $0 }
        .overlay {
            if isAudioDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8]))
                    .padding(12)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .sheet(isPresented: Binding(
            get: { !onboardingComplete },
            set: { if !$0 { onboardingComplete = true } }
        )) {
            OnboardingView(store: store, isComplete: $onboardingComplete)
        }
    }

    private func isSupportedAudio(_ url: URL) -> Bool {
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }
        return type.conforms(to: .audio) || type.conforms(to: .mpeg4Movie)
    }

    @ViewBuilder
    private var detail: some View {
        switch store.selection ?? .home {
        case .home:
            HomeView(store: store)
        case .ask:
            AskView(store: store)
        case .dictation:
            DictationView(store: store)
        case .notes:
            MeetingNotesView(store: store)
        case let .meeting(id):
            MeetingDetailView(store: store, meetingID: id)
                .id(id)
        case .company:
            CompanyDashboardView(store: store)
        case .agents:
            BongiLocalAgentView()
        case .github:
            GitHubRepositoriesView()
        case .sharedContext:
            SharedContextView()
        case .people:
            PeopleView()
        case .search:
            SearchEverythingView()
        case .activity:
            ActivityView()
        }
    }
}

/// `.toolbarBackgroundVisibility(_:for:)` needs macOS 15; on macOS 14 the color
/// set by `.toolbarBackground(_:for:)` already renders opaque, so there is
/// nothing more to force.
private struct VisibleToolbarBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15, *) {
            content.toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        } else {
            content
        }
    }
}

private struct ErrorBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 2) {
                Text("Atrium needs attention")
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .lineLimit(3)
            }
            Spacer()
            Button("Dismiss", systemImage: "xmark", action: dismiss)
                .labelStyle(.iconOnly)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .contain)
    }
}
