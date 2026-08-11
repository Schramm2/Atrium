import NotiveCore
import SwiftUI

struct HomeView: View {
    @Bindable var store: AppStore
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTIVE · PRIVATE WORKSPACE")
                            .font(.caption.weight(.semibold))
                            .tracking(2)
                            .foregroundStyle(.secondary)
                        Text("Conversation capture")
                            .font(.largeTitle.weight(.semibold))
                        Text("Record, transcribe, and keep the context of important conversations close to the work.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 680, alignment: .leading)
                    }
                    Spacer()
                    Label("On-device by default", systemImage: "lock.fill")
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }

                GroupBox {
                    HStack(spacing: 40) {
                        VStack(alignment: .leading, spacing: 16) {
                            Image(systemName: "waveform.badge.mic")
                                .font(.system(size: 38))
                                .foregroundStyle(palette.accent)
                            Text("Keep the conversation.\nMove the work forward.")
                                .font(.system(size: 30, weight: .semibold))
                            Text("Capture the context while it is fresh. Transcription stays local, so your notes stay close to the work.")
                                .foregroundStyle(.secondary)
                            Button {
                                Task { await store.startRecording() }
                            } label: {
                                Label("Start a recording", systemImage: "mic.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()

                        VStack(alignment: .leading, spacing: 18) {
                            Text("YOUR PRIVATE WORKFLOW")
                                .font(.caption.weight(.semibold))
                                .tracking(1.5)
                                .foregroundStyle(.secondary)
                            WorkflowStep(number: "01", title: "Capture the conversation")
                            WorkflowStep(number: "02", title: "Review the transcript")
                            WorkflowStep(number: "03", title: "Keep the next step visible")
                        }
                        .frame(maxWidth: 320, alignment: .leading)
                    }
                    .padding(24)
                }
                .groupBoxStyle(.automatic)

                if !store.searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search results")
                            .font(.title2.weight(.semibold))
                        ForEach(store.searchResults) { result in
                            Button {
                                store.select(.meeting(result.meetingID))
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.meetingTitle)
                                        .font(.headline)
                                    Text(result.context)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                }
            }
            .padding(40)
            .frame(maxWidth: 1_100, alignment: .leading)
        }
        .background(palette.detailBackground.opacity(theme == .firstMotive ? 0.9 : 1))
        .navigationTitle("Conversation capture")
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}

private struct WorkflowStep: View {
    let number: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)
            Text(title)
        }
    }
}
