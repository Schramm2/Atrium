import AppKit
import NotiveCore
import SwiftUI

struct DictationView: View {
    @Bindable var store: AppStore
    @AppStorage("notive.dictation.shortcut") private var shortcut = "Option + Space"
    @AppStorage("notive.dictation.microphone") private var microphone = ""

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    NotivePageHeader(
                        "Local Dictation",
                        detail: "Speak into any app, transcribe on this Mac, and keep the latest result ready to reuse."
                    ) {
                        BrandStatusLabel(
                            title: store.isDictating ? "Listening" : "On-device speech",
                            systemImage: store.isDictating ? "waveform" : "lock.fill",
                            kind: store.isDictating ? .processing : .local
                        )
                    }

                    BrandPanel {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .center, spacing: 32) {
                                dictationAction
                                Divider().frame(minHeight: 160)
                                setupValues
                                    .frame(maxWidth: 430)
                            }
                            VStack(alignment: .leading, spacing: 24) {
                                dictationAction
                                Divider()
                                setupValues
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Latest result")
                                .font(.title2.weight(.semibold))
                            Spacer()
                            if !store.dictationText.isEmpty {
                                Button("Copy", systemImage: "doc.on.doc", action: copyResult)
                            }
                        }

                        BrandPanel {
                            if store.dictationText.isEmpty {
                                ContentUnavailableView(
                                    "No dictation yet",
                                    systemImage: "text.cursor",
                                    description: Text("Use the global shortcut or start dictation above. Your result will appear here.")
                                )
                                .frame(maxWidth: .infinity, minHeight: 230)
                            } else {
                                Text(store.dictationText)
                                    .font(.body)
                                    .lineSpacing(4)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
                            }
                        }
                    }

                    Label(
                        "Speech is processed on this device. Dictation audio is not retained after transcription.",
                        systemImage: "checkmark.shield.fill"
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                .padding(32)
                .frame(maxWidth: 1_180, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Dictation")
    }

    private var dictationAction: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: store.isDictating ? "waveform.circle.fill" : "mic.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .symbolEffect(.variableColor.iterative, isActive: store.isDictating)
                .accessibilityHidden(true)
            Text(statusTitle)
                .font(.title.weight(.semibold))
            Text("Hold \(shortcut) anywhere, or use the control below.")
                .foregroundStyle(.secondary)
            Button(
                store.isDictating ? "Stop Dictation" : "Start Dictation",
                systemImage: store.isDictating ? "stop.fill" : "mic.fill"
            ) {
                Task {
                    if store.isDictating {
                        await store.stopDictation()
                    } else {
                        await store.startDictation()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(store.isPreparingDictation || store.isProcessingDictation)
            if store.isPreparingDictation {
                ProgressView("Preparing microphone")
            }
            if store.isProcessingDictation {
                ProgressView("Transcribing on this Mac")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var setupValues: some View {
        VStack(spacing: 0) {
            SetupValue(title: "Shortcut", value: shortcut, systemImage: "keyboard")
            Divider()
            SetupValue(
                title: "Microphone",
                value: microphone.isEmpty ? "System default" : "Selected microphone",
                systemImage: "mic"
            )
            Divider()
            SetupValue(title: "Processing", value: "On this Mac", systemImage: "cpu")
        }
    }

    private var statusTitle: String {
        if store.isDictating { return "Listening…" }
        if store.isPreparingDictation { return "Preparing…" }
        if store.isProcessingDictation { return "Transcribing…" }
        return "Ready when you are"
    }

    private func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(store.dictationText, forType: .string)
    }
}

private struct SetupValue: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 13)
    }
}
