import Foundation

public enum SummaryTemplate: String, CaseIterable, Identifiable, Sendable {
    case standard = "standard_meeting"
    case dailyStandup = "daily_standup"
    case projectSync = "project_sync"
    case retrospective = "retrospective"
    case clientCall = "sales_marketing_client_call"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .standard: "Standard meeting"
        case .dailyStandup: "Daily standup"
        case .projectSync: "Project sync"
        case .retrospective: "Retrospective"
        case .clientCall: "Client or sales call"
        }
    }

    var sectionInstruction: String {
        switch self {
        case .standard:
            "Use supported sections from: Summary, Key Decisions, Action Items, and Discussion Highlights."
        case .dailyStandup:
            "Use supported sections from: Attendees, Yesterday, Today, Blockers, and Notes."
        case .projectSync:
            "Use supported sections from: Milestones and Status, Progress, Risks and Mitigations, Decisions, and Action Items."
        case .retrospective:
            "Use supported sections from: Start Doing, Stop Doing, Continue Doing, Action Items, and Notes."
        case .clientCall:
            "Use supported sections from: Client Goals, Agreed Deliverables, Commercial Terms, Risks, and Next Steps."
        }
    }
}
