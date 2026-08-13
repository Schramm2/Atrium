import AppKit
import CoreGraphics
import NotiveCore
import Speech
import SwiftUI

struct OnboardingView: View {
    @Bindable var store: AppStore
    @Binding var isComplete: Bool
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("ubundi-meet-brand-theme") private var themeRaw = BrandTheme.firstMotive.rawValue
    @AppStorage("notive.hub.profile-name") private var profileName = ""
    @AppStorage("notive.hub.profile-role") private var profileRole = ""
    @AppStorage("notive.hub.appear-in-people") private var appearInPeople = true
    @AppStorage("notive.hub.share-activity") private var shareActivity = true
    @AppStorage("notive.hub.agents-read-shared") private var agentsReadShared = true
    @AppStorage("notive.hub.github-login") private var githubLogin = ""
    @AppStorage("notive.hub.github-organization") private var githubOrganization = ""
    @State private var step = OnboardingStep.welcome
    @State private var permissions = OnboardingPermissions()
    @State private var identityPhase = GitHubCheckPhase.unchecked
    @State private var restoredData: PreviousInstallationImport?

    /// The earlier-data step is offered only when this Mac holds meetings to take back.
    private var steps: [OnboardingStep] {
        OnboardingStep.allCases.filter { $0 != .earlierData || offersEarlierData }
    }

    private var offersEarlierData: Bool {
        store.previousInstallation != nil || restoredData != nil
    }

    private var currentIndex: Int {
        steps.firstIndex(of: step) ?? 0
    }

    private var caption: String {
        guard currentIndex > 0 else { return "Set up in about a minute" }
        return "Step \(currentIndex + 1) of \(steps.count) — \(step.caption)"
    }

    private var theme: BrandTheme {
        BrandTheme(rawValue: themeRaw) ?? .firstMotive
    }

