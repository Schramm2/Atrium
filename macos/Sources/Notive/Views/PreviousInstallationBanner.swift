import NotiveCore
import SwiftUI

struct PreviousInstallationBanner: View {
    @Bindable var store: AppStore
    let installation: PreviousInstallation
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Earlier Notive meetings found")
                    .font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if store.isRestoringPreviousData {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Restoring earlier Notive meetings")
            } else {
                Button("Not Now", action: dismiss)
                Button("Restore Meetings", systemImage: "clock.arrow.circlepath") {
                    Task { await store.restorePreviousInstallation() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .contain)
    }

    private var detail: String {
        let count = installation.meetingCount
        let meetings = count == 1 ? "1 meeting" : "\(count) meetings"
        return "Restore \(meetings) from the earlier installation. Existing meetings stay unchanged."
    }
}
