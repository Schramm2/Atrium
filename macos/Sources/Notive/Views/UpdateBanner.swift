import SwiftUI

struct UpdateBanner: View {
    @Bindable var updater: UpdaterService

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            action
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .contain)
    }

    private var title: String {
        guard let version = updater.updateNoticeVersion else { return "Notive update" }
        return "Notive \(version) is available"
    }

    private var detail: String {
        if case .installing(_, let message) = updater.phase { return message }
        if case .failed(let message, _) = updater.phase { return message }
        return updater.installationBlockReason
            ?? "Update from version \(updater.currentVersion) when you are ready."
    }

    @ViewBuilder
    private var action: some View {
        if case .installing = updater.phase {
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("Installing Notive update")
        } else if let version = updater.updateNoticeVersion {
            Button("Update Now", systemImage: "arrow.down.circle") {
                Task { await updater.performPrimaryAction() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!updater.canPerformPrimaryAction)
            .accessibilityLabel("Update Notive to version \(version)")
            .help(updater.installationBlockReason ?? "Install Notive \(version)")
        }
    }
}
