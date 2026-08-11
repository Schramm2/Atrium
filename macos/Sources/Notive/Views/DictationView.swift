import AppKit
import NotiveCore
import SwiftUI

struct DictationView: View {
    @Bindable var store: AppStore
    @AppStorage("notive.dictation.shortcut") private var shortcut = "Option + Space"
    @AppStorage("notive.dictation.microphone") private var microphone = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("NOTIVE")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dictation")
                            .font(.largeTitle.weight(.semibold))
                        Text("Ready")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(statusTitle)
                            .font(.title2.weight(.semibold))
                        Text("Use the global shortcut anywhere, or start here.")
                            .foregroundStyle(.secondary)
                        Button(
                            store.isDictating ? "Stop dictation" : "Start dictation",
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
                        .disabled(store.isProcessingDictation)
                        if store.isProcessingDictation {
                            ProgressView("Transcribing on device")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                }

                HStack(spacing: 24) {
                    SetupValue(title: "Shortcut", value: shortcut)
                    SetupValue(
                        title: "Microphone",
                        value: microphone.isEmpty ? "System default" : "Selected microphone"
                    )
                    SetupValue(title: "Model", value: "On-device speech")
                }

                GroupBox("Last result") {
                    if store.dictationText.isEmpty {
                        ContentUnavailableView(
                            "Your latest dictation will appear here",
                            systemImage: "text.cursor"
                        )
                        .frame(maxWidth: .infinity, minHeight: 180)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(store.dictationText)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                            Button("Copy", systemImage: "doc.on.doc") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(store.dictationText, forType: .string)
                            }
                        }
                        .padding(10)
                    }
                }

                Label(
                    "Speech is processed on this device. Audio is not retained after transcription.",
                    systemImage: "lock.fill"
                )
                .foregroundStyle(.secondary)
            }
            .padding(40)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .navigationTitle("Dictation")
    }

    private var statusTitle: String {
        if store.isDictating { return "Listening…" }
        if store.isProcessingDictation { return "Transcribing…" }
        return "Ready when you are."
    }

}

private struct SetupValue: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
