import AppKit
import AVFoundation
import NotiveCore
import Speech
import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: page == 0 ? "waveform.badge.mic" : page == 1 ? "lock.shield" : "sparkles")
                .font(.system(size: 58))
                .foregroundStyle(.tint)

            VStack(spacing: 10) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                Text(detail)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
            }

            if page == 1 {
                VStack(spacing: 10) {
                    PermissionButton(title: "Microphone", systemImage: "mic") {
                        _ = await AVCaptureDevice.requestAccess(for: .audio)
                    }
                    PermissionButton(title: "Speech Recognition", systemImage: "text.bubble") {
                        _ = await SpeechAuthorization.request()
                    }
                    Button("Screen Recording Settings", systemImage: "rectangle.dashed.badge.record") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(width: 320)
            }

            Spacer()
            HStack {
                if page > 0 {
                    Button("Back") { page -= 1 }
                }
                Spacer()
                Button(page == 2 ? "Start using Notive" : "Continue") {
                    if page == 2 {
                        isComplete = true
                    } else {
                        page += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(40)
        .frame(width: 680, height: 500)
        .interactiveDismissDisabled()
    }

    private var title: String {
        switch page {
        case 0: "Welcome to Notive"
        case 1: "Choose local permissions"
        default: "Ready for your next meeting"
        }
    }

    private var detail: String {
        switch page {
        case 0:
            "Record meetings, create on-device transcripts, and ask questions with cited local evidence."
        case 1:
            "Notive asks for access only when a feature needs it. You can continue and grant access later."
        default:
            "Your database and recordings remain on this Mac. Apple Intelligence is used on device when available."
        }
    }
}

private struct PermissionButton: View {
    let title: String
    let systemImage: String
    let action: () async -> Void
    @State private var requested = false

    var body: some View {
        Button(requested ? "\(title) requested" : "Allow \(title)", systemImage: requested ? "checkmark" : systemImage) {
            Task {
                await action()
                requested = true
            }
        }
        .buttonStyle(.bordered)
        .disabled(requested)
    }
}
