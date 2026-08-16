import AppKit
import AtriumCore
import SwiftUI

struct GitHubRepositoriesView: View {
    @Environment(GitHubRepositoryStore.self) private var github

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AtriumPageHeader(
                        "GitHub",
                        detail: "Work that needs action, recent delivery, and important repositories across both companies."
                    ) {
                        HStack(spacing: 12) {
                            if let lastUpdatedAt = github.lastUpdatedAt {
                                Text("Updated \(lastUpdatedAt, format: .relative(presentation: .numeric))")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            Button("Refresh", systemImage: "arrow.clockwise", action: refresh)
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .disabled(github.isLoading)
                        }
                    }

                    content

                    HubPrivacyFootnote(
                        text: "Atrium reads only work available to your authenticated GitHub CLI session. Repository data and favourites stay on this Mac."
                    )
                }
                .padding(32)
                .frame(maxWidth: 1_280, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("GitHub")
        .task {
            if !github.hasLoaded || github.errorMessage != nil { await github.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if github.shouldRefresh() { refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if github.isLoading && !github.hasLoaded {
            BrandPanel {
                ProgressView("Loading GitHub work…")
                    .frame(maxWidth: .infinity, minHeight: 240)
            }
        } else if let error = github.errorMessage, !hasContent {
            BrandPanel(padding: 0) {
                ContentUnavailableView {
                    Label("GitHub unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try again", action: refresh)
                }
                .frame(maxWidth: .infinity, minHeight: 280)
            }
        } else {
            GitHubDashboardView()
        }
    }

    private var hasContent: Bool {
        !github.repositories.isEmpty || !github.attention.isEmpty
            || !github.recentDelivery.isEmpty || !github.notifications.isEmpty
    }

    private func refresh() {
        Task { await github.load() }
    }
}
