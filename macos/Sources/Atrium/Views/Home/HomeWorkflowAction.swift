import AtriumCore
import SwiftUI

/// One entry point in the Home workflow strip.
struct HomeWorkflowAction: Identifiable {
    let id: WorkspaceSelection
    let title: String
    let detail: String
    let systemImage: String

    static let all: [HomeWorkflowAction] = [
        HomeWorkflowAction(
            id: .ask,
            title: "Ask Atrium",
            detail: "Cited answers from meetings",
            systemImage: "bubble.left.and.text.bubble.right"
        ),
        HomeWorkflowAction(
            id: .dictation,
            title: "Dictate",
            detail: "Write with your voice",
            systemImage: "waveform"
        ),
        HomeWorkflowAction(
            id: .notes,
            title: "Review",
            detail: "Open meeting notes",
            systemImage: "note.text"
        ),
        HomeWorkflowAction(
            id: .search,
            title: "Search",
            detail: "Workspace and Company Hub",
            systemImage: "magnifyingglass"
        ),
    ]
}
