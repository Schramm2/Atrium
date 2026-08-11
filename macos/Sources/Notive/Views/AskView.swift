import NotiveCore
import SwiftUI

struct AskView: View {
    @Bindable var store: AppStore
    @State private var question = ""
    @State private var selectedMeetingIDs: Set<String> = []
    @State private var limitsDate = false
    @State private var dateFrom = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var dateTo = Date.now
    @State private var askTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ask Notive")
                    .font(.largeTitle.weight(.semibold))
                Text("Answers use only cited meeting transcript evidence.")
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 12) {
                TextField(
                    "What decisions did we make about the launch?",
                    text: $question,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...5)

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

                Button("Ask") {
                    submitQuestion()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || store.askPhase == .retrieving
                        || store.askPhase == .generating
                )
            }

            HStack(spacing: 12) {
                Toggle("Limit by date", isOn: $limitsDate)
                    .toggleStyle(.checkbox)
                if limitsDate {
                    DatePicker("From", selection: $dateFrom, displayedComponents: .date)
                    DatePicker("To", selection: $dateTo, in: dateFrom..., displayedComponents: .date)
                }
            }

            Divider()

            switch store.askPhase {
            case .idle:
                ContentUnavailableView(
                    "Ask about your meetings",
                    systemImage: "bubble.left.and.text.bubble.right"
                )
            case .retrieving:
                workingView(label: "Searching local transcripts")
            case let .confirming(provider):
                VStack(alignment: .leading, spacing: 14) {
                    Label("Send selected evidence to \(provider)?", systemImage: "network.badge.shield.half.filled")
                        .font(.headline)
                    Text("The question and retrieved transcript evidence will leave this Mac. You will not be asked again for this provider until Notive quits.")
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Cancel") { cancelQuestion() }
                        Button("Send and answer") {
                            submitQuestion(externalEvidenceConfirmed: true)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            case .insufficient:
                ContentUnavailableView(
                    "No supporting evidence",
                    systemImage: "doc.text.magnifyingglass"
                )
            case .generating:
                workingView(label: "Generating answer")
            case let .failed(message):
                ContentUnavailableView(
                    "Ask failed",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            case .answered:
                answerView
            }
        }
        .padding(32)
        .frame(maxWidth: 1_000, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Ask Notive")
        .onDisappear { cancelQuestion() }
    }

    private func submitQuestion(externalEvidenceConfirmed: Bool = false) {
        askTask?.cancel()
        askTask = Task {
            await store.answerQuestion(
                question: question,
                scope: scope,
                externalEvidenceConfirmed: externalEvidenceConfirmed
            )
            askTask = nil
        }
    }

    private func cancelQuestion() {
        askTask?.cancel()
        askTask = nil
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
            : "\(selectedMeetingIDs.count) selected"
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

    private var evidenceList: some View {
        List(store.askEvidence) { evidence in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(evidence.id)
                        .font(.caption.monospaced().weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
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
        .listStyle(.inset)
    }

    private var answerView: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let answer = store.askAnswer {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(answer.claims) { claim in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(claim.text)
                                    .textSelection(.enabled)
                                Text(claim.citationIDs.joined(separator: " · "))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text("\(answer.provider) · \(answer.model)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Text("Sources")
                .font(.headline)
            evidenceList
                .frame(minHeight: 220)
        }
    }
}
