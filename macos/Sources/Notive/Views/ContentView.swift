import NotiveCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var store: AppStore
    @AppStorage("ubundi-meet-brand-theme") private var themeRaw = BrandTheme.firstMotive.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("notive.onboarding.complete") private var onboardingComplete = false
    @AppStorage("notive.appearance") private var appearance = "system"
    @State private var isAudioDropTargeted = false

    private var theme: BrandTheme {
        BrandTheme(rawValue: themeRaw) ?? .firstMotive
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store, theme: theme)
                .navigationSplitViewColumnWidth(min: 240, ideal: 268, max: 320)
        } detail: {
            detail
        }
        .environment(\.brandTheme, theme)
        .tint(BrandPalette.palette(for: theme, colorScheme: colorScheme).accent)
        .preferredColorScheme(
            theme == .firstMotive
                ? .dark
                : appearance == "light" ? .light : appearance == "dark" ? .dark : nil
        )
        .onAppear { GlobalDictationShortcut.shared.install(store: store) }
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
                RoundedRectangle(cornerRadius: 14)
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
            OnboardingView(isComplete: $onboardingComplete)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let message = store.errorMessage {
                ErrorBanner(message: message) {
                    store.clearError()
                }
            }
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
                Text("Notive needs attention")
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .lineLimit(2)
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
