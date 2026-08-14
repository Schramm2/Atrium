import AtriumCore
import SwiftUI

struct AskView: View {
    @Bindable var store: AppStore
    @State private var question = ""
    @State private var selectedMeetingIDs: Set<String> = []
    @State private var limitsDate = false
    @State private var dateFrom = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var dateTo = Date.now
    @State private var askTask: Task<Void, Never>?
    @State private var askTaskID: UUID?

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AtriumPageHeader(
                        "Ask Atrium",
                        detail: "Find answers from your meeting transcripts, with citations."
                    ) {
                        BrandStatusLabel(
                            title: "Searches this Mac",
                            systemImage: "checkmark.shield.fill",
                            kind: .local
                        )
                    }

                    composer
                    result
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .padding(32)
                .frame(maxWidth: 1_280, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Ask Atrium")
        .onDisappear { cancelQuestion() }
    }

    private var composer: some View {
        BrandPanel {
            VStack(alignment: .leading, spacing: 16) {
                TextField(
                    "What decisions did we make about the launch?",
                    text: $question,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.title3)
                .lineLimit(2...5)
                .padding(.vertical, 4)

                Divider()

                HStack(spacing: 12) {
                    Menu {
                        Button("All meetings") { selectedMeetingIDs = [] }
                        Divider()
                        ForEach(store.meetings) { meeting in
                            Toggle(
                                meeting.title,
                                isOn: Binding(
                                    get: { selectedMeetingIDs.contains(meeting.id) },
                                    set: { selected in
                                        if selected {
                                            selectedMeetingIDs.insert(meeting.id)
                                        } else {
                                            selectedMeetingIDs.remove(meeting.id)
                                        }
                                    }
                                )
                            )
                        }
                    } label: {
                        Label(scopeLabel, systemImage: "line.3.horizontal.decrease.circle")
                    }

                    Toggle("Limit by date", isOn: $limitsDate)
                        .toggleStyle(.checkbox)
                    if limitsDate {
                        DatePicker("From", selection: $dateFrom, displayedComponents: .date)
                            .labelsHidden()
                        Text("to").foregroundStyle(.secondary)
                        DatePicker("To", selection: $dateTo, in: dateFrom..., displayedComponents: .date)
                            .labelsHidden()
                    }
                    Spacer()
                    Button("Ask Atrium", systemImage: "arrow.up") { submitQuestion() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(
                            question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || store.askPhase == .retrieving
                                || store.askPhase == .generating
                        )
                }
            }
        }
    }

    @ViewBuilder
    private var result: some View {
        switch store.askPhase {
        case .idle:
            BrandPanel {
                ContentUnavailableView(
                    "Ask across your meeting history",
                    systemImage: "bubble.left.and.text.bubble.right",
                    description: Text("Atrium searches your transcripts and cites the source for each part of the answer.")
                )
                .frame(maxWidth: .infinity, minHeight: 260)
            }
        case .retrieving:
            BrandPanel { workingView(label: "Searching your transcripts…") }
        case let .confirming(provider):
            BrandPanel {
                VStack(alignment: .leading, spacing: 16) {
                    BrandStatusLabel(
                        title: "Leaves this Mac",
                        systemImage: "network.badge.shield.half.filled",
                        kind: .warning
                    )
                    Text("Send the selected transcript excerpts to \(provider)?")
                        .font(.title2.weight(.semibold))
                    Text("Your question and the selected transcript excerpts will leave this Mac. Atrium will remember your choice until you quit the app.")
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Cancel") { cancelQuestion() }
                        Button("Send and Answer") {
                            confirmQuestion()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        case .insufficient:
            BrandPanel {
                ContentUnavailableView(
                    "Not enough information found",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Select more meetings, widen the date range, or ask a different question.")
                )
                .frame(maxWidth: .infinity, minHeight: 240)
            }
        case .generating:
            BrandPanel { workingView(label: "Writing an answer from your transcripts…") }
        case let .failed(message):
            BrandPanel {
                ContentUnavailableView(
                    "Atrium could not answer",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .frame(maxWidth: .infinity, minHeight: 240)
            }
        case .answered:
            answerView
        }
    }

    private func submitQuestion() {
        askTask?.cancel()
        let taskID = UUID()
        let submittedQuestion = question
        let submittedScope = scope
        askTaskID = taskID
        askTask = Task {
            await store.answerQuestion(
                question: submittedQuestion,
                scope: submittedScope
            )
            guard askTaskID == taskID else { return }
            askTask = nil
            askTaskID = nil
        }
    }

    private func confirmQuestion() {
        askTask?.cancel()
        let taskID = UUID()
        askTaskID = taskID
        askTask = Task {
            await store.confirmExternalAsk()
            guard askTaskID == taskID else { return }
            askTask = nil
            askTaskID = nil
        }
    }

    private func cancelQuestion() {
        askTask?.cancel()
        askTask = nil
        askTaskID = nil
        store.cancelAsk()
    }

    private func workingView(label: String) -> some View {
        HStack(spacing: 12) {
            ProgressView(label)
            Button("Cancel", role: .cancel) { cancelQuestion() }
        }
    }

    private var scopeLabel: String {
        selectedMeetingIDs.isEmpty
            ? "All meetings"
            : "\(selectedMeetingIDs.count) meeting\(selectedMeetingIDs.count == 1 ? "" : "s") selected"
    }

    private var scope: AskScope {
        AskScope(
            meetingIDs: selectedMeetingIDs,
            dateFrom: limitsDate ? Calendar.current.startOfDay(for: dateFrom) : nil,
            dateTo: limitsDate
                ? Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: dateTo)
                : nil
        )
    }

    private func evidenceList(_ evidence: [AskEvidence]) -> some View {
        List(evidence) { evidence in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(evidence.meetingTitle)
                        .font(.headline)
                    Spacer()
                    Text(evidence.timestamp)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(evidence.context)
                    .textSelection(.enabled)
                Button("Open citation") {
                    store.openCitation(evidence)
                }
                .buttonStyle(.link)
            }
            .padding(.vertical, 6)
        }
        .listStyle(.plain)
    }

    private var answerView: some View {
        BrandPanel(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
            if let answer = store.askAnswer {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(answer.claims) { claim in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(claim.text)
                                    .textSelection(.enabled)
                                HStack(spacing: 8) {
                                    ForEach(answer.citations(for: claim)) { citation in
                                        Button {
                                            store.openCitation(citation)
                                        } label: {
                                            Text("\(citation.meetingTitle) · \(citation.timestamp)")
                                        }
                                        .buttonStyle(.link)
                                        .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                }
            }
            Divider()
            HStack {
                Text("Sources")
                    .font(.headline)
                Spacer()
                Text("\(citedEvidence.count) cited excerpt\(citedEvidence.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            evidenceList(citedEvidence)
                .frame(minHeight: 220)
            }
        }
    }

    private var citedEvidence: [AskEvidence] {
        store.askAnswer?.citations ?? []
    }
}