    var body: some View {
        ZStack {
            BrandScreen { Color.clear }
            BrandAtmosphere()
                .frame(width: 880, height: 620)
                .clipped()

            VStack(spacing: 0) {
                header
                Divider()
                ScrollView {
                    stepBody
                        .containerRelativeFrame(.vertical)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider()
                footer
            }
            .frame(width: 880, height: 620)
        }
        .environment(\.brandTheme, theme)
        .frame(width: 880, height: 620)
        .interactiveDismissDisabled()
        .task { permissions.refresh() }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            permissions.refresh()
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            BrandMarkView(size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text("Notive")
                    .font(.headline)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 7) {
                ForEach(Array(steps.enumerated()), id: \.element) { index, item in
                    Button {
                        step = item
                    } label: {
                        Capsule()
                            .fill(
                                index < currentIndex
                                    ? palette.secondaryAccent
                                    : item == step ? palette.accent : palette.border
                            )
                            .frame(width: item == step ? 26 : 8, height: 7)
                    }
                    .buttonStyle(.plain)
                    .disabled(index >= currentIndex)
                    .help(item.label)
                    .accessibilityLabel(item.label)
                    .accessibilityValue(
                        item == step
                            ? "Current step"
                            : index < currentIndex ? "Completed step" : "Upcoming step"
                    )
                }
            }
            .animation(.easeInOut(duration: 0.25), value: step)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepBody: some View {
        switch step {
        case .welcome: identityStep
        case .earlierData: earlierDataStep
        case .workspace: workspaceStep
        case .access: accessStep
        case .hub: hubStep
        case .ready: readyStep
        }
    }

    private var identityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingEyebrow("Welcome")
            OnboardingTitle("One private workspace for every conversation")
                .frame(maxWidth: 560, alignment: .leading)
            OnboardingLead(
                "Record meetings, dictate text, review notes, and get cited answers — with a shared Company Hub when you choose to share. First, whose workspace is this?"
            )
            HStack(alignment: .top, spacing: 16) {
                IdentityCard(
                    markName: "ubundi-mark",
                    title: "Ubundi",
                    detail: "Open, precise, human. Light workspace with navy identity.",
                    isSelected: theme == .ubundi
                ) {
                    themeRaw = BrandTheme.ubundi.rawValue
                }
                IdentityCard(
                    markName: "first-motive-mark",
                    title: "First Motive",
                    detail: "Grounded, technical, warm. Signature dark aubergine workspace.",
                    isSelected: theme == .firstMotive
                ) {
                    themeRaw = BrandTheme.firstMotive.rawValue
                }
            }
            .frame(maxWidth: 640)
            .padding(.top, 8)
            Text("This sets your workspace identity and theme. Change it any time in Settings.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .transition(.opacity)
    }

    private var workspaceStep: some View {
        HStack(alignment: .top, spacing: 28) {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingEyebrow("Your workspace")
                OnboardingTitle("Four ways to work, one place")
                OnboardingLead(
                    "Everything below runs on this Mac. Meetings, transcripts, and notes are yours — the Company Hub only sees what you choose to share."
                )
                Spacer()
                Label(
                    "New: the Company Hub adds shared context, agents, and company-wide search.",
                    systemImage: "square.stack.3d.up"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(palette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.border, lineWidth: 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            BrandPanel(padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    OnboardingWorkflow(
                        icon: "mic.fill", title: "Capture", detail: "Record live or import audio"
                    )
                    Divider()
                    OnboardingWorkflow(
                        icon: "text.quote", title: "Review",
                        detail: "Transcript, summary, and notes"
                    )
                    Divider()
                    OnboardingWorkflow(
                        icon: "bubble.left.and.text.bubble.right", title: "Ask",
                        detail: "Get answers with citations"
                    )
                    Divider()
                    OnboardingWorkflow(
                        icon: "waveform", title: "Dictate", detail: "Write by voice in any app"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
            .frame(width: 300)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(width: 792)
        .padding(.horizontal, 44)
        .padding(.vertical, 32)
        .transition(.opacity)
    }

    private var accessStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingEyebrow("Access")
            OnboardingTitle("Choose the access each feature needs")
            OnboardingLead(
                "Notive asks for access only when a feature needs it. Grant what you like now — everything can wait until later in Settings."
            )
            VStack(spacing: 10) {
                PermissionCard(
                    icon: "mic",
                    title: "Microphone",
                    detail: "Needed to record meetings and dictate.",
                    cta: "Allow",
                    granted: permissions.microphone
                ) {
                    _ = await MicrophoneAuthorization.request()
                    permissions.refresh()
                }
                PermissionCard(
                    icon: "text.bubble",
                    title: "Speech Recognition",
                    detail: "Transcribes speech on this Mac — audio never leaves the device.",
                    cta: "Allow",
                    granted: permissions.speech
                ) {
                    _ = await SpeechAuthorization.request()
                    permissions.refresh()
                }
                PermissionCard(
                    icon: "rectangle.dashed.badge.record",
                    title: "System Audio",
                    detail: "Captures the other side of calls. Opens System Settings.",
                    cta: "Open Settings",
                    granted: permissions.systemAudio
                ) {
                    if !CGRequestScreenCaptureAccess(),
                        let url = URL(
                            string:
                                "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
                        ) {
                        NSWorkspace.shared.open(url)
                    }
                    permissions.refresh()
                }
            }
            .frame(maxWidth: 600)
            .padding(.top, 6)
            Text("Permissions are optional and can be changed later in System Settings.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .transition(.opacity)
    }

    private var earlierDataStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingEyebrow("Earlier meetings")
            OnboardingTitle("Notive found meetings from before")
            OnboardingLead(
                "An earlier Notive installation left meeting data on this Mac. Take it back and your meetings, transcripts, notes, summaries, and speaker names return with their recordings."
            )
            EarlierDataCard(
                installation: store.previousInstallation,
                restored: restoredData,
                isRestoring: store.isRestoringPreviousData,
                errorMessage: store.previousInstallationRestoreError
            ) {
                restoredData = await store.restorePreviousInstallation()
            }
            .frame(maxWidth: 660)
            Label(
                "Meetings you already have stay as they are. Nothing is removed from the earlier folder.",
                systemImage: "lock"
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .transition(.opacity)
    }

    private var hubStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingEyebrow("Company Hub")
            OnboardingTitle("Join the shared workspace")
            OnboardingLead(
                "The hub is where the team — and the company agents — share context. Your meetings stay private unless you share them, one at a time."
            )
            GitHubIdentityCard(phase: identityPhase) {
                await verifyGitHubIdentity()
            }
            .frame(maxWidth: 660)
            .task { if identityPhase == .unchecked { await verifyGitHubIdentity() } }
            HStack(alignment: .top, spacing: 16) {
                BrandPanel(padding: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your profile in the hub")
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .foregroundStyle(.tertiary)
                        TextField("Your name", text: $profileName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Role — e.g. Product Lead", text: $profileRole)
                            .textFieldStyle(.roundedBorder)
                        Text("Shown in People and next to anything you share.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                BrandPanel(padding: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        HubToggleRow(
                            title: "Appear in People",
                            detail: "Your name, role, and status are visible to the team.",
                            isOn: $appearInPeople
                        )
                        Divider()
                        HubToggleRow(
                            title: "Show my shares in Activity",
                            detail: "When you share a meeting, it appears in the company feed.",
                            isOn: $shareActivity
                        )
                        Divider()
                        HubToggleRow(
                            title: "Let agents read what I share",
                            detail: "Openclaw and Hermes can use your shared items — never local ones.",
                            isOn: $agentsReadShared
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 4)
                }
            }
            .frame(width: 660)
            .padding(.top, 6)
            Label(
                "Sharing a meeting to the hub is always a separate, explicit action — never automatic.",
                systemImage: "lock"
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .transition(.opacity)
    }

    private var readyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 64, height: 64)
                .background(palette.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(palette.border, lineWidth: 1)
                }
                .accessibilityHidden(true)
            OnboardingTitle(readyTitle)
            Text("Recordings, transcripts, notes, and searches stay on this Mac. Notive asks before anything leaves it.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)
            VStack(spacing: 10) {
                ForEach(Array(summaryChipRows.enumerated()), id: \.offset) { row in
                    HStack(spacing: 10) {
                        ForEach(row.element, id: \.label) { chip in
                            Label(chip.label, systemImage: "checkmark")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(palette.surface, in: Capsule())
                                .overlay { Capsule().stroke(palette.border, lineWidth: 1) }
                        }
                    }
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    private var readyTitle: String {
        let firstName = profileName.trimmingCharacters(in: .whitespaces)
            .split(separator: " ").first.map(String.init)
        if let firstName, !firstName.isEmpty {
            return "Your workspace is ready, \(firstName)"
        }
        return "Your local workspace is ready"
    }

    private struct SummaryChip {
        let label: String
    }

    private var summaryChips: [SummaryChip] {
        [
            SummaryChip(label: "\(theme.title) workspace"),
            SummaryChip(label: "\(permissions.grantedCount) of 3 permissions granted"),
            SummaryChip(
                label: githubLogin.isEmpty
                    ? "GitHub not connected"
                    : "GitHub: @\(githubLogin) · \(githubOrganization)"
            ),
            SummaryChip(label: appearInPeople ? "Visible in People" : "Hidden from People"),
            SummaryChip(label: "Sharing: per-meeting, opt-in"),
        ]
    }

    private var summaryChipRows: [[SummaryChip]] {
        stride(from: 0, to: summaryChips.count, by: 3).map {
            Array(summaryChips[$0..<min($0 + 3, summaryChips.count)])
        }
    }

    private func verifyGitHubIdentity() async {
        guard identityPhase != .checking else { return }
        identityPhase = .checking
        let service = GitHubIdentityService.live()
        let status = await Task.detached { service.verify() }.value
        identityPhase = .checked(status)
        if case let .verified(identity, organization) = status {
            githubLogin = identity.login
            githubOrganization = organization
            if profileName.trimmingCharacters(in: .whitespaces).isEmpty, let name = identity.name {
                profileName = name
            }
        } else {
            githubLogin = ""
            githubOrganization = ""
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 14) {
            if currentIndex > 0 {
                Button("Back") {
                    step = steps[currentIndex - 1]
                }
            }
            Spacer()
            switch step {
            case .earlierData:
                Text(
                    restoredData == nil
                        ? "You can also do this later in Settings."
                        : "Your earlier meetings are in the sidebar."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            case .hub:
                Text(
                    isHubVerified
                        ? "You can change all of this in Settings."
                        : "Joining the hub needs a company GitHub identity — or skip for now."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            case .welcome, .workspace, .access, .ready:
                EmptyView()
            }
            if step.isSkippable, !(step == .earlierData && restoredData != nil) {
                Button("Skip for now") { advance() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            Button(step == .ready ? "Start Using Notive" : "Continue") {
                advance()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(continueIsBlocked)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var isHubVerified: Bool {
        if case .checked(.verified) = identityPhase { return true }
        return false
    }

    private var continueIsBlocked: Bool {
        switch step {
        case .hub: !isHubVerified
        case .earlierData: store.isRestoringPreviousData || restoredData == nil
        default: false
        }
    }

    private func advance() {
        if step == .ready {
            isComplete = true
        } else {
            step = steps[min(currentIndex + 1, steps.count - 1)]
        }
    }
}

// MARK: - Steps

private enum OnboardingStep: CaseIterable, Hashable {
    case welcome
    case earlierData
    case workspace
    case access
    case hub
    case ready

    var label: String {
        switch self {
        case .welcome: "Welcome"
        case .earlierData: "Earlier meetings"
        case .workspace: "Your workspace"
        case .access: "Access"
        case .hub: "Company Hub"
        case .ready: "Ready"
        }
    }

    var caption: String {
        switch self {
        case .welcome: "welcome"
        case .earlierData: "meetings from before"
        case .workspace: "what Notive does"
        case .access: "permissions"
        case .hub: "the shared hub"
        case .ready: "all set"
        }
    }

    var isSkippable: Bool {
        self == .earlierData || self == .access || self == .hub
    }
}

// MARK: - Earlier meeting data

private struct EarlierDataCard: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let installation: PreviousInstallation?
    let restored: PreviousInstallationImport?
    let isRestoring: Bool
    let errorMessage: String?
    let restore: () async -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: restored == nil ? "clock.arrow.circlepath" : "checkmark")
                .foregroundStyle(restored == nil ? palette.secondaryAccent : palette.accent)
                .frame(width: 38, height: 38)
                .background(palette.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.border, lineWidth: 1)
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(detailColor)
            }
            Spacer()
            if isRestoring {
                ProgressView()
                    .controlSize(.small)
            } else if restored == nil {
                Button("Restore") {
                    Task { await restore() }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(restored == nil ? palette.border : palette.accent, lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.25), value: isRestoring)
    }

    private var title: String {
        if let restored {
            return "\(Self.meetings(restored.importedMeetingCount)) restored"
        }
        guard let installation else { return "No earlier meetings found" }
        return "\(Self.meetings(installation.importableMeetingCount)) found"
    }

    private var detail: String {
        if let errorMessage { return errorMessage }
        if let restored {
            var parts: [String] = []
            if restored.copiedRecordingCount > 0 {
                let recordings = restored.copiedRecordingCount == 1
                    ? "1 recording"
                    : "\(restored.copiedRecordingCount) recordings"
                parts.append("\(recordings) copied into your recordings folder")
            }
            if restored.skippedMeetingCount > 0 {
                parts.append("\(restored.skippedMeetingCount) you already had were left alone")
            }
            return parts.isEmpty ? "Everything came across." : parts.joined(separator: " · ")
        }
        guard let installation else {
            return "Notive found no meeting data from an earlier installation."
        }
        var parts = ["\(installation.transcriptCount) transcript segments"]
        if let latest = installation.latestMeetingDate, latest > .distantPast {
            parts.append("most recent \(latest.formatted(date: .abbreviated, time: .omitted))")
        }
        return parts.joined(separator: " · ")
    }

    private static func meetings(_ count: Int) -> String {
        count == 1 ? "1 meeting" : "\(count) meetings"
    }

    private var detailColor: Color {
        errorMessage == nil ? .secondary : .red
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}

// MARK: - GitHub identity check

private enum GitHubCheckPhase: Equatable {
    case unchecked
    case checking
    case checked(GitHubIdentityStatus)
}

private struct GitHubIdentityCard: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let phase: GitHubCheckPhase
    let recheck: () async -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 38, height: 38)
                .background(palette.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.border, lineWidth: 1)
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            switch phase {
            case .checking:
                ProgressView()
                    .controlSize(.small)
            case .checked(.verified):
                Label("Verified", systemImage: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(palette.accent)
            default:
                Button("Check Again") {
                    Task { await recheck() }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isVerified ? palette.accent : palette.border, lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.25), value: phase)
    }

    private var isVerified: Bool {
        if case .checked(.verified) = phase { return true }
        return false
    }

    private var iconName: String {
        switch phase {
        case .checked(.verified): "person.badge.shield.checkmark"
        case .checked(.notMember): "person.badge.minus"
        default: "person.crop.circle.badge.questionmark"
        }
    }

    private var iconColor: Color {
        switch phase {
        case .checked(.verified): palette.accent
        case .checked(.notMember), .checked(.notAuthenticated), .checked(.cliMissing):
            palette.warning
        default: palette.secondaryAccent
        }
    }

    private var title: String {
        switch phase {
        case .unchecked, .checking:
            "GitHub identity"
        case .checked(.cliMissing):
            "GitHub CLI not found"
        case .checked(.notAuthenticated):
            "GitHub sign-in required"
        case let .checked(.notMember(identity)):
            "@\(identity.login) is not in a company organization"
        case let .checked(.verified(identity, organization)):
            "Signed in as @\(identity.login) · \(organization)"
        }
    }

    private var detail: String {
        switch phase {
        case .unchecked, .checking:
            "Checking the GitHub CLI on this Mac."
        case .checked(.cliMissing):
            "Install the GitHub CLI (gh), then check again."
        case .checked(.notAuthenticated):
            "Run “gh auth login” in Terminal, then check again."
        case .checked(.notMember):
            "The hub needs membership in Ubundi or first-motive on GitHub."
        case .checked(.verified):
            "Your company GitHub identity connects you to the hub."
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}

// MARK: - Permission state

@MainActor
@Observable
private final class OnboardingPermissions {
    var microphone = false
    var speech = false
    var systemAudio = false

    var grantedCount: Int {
        [microphone, speech, systemAudio].count(where: { $0 })
    }

    func refresh() {
        microphone = MicrophoneAuthorization.currentStatus == .authorized
        speech = SFSpeechRecognizer.authorizationStatus() == .authorized
        systemAudio = CGPreflightScreenCaptureAccess()
    }
}

// MARK: - Shared step typography

private struct OnboardingEyebrow: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(.tint)
    }
}

private struct OnboardingTitle: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.largeTitle.weight(.semibold))
            .tracking(-0.6)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct OnboardingLead: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.title3)
            .foregroundStyle(.secondary)
            .lineSpacing(3)
            .frame(maxWidth: 540, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Step components

private struct IdentityCard: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let markName: String
    let title: String
    let detail: String
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Group {
                        if let image = BrandAssets.image(named: markName) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: "waveform.badge.mic")
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text(title)
                        .font(.headline)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.bold))
                            .foregroundStyle(palette.accent)
                    }
                }
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? palette.accent : palette.border, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}

private struct PermissionCard: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    let detail: String
    let cta: String
    let granted: Bool
    let request: () async -> Void
    @State private var isRequesting = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(granted ? palette.accent : palette.secondaryAccent)
                .frame(width: 38, height: 38)
                .background(palette.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.border, lineWidth: 1)
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if granted {
                Label("Granted", systemImage: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(palette.accent)
            } else {
                Button(cta) {
                    isRequesting = true
                    Task {
                        await request()
                        isRequesting = false
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isRequesting)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(granted ? palette.accent : palette.border, lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.25), value: granted)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}

private struct HubToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle(title, isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
        }
        .padding(.vertical, 11)
    }
}

private struct OnboardingWorkflow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 13)
    }
}
