import AppKit
import NotiveCore
import Speech
import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @Environment(\.brandTheme) private var theme
    @State private var page = 0

    var body: some View {
        ZStack {
            BrandScreen { Color.clear }
            BrandAtmosphere()
                .clipped()

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    BrandMarkView(size: 38)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Notive")
                            .font(.headline)
                        Text(theme.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 7) {
                        ForEach(0..<3, id: \.self) { index in
                            Capsule()
                                .fill(index == page ? Color.accentColor : Color.secondary.opacity(0.24))
                                .frame(width: index == page ? 28 : 8, height: 7)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Step \(page + 1) of 3")
                }
                .padding(24)

                Divider()

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 18) {
                        Image(systemName: pageIcon)
                            .font(.system(size: 42, weight: .medium))
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        Text(title)
                            .font(.largeTitle.weight(.semibold))
                            .tracking(-0.6)
                        Text(detail)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .frame(maxWidth: 460, alignment: .leading)

                        if page == 1 {
                            permissionControls
                        } else if page == 2 {
                            VStack(alignment: .leading, spacing: 11) {
                                OnboardingFact(icon: "internaldrive", title: "Local meeting database")
                                OnboardingFact(icon: "text.bubble", title: "On-device transcription")
                                OnboardingFact(icon: "checkmark.shield", title: "Explicit external evidence sharing")
                            }
                            .padding(.top, 4)
                        }
                        Spacer()
                    }
                    .padding(36)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    if page == 0 {
                        BrandPanel {
                            VStack(alignment: .leading, spacing: 0) {
                                OnboardingWorkflow(icon: "mic.fill", title: "Capture", detail: "Record live or import audio")
                                Divider()
                                OnboardingWorkflow(icon: "text.quote", title: "Review", detail: "Transcript, summary, and notes")
                                Divider()
                                OnboardingWorkflow(icon: "bubble.left.and.text.bubble.right", title: "Recall", detail: "Ask with cited evidence")
                                Divider()
                                OnboardingWorkflow(icon: "waveform", title: "Dictate", detail: "Write by voice in any app")
                            }
                        }
                        .padding(.trailing, 36)
                        .frame(width: 330)
                    }
                }

                Divider()

                HStack {
                    if page > 0 {
                        Button("Back") { page -= 1 }
                    }
                    Spacer()
                    if page == 1 {
                        Text("Permissions are optional and can be changed later.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button(page == 2 ? "Start Using Notive" : "Continue") {
                        if page == 2 {
                            isComplete = true
                        } else {
                            page += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(24)
            }
        }
        .frame(width: 820, height: 560)
        .interactiveDismissDisabled()
    }

    private var permissionControls: some View {
        VStack(spacing: 10) {
            PermissionButton(title: "Microphone", systemImage: "mic") {
                _ = await MicrophoneAuthorization.request()
            }
            PermissionButton(title: "Speech Recognition", systemImage: "text.bubble") {
                _ = await SpeechAuthorization.request()
            }
            Button("Open Screen Recording Settings", systemImage: "rectangle.dashed.badge.record") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: 360, alignment: .leading)
    }

    private var pageIcon: String {
        switch page {
        case 0: "waveform.badge.mic"
        case 1: "hand.raised.fill"
        default: "checkmark.seal.fill"
        }
    }

    private var title: String {
        switch page {
        case 0: "One private workspace for every conversation"
        case 1: "Choose the access each feature needs"
        default: "Your local workspace is ready"
        }
    }

    private var detail: String {
        switch page {
        case 0:
            "Capture meetings, dictate text, review notes, and recall cited evidence without splitting the work across tools."
        case 1:
            "Notive asks for access only when a feature needs it. You can continue now and grant access later in Settings."
        default:
            "Recordings, transcripts, notes, retrieval, and default answers stay on this Mac. External AI use is always explicit."
        }
    }
}

private struct OnboardingFact: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
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

private struct PermissionButton: View {
    let title: String
    let systemImage: String
    let action: () async -> Void
    @State private var requested = false
    @State private var isRequesting = false

    var body: some View {
        Button(
            requested ? "\(title) Requested" : isRequesting ? "Requesting \(title)" : "Allow \(title)",
            systemImage: requested ? "checkmark" : systemImage
        ) {
            isRequesting = true
            Task {
                await action()
                requested = true
                isRequesting = false
            }
        }
        .buttonStyle(.bordered)
        .disabled(requested || isRequesting)
    }
}
