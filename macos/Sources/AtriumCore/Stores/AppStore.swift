import Foundation
import Observation

@MainActor
@Observable
public final class AppStore {
    public private(set) var meetings: [Meeting] = []
    public var selection: WorkspaceSelection? = .home
    public var searchText = ""
    public private(set) var workspace: MeetingWorkspace?
    public private(set) var searchResults: [TranscriptSearchResult] = []
    public private(set) var askEvidence: [AskEvidence] = []
    public private(set) var askAnswer: AskAnswer?
    public private(set) var askPhase: AskPhase = .idle
    public private(set) var isLoading = false
    public private(set) var recordingState: RecordingState = .idle
    public private(set) var recordingElapsed: TimeInterval = 0
    public private(set) var recordingPower: Float = -80
    public private(set) var activeRecordingMeetingID: String?
    public private(set) var liveTranscriptSegments: [TranscriptSegment] = []
    public private(set) var playbackMeetingID: String?
    public private(set) var playbackTime: TimeInterval = 0
    public private(set) var playbackDuration: TimeInterval = 0
    public private(set) var isPlaying = false
    public private(set) var isRetranscribing = false
    public private(set) var isGeneratingSummary = false
    public private(set) var isImportingAudio = false
    public private(set) var highlightedTranscriptID: String?
    public private(set) var isDictating = false
    public private(set) var isPreparingDictation = false
    public private(set) var isProcessingDictation = false
    public private(set) var dictationText = ""
    public private(set) var previousInstallation: PreviousInstallation?
    public private(set) var isRestoringPreviousData = false
    public private(set) var previousInstallationRestoreError: String?
    public var errorMessage: String?

    public let databaseURL: URL
    public let database: SQLiteDatabase
    @ObservationIgnored private let recorder = LiveMeetingCaptureService()
    @ObservationIgnored private let dictationRecorder = LiveMeetingCaptureService()
    @ObservationIgnored private let transcription: any SpeechTranscribing
    @ObservationIgnored private let systemAudioCapture = SystemAudioCaptureService()
    @ObservationIgnored private let audioMixer = AudioMixingService()
    @ObservationIgnored private let audioImporter = AudioImportService()
    @ObservationIgnored private let voiceCluster = VoiceClusterService()
    @ObservationIgnored private let intelligence = LocalIntelligenceService()
    @ObservationIgnored private let askAnswerer: any AskAnswering
    @ObservationIgnored private let askConfiguration: () -> AIConfiguration
    @ObservationIgnored private let notifications = NotificationService()
    @ObservationIgnored private let playback = AudioPlaybackService()
    @ObservationIgnored private var meterTimer: Timer?
    @ObservationIgnored private var playbackTimer: Timer?
    @ObservationIgnored private var importCancellationRequested = false
    @ObservationIgnored private let recordingsFolder: () -> URL
    @ObservationIgnored private var activeAskOperationID: UUID?
    @ObservationIgnored private var pendingExternalAsk: PendingExternalAsk?
    @ObservationIgnored private var confirmedExternalAskDestinations: Set<ExternalAskDestination> = []
    @ObservationIgnored private var summaryTask: Task<Void, Never>?
    @ObservationIgnored private var activeSummaryOperationID: UUID?
    @ObservationIgnored private var retranscriptionTask: Task<Void, Never>?
    @ObservationIgnored private var activeRetranscriptionOperationID: UUID?
    @ObservationIgnored private var activeDictationOperationID: UUID?
    @ObservationIgnored private var isStartingRecording = false
    @ObservationIgnored private var isCapturingSystemAudio = false

    public convenience init() throws {
        let url = try SQLiteDatabase.defaultDatabaseURL()
        try self.init(
            databaseURL: url,
            previousInstallation: PreviousInstallationService.find(currentDatabaseURL: url)
        )
    }

    public init(
        databaseURL: URL,
        transcription: any SpeechTranscribing = SpeechTranscriptionService(),
        recordingsFolder: @escaping () -> URL = { RecordingPreferenceStore.folder() },
        askAnswerer: any AskAnswering = LocalIntelligenceService(),
        askConfiguration: @escaping () -> AIConfiguration = { AIConfiguration.load() },
        previousInstallation: PreviousInstallation? = nil
    ) throws {
        self.databaseURL = databaseURL
        self.transcription = transcription
        self.recordingsFolder = recordingsFolder
        self.askAnswerer = askAnswerer
        self.askConfiguration = askConfiguration
        database = try SQLiteDatabase(url: databaseURL)
        if let previousInstallation {
            if let importableMeetingCount = try? database.importableMeetingCount(
                from: previousInstallation.databaseURL
            ) {
                self.previousInstallation = importableMeetingCount > 0
                    ? PreviousInstallation(
                        databaseURL: previousInstallation.databaseURL,
                        survey: previousInstallation.survey,
                        importableMeetingCount: importableMeetingCount
                    )
                    : nil
            } else {
                // Keep the offer when the source cannot be inspected now so a transient
                // file-access error does not silently discard the user's restore option.
                self.previousInstallation = previousInstallation
            }
        } else {
            self.previousInstallation = nil
        }
        for folder in [databaseURL.deletingLastPathComponent(), previousInstallation?.applicationSupportURL] {
            guard let folder else { continue }
            try? RecordingPreferenceStore.migrateLegacyPreferences(from: folder)
        }
    }

    /// Copies the meetings held by an earlier installation into this one.
    ///
    /// Meetings Atrium already holds stay unchanged.
    @discardableResult
    public func restorePreviousInstallation() async -> PreviousInstallationImport? {
        guard let installation = previousInstallation, !isRestoringPreviousData else { return nil }
        isRestoringPreviousData = true
        previousInstallationRestoreError = nil
        defer { isRestoringPreviousData = false }

        let database = database
        let folder = recordingsFolder()
        do {
            let summary = try await Task.detached {
                try PreviousInstallationService.restore(
                    installation,
                    into: database,
                    recordingsFolder: folder
                )
            }.value
            previousInstallation = nil
            reloadMeetings()
            return summary
        } catch {
            let message = "Atrium could not read the meetings from the earlier installation."
            previousInstallationRestoreError = message
            errorMessage = message
            DiagnosticLogger.failure(operation: "previous_installation_restore", error: error)
            return nil
        }
    }

    public func start() {
        reloadMeetings()
        if case let .meeting(id) = selection {
            loadWorkspace(meetingID: id)
        }
    }

    public func reloadMeetings() {
        perform {
            meetings = try database.fetchMeetings(matching: searchText)
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                searchResults = []
            }
        }
    }

    public func search() {
        perform {
            meetings = try database.fetchMeetings(matching: searchText)
            searchResults = try database.search(searchText)
        }
    }

    public func select(_ newSelection: WorkspaceSelection?) {
        selection = newSelection
        if case let .meeting(id) = newSelection {
            loadWorkspace(meetingID: id)
        } else {
            workspace = nil
        }
    }

    public func loadWorkspace(meetingID: String) {
        perform {
            guard let meeting = try database.fetchMeeting(id: meetingID) else {
                throw DatabaseError.invalidData("The selected meeting no longer exists.")
            }
            workspace = MeetingWorkspace(
                meeting: meeting,
                transcripts: try database.fetchTranscripts(meetingID: meetingID),
                note: try database.fetchNote(meetingID: meetingID)
                    ?? MeetingNote(meetingID: meetingID, markdown: ""),
                summary: try database.fetchSummary(meetingID: meetingID),
                aliases: try database.fetchSpeakerAliases(meetingID: meetingID)
            )
        }
    }

    @discardableResult
    public func createMeeting(title: String = "New meeting") -> Meeting? {
        var created: Meeting?
        perform {
            created = try database.createMeeting(title: title)
            if let created {
                try MeetingSummaryPreferenceStore.applyDefault(to: created)
            }
            reloadMeetings()
            if let created {
                select(.meeting(created.id))
            }
        }
        return created
    }

    public func renameMeeting(id: String, title: String) {
        perform {
            try database.updateMeetingTitle(id: id, title: title)
            reloadMeetings()
            loadWorkspace(meetingID: id)
        }
    }

    public func deleteMeeting(id: String) {
        perform {
            try database.deleteMeeting(id: id)
            if selection == .meeting(id) {
                selection = .home
                workspace = nil
            }
            reloadMeetings()
        }
    }

    public func saveNote(markdown: String) {
        guard var current = workspace else { return }
        current.note.markdown = markdown
        current.note.updatedAt = .now
        perform {
            try database.saveNote(current.note)
            workspace = current
        }
    }

    public func saveSummary(markdown: String) {
        guard let meetingID = workspace?.meeting.id else { return }
        perform {
            try database.saveSummary(meetingID: meetingID, markdown: markdown)
            workspace?.summary = try database.fetchSummary(meetingID: meetingID)
        }
    }

    public func saveSpeakerAlias(originalLabel: String, alias: String) {
        guard let meetingID = workspace?.meeting.id else { return }
        perform {
            try database.saveSpeakerAlias(
                meetingID: meetingID,
                originalLabel: originalLabel,
                alias: alias
            )
            loadWorkspace(meetingID: meetingID)
        }
    }

    public func clearSpeakerAlias(originalLabel: String) {
        guard let meetingID = workspace?.meeting.id else { return }
        perform {
            try database.clearSpeakerAlias(
                meetingID: meetingID,
                originalLabel: originalLabel
            )
            loadWorkspace(meetingID: meetingID)
        }
    }

    public func retrieveAskEvidence(question: String, scope: AskScope) {
        activeAskOperationID = nil
        pendingExternalAsk = nil
        askEvidence = []
        let cleaned = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            askAnswer = nil
            askPhase = .idle
            return
        }
        askPhase = .retrieving
        askAnswer = nil
        perform {
            askEvidence = try database.retrieveEvidence(question: cleaned, scope: scope)
            askPhase = askEvidence.isEmpty ? .insufficient : .generating
        }
    }

    public func answerQuestion(
        question: String,
        scope: AskScope
    ) async {
        retrieveAskEvidence(question: question, scope: scope)
        guard !askEvidence.isEmpty else { return }
        let configuration = askConfiguration()
        let destination = ExternalAskDestination(configuration: configuration)
        if configuration.isExternal,
           !confirmedExternalAskDestinations.contains(destination) {
            pendingExternalAsk = PendingExternalAsk(
                question: question,
                evidence: askEvidence,
                configuration: configuration
            )
            askPhase = .confirming(configuration.provider.title)
            return
        }
        await generateAskAnswer(
            question: question,
            evidence: askEvidence,
            configuration: configuration
        )
    }

    public func confirmExternalAsk() async {
        guard let pendingExternalAsk else { return }
        self.pendingExternalAsk = nil
        confirmedExternalAskDestinations.insert(
            ExternalAskDestination(configuration: pendingExternalAsk.configuration)
        )
        askEvidence = pendingExternalAsk.evidence
        await generateAskAnswer(
            question: pendingExternalAsk.question,
            evidence: pendingExternalAsk.evidence,
            configuration: pendingExternalAsk.configuration
        )
    }

    private func generateAskAnswer(
        question: String,
        evidence: [AskEvidence],
        configuration: AIConfiguration
    ) async {
        let operationID = UUID()
        activeAskOperationID = operationID
        askPhase = .generating
        do {
            let answer = try await askAnswerer.answer(
                question: question,
                evidence: evidence,
                configuration: configuration
            )
            guard activeAskOperationID == operationID, !Task.isCancelled else { return }
            askAnswer = answer
            askPhase = askAnswer?.claims.isEmpty == false ? .answered : .insufficient
        } catch {
            guard activeAskOperationID == operationID else { return }
            if Task.isCancelled || error is CancellationError {
                cancelAsk()
                return
            }
            let message = "Atrium could not answer this question. Check your model settings and try again."
            askPhase = .failed(message)
            report(
                error,
                operation: "ask_generate",
                userMessage: message,
                context: "provider=\(configuration.provider.rawValue) model=\(configuration.model)",
                showBanner: false
            )
        }
        if activeAskOperationID == operationID {
            activeAskOperationID = nil
        }
    }

    public func cancelAsk() {
        activeAskOperationID = nil
        pendingExternalAsk = nil
        askPhase = .idle
        askAnswer = nil
        askEvidence = []
    }

    public func beginSummaryGeneration(customPrompt: String = "") {
        cancelSummary()
        summaryTask = Task { await generateSummary(customPrompt: customPrompt) }
    }

    public func cancelSummary() {
        summaryTask?.cancel()
        summaryTask = nil
        activeSummaryOperationID = nil
        isGeneratingSummary = false
    }

    private func generateSummary(customPrompt: String) async {
        guard let workspace else { return }
        let operationID = UUID()
        activeSummaryOperationID = operationID
        isGeneratingSummary = true
        defer {
            if activeSummaryOperationID == operationID {
                activeSummaryOperationID = nil
                summaryTask = nil
                isGeneratingSummary = false
            }
        }
        do {
            let language = try MeetingSummaryPreferenceStore.language(for: workspace.meeting)
            let markdown = try await intelligence.summarize(
                workspace.transcripts,
                language: language,
                customPrompt: customPrompt
            )
            guard activeSummaryOperationID == operationID, !Task.isCancelled else { return }
            try database.saveSummary(meetingID: workspace.meeting.id, markdown: markdown)
            loadWorkspace(meetingID: workspace.meeting.id)
        } catch {
            guard activeSummaryOperationID == operationID else { return }
            if Task.isCancelled || error is CancellationError { return }
            report(
                error,
                operation: "summary_generate",
                userMessage: "Atrium could not create the summary. Try again."
            )
        }
    }

    public func summaryLanguage(for meeting: Meeting) -> String {
        do {
            return try MeetingSummaryPreferenceStore.language(for: meeting) ?? "auto"
        } catch {
            report(
                error,
                operation: "summary_language_read",
                userMessage: "Atrium could not read the summary language. The automatic setting will be used."
            )
            return "auto"
        }
    }

    public func saveSummaryLanguage(_ language: String, for meeting: Meeting) {
        do {
            try MeetingSummaryPreferenceStore.save(language, for: meeting)
            errorMessage = nil
        } catch {
            report(
                error,
                operation: "summary_language_save",
                userMessage: "Atrium could not save the summary language. Try again."
            )
        }
    }

    public func togglePlayback(for meeting: Meeting) {
        do {
            guard let audioURL = MeetingAudioFiles.primary(in: meeting.folderPath) else {
                throw DatabaseError.invalidData("Atrium could not find an audio file for this meeting.")
            }
            if playbackMeetingID != meeting.id {
                try playback.load(audioURL)
                playbackMeetingID = meeting.id
                playbackDuration = playback.duration
                playbackTime = 0
            }
            playback.toggle()
            isPlaying = playback.isPlaying
            startPlaybackTimer()
        } catch {
            report(
                error,
                operation: "audio_playback_toggle",
                userMessage: "Atrium could not play this recording. Check that the audio file is still available."
            )
        }
    }

    public func play(_ meeting: Meeting, at time: TimeInterval) {
        do {
            guard let audioURL = MeetingAudioFiles.primary(in: meeting.folderPath) else {
                throw DatabaseError.invalidData("Atrium could not find an audio file for this meeting.")
            }
            if playbackMeetingID != meeting.id {
                try playback.load(audioURL)
                playbackMeetingID = meeting.id
                playbackDuration = playback.duration
            }
            playback.seek(to: time)
            playbackTime = playback.currentTime
            if !playback.isPlaying { playback.toggle() }
            isPlaying = playback.isPlaying
            startPlaybackTimer()
        } catch {
            report(
                error,
                operation: "audio_playback_seek",
                userMessage: "Atrium could not play this citation. Check that the audio file is still available."
            )
        }
    }

    public func openCitation(_ evidence: AskEvidence) {
        highlightedTranscriptID = evidence.transcriptID
        select(.meeting(evidence.meetingID))
    }

    public func clearTranscriptHighlight() {
        highlightedTranscriptID = nil
    }

    public func seekPlayback(to value: TimeInterval) {
        playback.seek(to: value)
        playbackTime = playback.currentTime
    }

    public func beginRetranscription() {
        guard recordingState == .idle,
              !isDictating,
              !isPreparingDictation,
              !isProcessingDictation,
              !isImportingAudio,
              !isRetranscribing,
              retranscriptionTask == nil else { return }
        retranscriptionTask = Task { await retranscribeCurrentMeeting() }
    }

    public func cancelRetranscription() {
        retranscriptionTask?.cancel()
        retranscriptionTask = nil
        activeRetranscriptionOperationID = nil
        transcription.cancel()
        isRetranscribing = false
    }

    private func retranscribeCurrentMeeting() async {
        guard let workspace,
              let audioURL = MeetingAudioFiles.primary(in: workspace.meeting.folderPath) else {
            errorMessage = "Atrium could not find an audio file for this meeting."
            retranscriptionTask = nil
            isRetranscribing = false
            return
        }
        let operationID = UUID()
        activeRetranscriptionOperationID = operationID
        isRetranscribing = true
        defer {
            if activeRetranscriptionOperationID == operationID {
                activeRetranscriptionOperationID = nil
                retranscriptionTask = nil
                isRetranscribing = false
            }
        }
        do {
            let recognized = try await transcription.transcribe(
                audioURL: audioURL,
                localeIdentifier: Self.transcriptionLocaleIdentifier
            )
            guard activeRetranscriptionOperationID == operationID,
                  !Task.isCancelled else { return }
            let segments = Self.transcriptSegments(
                from: recognized,
                meetingID: workspace.meeting.id
            )
            let labelled = (try? await voiceCluster.label(segments, audioURL: audioURL)) ?? segments
            guard activeRetranscriptionOperationID == operationID,
                  !Task.isCancelled else { return }
            try database.replaceTranscripts(meetingID: workspace.meeting.id, with: labelled)
            loadWorkspace(meetingID: workspace.meeting.id)
        } catch {
            guard activeRetranscriptionOperationID == operationID else { return }
            if Task.isCancelled || error is CancellationError { return }
            report(
                error,
                operation: "meeting_retranscribe",
                userMessage: "Atrium could not transcribe this recording. Check Speech Recognition access and try again."
            )
        }
    }

    public func startDictation() async {
        guard !isDictating,
              !isPreparingDictation,
              !isProcessingDictation,
              !isStartingRecording,
              !isRetranscribing,
              recordingState == .idle else { return }
        isPreparingDictation = true
        defer { isPreparingDictation = false }
        guard await dictationRecorder.requestPermission() else {
            let error = AudioRecordingError.permissionDenied
            report(
                error,
                operation: "dictation_start",
                userMessage: "Atrium could not start Dictation. Check Microphone access and try again."
            )
            return
        }
        guard !Task.isCancelled else { return }
        do {
            let folder = FileManager.default.temporaryDirectory
                .appendingPathComponent("Atrium-Dictation", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("dictation-\(UUID().uuidString).wav")
            try dictationRecorder.start(
                at: url,
                localeIdentifier: Self.transcriptionLocaleIdentifier,
                inputDeviceID: UserDefaults.standard.string(forKey: "notive.dictation.microphone") ?? ""
            ) { _ in }
            dictationText = ""
            isDictating = true
        } catch {
            guard !(error is CancellationError) else { return }
            report(
                error,
                operation: "dictation_transcribe",
                userMessage: "Atrium could not transcribe the dictation. Try again."
            )
        }
    }

    public func stopDictation() async {
        guard isDictating else { return }
        let operationID = UUID()
        activeDictationOperationID = operationID
        isDictating = false
        isProcessingDictation = true
        defer {
            if activeDictationOperationID == operationID {
                activeDictationOperationID = nil
                isProcessingDictation = false
            }
        }
        do {
            let url = try dictationRecorder.stop()
            defer { try? FileManager.default.removeItem(at: url) }
            let segments = try await transcription.transcribe(
                audioURL: url,
                localeIdentifier: Self.transcriptionLocaleIdentifier
            )
            guard activeDictationOperationID == operationID, !Task.isCancelled else { return }
            dictationText = segments.map(\.text).joined(separator: " ")
        } catch {
            guard activeDictationOperationID == operationID else { return }
            if Task.isCancelled || error is CancellationError { return }
            report(
                error,
                operation: "dictation_transcribe",
                userMessage: "Atrium could not transcribe the dictation. Try again."
            )
        }
    }

    public func cancelDictation() {
        dictationRecorder.cancel()
        transcription.cancel()
        activeDictationOperationID = nil
        isDictating = false
        isPreparingDictation = false
        isProcessingDictation = false
    }

    public func clearError() {
        errorMessage = nil
    }

    public func startRecording(title: String = "New meeting") async {
        guard case .idle = recordingState,
              !isStartingRecording,
              !isDictating,
              !isPreparingDictation,
              !isProcessingDictation,
              !isRetranscribing else { return }
        isStartingRecording = true
        defer { isStartingRecording = false }
        guard await recorder.requestPermission() else {
            let error = AudioRecordingError.permissionDenied
            let message = "Microphone access is required. Allow access in System Settings, then try again."
            recordingState = .failed(message)
            report(error, operation: "recording_authorize", userMessage: message)
            return
        }
        guard !Task.isCancelled else { return }
        _ = await transcription.requestPermission()
        guard !Task.isCancelled else { return }

        var createdMeeting: Meeting?
        var createdFolder: URL?
        do {
            let folder = try makeMeetingFolder(title: title)
            createdFolder = folder
            let meeting = try database.createMeeting(title: title, folderPath: folder.path)
            createdMeeting = meeting
            try MeetingSummaryPreferenceStore.applyDefault(to: meeting)
            let microphoneURL = folder.appendingPathComponent("microphone.wav")
            try recorder.start(
                at: microphoneURL,
                localeIdentifier: Self.transcriptionLocaleIdentifier,
                inputDeviceID: UserDefaults.standard.string(forKey: "notive.recording.microphone") ?? ""
            ) { [weak self] recognized in
                guard let self else { return }
                self.liveTranscriptSegments = Self.transcriptSegments(
                    from: recognized,
                    meetingID: meeting.id,
                    speaker: "mic"
                )
            }
            if Self.systemAudioEnabled {
                do {
                    try await systemAudioCapture.start(
                        at: folder.appendingPathComponent("system-audio.m4a")
                    )
                    isCapturingSystemAudio = true
                } catch {
                    isCapturingSystemAudio = false
                    let message = "Recording started with microphone audio only. Check Screen Recording access before the next meeting."
                    errorMessage = message
                    DiagnosticLogger.partialFailure(
                        operation: "system_audio_start",
                        error: error,
                        context: "meeting_id=\(meeting.id) fallback=microphone_only"
                    )
                }
            }
            try Task.checkCancellation()
            activeRecordingMeetingID = meeting.id
            recordingState = .recording
            selection = .meeting(meeting.id)
            reloadMeetings()
            loadWorkspace(meetingID: meeting.id)
            startMetering()
            Task {
                await notifications.send(
                    title: "Recording started",
                    body: meeting.title,
                    preferenceKey: "notive.notifications.recording",
                    defaultEnabled: false
                )
            }
        } catch {
            recorder.cancel()
            await systemAudioCapture.cancel()
            isCapturingSystemAudio = false
            if let createdMeeting {
                try? database.deleteMeeting(id: createdMeeting.id)
            }
            if let createdFolder {
                try? FileManager.default.removeItem(at: createdFolder)
            }
            if error is CancellationError {
                recordingState = .idle
                errorMessage = nil
            } else {
                let message = "Atrium could not start the recording. Check Microphone access and the save location, then try again."
                recordingState = .failed(message)
                report(error, operation: "recording_start", userMessage: message)
            }
        }
    }

    public func pauseRecording() {
        guard case .recording = recordingState else { return }
        recorder.pause()
        systemAudioCapture.pause()
        recordingState = .paused
        Task {
                await notifications.send(
                    title: "Recording paused",
                    body: "Resume when you are ready.",
                preferenceKey: "notive.notifications.recording",
                defaultEnabled: false
            )
        }
    }

    public func resumeRecording() {
        guard case .paused = recordingState else { return }
        recorder.resume()
        systemAudioCapture.resume()
        recordingState = .recording
        Task {
                await notifications.send(
                    title: "Recording resumed",
                    body: "The meeting recording is active.",
                preferenceKey: "notive.notifications.recording",
                defaultEnabled: false
            )
        }
    }

    public func stopRecording() async {
        guard recordingState == .recording || recordingState == .paused,
              let meetingID = activeRecordingMeetingID else { return }
        recordingState = .transcribing
        stopMetering()
        do {
            let microphoneURL = try recorder.stop()
            let systemAudioURL: URL?
            if isCapturingSystemAudio {
                do {
                    systemAudioURL = try await systemAudioCapture.stop()
                } catch {
                    systemAudioURL = nil
                    let message = "The microphone recording was saved, but system audio was not."
                    errorMessage = message
                    DiagnosticLogger.partialFailure(
                        operation: "system_audio_stop",
                        error: error,
                        context: "meeting_id=\(meetingID) fallback=microphone_only"
                    )
                }
                isCapturingSystemAudio = false
            } else {
                systemAudioURL = nil
            }
            Task {
                await notifications.send(
                    title: "Recording saved",
                    body: "Atrium is preparing the transcript.",
                    preferenceKey: "notive.notifications.recording",
                    defaultEnabled: false
                )
            }
            if let meeting = try database.fetchMeeting(id: meetingID),
               let folderPath = meeting.folderPath {
                _ = try await audioMixer.mix(
                    microphoneURL: microphoneURL,
                    systemAudioURL: systemAudioURL,
                    outputURL: URL(fileURLWithPath: folderPath).appendingPathComponent("audio.m4a")
                )
            }
            let recognized = try await transcription.transcribe(
                audioURL: microphoneURL,
                localeIdentifier: Self.transcriptionLocaleIdentifier
            )
            var segments = Self.transcriptSegments(
                from: recognized,
                meetingID: meetingID,
                speaker: "mic"
            )
            segments = (try? await voiceCluster.label(segments, audioURL: microphoneURL)) ?? segments
            if let systemAudioURL,
               let systemRecognized = try? await transcription.transcribe(
                audioURL: systemAudioURL,
                localeIdentifier: Self.transcriptionLocaleIdentifier
               ) {
                segments.append(contentsOf: Self.transcriptSegments(
                    from: systemRecognized,
                    meetingID: meetingID,
                    speaker: "system"
                ))
                segments.sort { ($0.audioStartTime ?? 0) < ($1.audioStartTime ?? 0) }
            }
            try database.insertTranscripts(segments)
            liveTranscriptSegments = []
            await generateAutomaticSummary(meetingID: meetingID, segments: segments)
            if !Self.savesRecordedAudio,
               let meeting = try database.fetchMeeting(id: meetingID),
               let folderPath = meeting.folderPath {
                try RecordingPreferenceStore.removeRecordedAudio(
                    from: URL(fileURLWithPath: folderPath, isDirectory: true)
                )
            }
            recordingState = .idle
            activeRecordingMeetingID = nil
            loadWorkspace(meetingID: meetingID)
            Task {
                await notifications.send(
                    title: "Transcript ready",
                    body: "Open the meeting to review it.",
                    preferenceKey: "notive.notifications.transcription",
                    defaultEnabled: true
                )
            }
        } catch {
            recorder.cancel()
            await systemAudioCapture.cancel()
            isCapturingSystemAudio = false
            activeRecordingMeetingID = nil
            liveTranscriptSegments = []
            let message = "Atrium could not finish this recording. The saved audio remains on this Mac."
            recordingState = .failed(message)
            report(error, operation: "recording_finish", userMessage: message)
        }
    }

    public func cancelRecording() async {
        recorder.cancel()
        liveTranscriptSegments = []
        await systemAudioCapture.cancel()
        isCapturingSystemAudio = false
        stopMetering()
        if let meetingID = activeRecordingMeetingID {
            try? database.deleteMeeting(id: meetingID)
        }
        activeRecordingMeetingID = nil
        recordingState = .idle
        reloadMeetings()
        selection = .home
    }

    public func resetRecordingError() {
        if case .failed = recordingState {
            recordingState = .idle
        }
    }

    public func importAudio(from sourceURL: URL) async {
        guard case .idle = recordingState,
              !isStartingRecording,
              !isDictating,
              !isPreparingDictation,
              !isProcessingDictation,
              !isRetranscribing else { return }
        isLoading = true
        isImportingAudio = true
        recordingState = .transcribing
        importCancellationRequested = false
        var createdMeeting: Meeting?
        var createdFolder: URL?
        defer {
            isLoading = false
            isImportingAudio = false
            importCancellationRequested = false
        }
        do {
            let title = sourceURL.deletingPathExtension().lastPathComponent
            let folder = try makeMeetingFolder(title: title)
            createdFolder = folder
            let destination = folder.appendingPathComponent(sourceURL.lastPathComponent)
            try await audioImporter.copy(from: sourceURL, to: destination)
            if importCancellationRequested { throw CancellationError() }
            let meeting = try database.createMeeting(title: title, folderPath: folder.path)
            createdMeeting = meeting
            try MeetingSummaryPreferenceStore.applyDefault(to: meeting)
            selection = .meeting(meeting.id)
            reloadMeetings()

            let recognized = try await transcription.transcribe(
                audioURL: destination,
                localeIdentifier: Self.transcriptionLocaleIdentifier
            )
            if importCancellationRequested { throw CancellationError() }
            let segments = Self.transcriptSegments(from: recognized, meetingID: meeting.id)
            let labelled = (try? await voiceCluster.label(segments, audioURL: destination)) ?? segments
            if importCancellationRequested { throw CancellationError() }
            try database.insertTranscripts(labelled)
            await generateAutomaticSummary(meetingID: meeting.id, segments: labelled)
            if importCancellationRequested { throw CancellationError() }
            recordingState = .idle
            loadWorkspace(meetingID: meeting.id)
            Task {
                await notifications.send(
                    title: "Imported transcript ready",
                    body: meeting.title,
                    preferenceKey: "notive.notifications.transcription",
                    defaultEnabled: true
                )
            }
        } catch {
            if let createdMeeting {
                try? database.deleteMeeting(id: createdMeeting.id)
            }
            if let createdFolder {
                try? FileManager.default.removeItem(at: createdFolder)
            }
            selection = .home
            workspace = nil
            reloadMeetings()
            if error is CancellationError || importCancellationRequested {
                recordingState = .idle
                errorMessage = nil
            } else {
                let message = "Atrium could not import this audio. Choose a supported audio file and try again."
                recordingState = .failed(message)
                report(error, operation: "audio_import", userMessage: message)
            }
        }
    }

    public func cancelImport() {
        guard isImportingAudio else { return }
        importCancellationRequested = true
        transcription.cancel()
    }

    private func perform(_ work: () throws -> Void) {
        isLoading = true
        defer { isLoading = false }
        do {
            try work()
        } catch {
            let message = "Atrium could not update local data. Try the action again."
            errorMessage = message
            DiagnosticLogger.failure(operation: "local_data_update", error: error)
            if case .retrieving = askPhase {
                askPhase = .failed("Atrium could not search the meeting transcripts. Try again.")
            }
        }
    }

    private func generateAutomaticSummary(
        meetingID: String,
        segments: [TranscriptSegment]
    ) async {
        guard UserDefaults.standard.bool(forKey: "notive.summary.automatic") else { return }
        do {
            guard let meeting = try database.fetchMeeting(id: meetingID) else { return }
            let language = try MeetingSummaryPreferenceStore.language(for: meeting)
            let markdown = try await intelligence.summarize(segments, language: language)
            try database.saveSummary(meetingID: meetingID, markdown: markdown)
        } catch {
            let message = "The transcript is ready, but Atrium could not create the automatic summary. You can try again from the meeting."
            errorMessage = message
            DiagnosticLogger.partialFailure(
                operation: "automatic_summary_generate",
                error: error,
                context: "meeting_id=\(meetingID) transcript_status=ready"
            )
        }
    }

    private func startMetering() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.recordingElapsed = self.recorder.currentTime
                self.recordingPower = self.recorder.averagePower
            }
        }
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
        recordingElapsed = 0
        recordingPower = -80
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        guard isPlaying else { return }
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.playbackTime = self.playback.currentTime
                self.isPlaying = self.playback.isPlaying
                if !self.isPlaying {
                    self.playbackTimer?.invalidate()
                    self.playbackTimer = nil
                }
            }
        }
    }

    private func makeMeetingFolder(title: String) throws -> URL {
        let base = recordingsFolder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let sanitized = title
            .map { character -> Character in
                "/\\:*?\"<>|".contains(character) || character.isNewline ? "_" : character
            }
            .reduce(into: "") { $0.append($1) }
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let folder = base.appendingPathComponent(
            "\(sanitized.isEmpty ? "Meeting" : sanitized)_\(formatter.string(from: .now))",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    static func transcriptSegments(
        from recognized: [SpeechRecognitionSegment],
        meetingID: String,
        speaker: String = "audio"
    ) -> [TranscriptSegment] {
        Self.utterances(from: recognized).map { utterance in
            TranscriptSegment(
                id: "segment-\(UUID().uuidString.lowercased())",
                meetingID: meetingID,
                text: utterance.text,
                timestamp: String(format: "%02d:%02d", Int(utterance.startTime) / 60, Int(utterance.startTime) % 60),
                audioStartTime: utterance.startTime,
                audioEndTime: utterance.startTime + utterance.duration,
                duration: utterance.duration,
                speaker: speaker
            )
        }
    }

    private static func utterances(
        from segments: [SpeechRecognitionSegment]
    ) -> [SpeechRecognitionSegment] {
        var result: [SpeechRecognitionSegment] = []
        for segment in segments.sorted(by: { $0.startTime < $1.startTime }) {
            guard let previous = result.last else {
                result.append(segment)
                continue
            }
            let previousEnd = previous.startTime + previous.duration
            let combinedDuration = segment.startTime + segment.duration - previous.startTime
            if segment.startTime - previousEnd <= 0.85, combinedDuration <= 12 {
                result[result.count - 1] = SpeechRecognitionSegment(
                    text: previous.text + " " + segment.text,
                    startTime: previous.startTime,
                    duration: combinedDuration
                )
            } else {
                result.append(segment)
            }
        }
        return result
    }

    private static var systemAudioEnabled: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "notive.recording.system-audio") == nil { return true }
        return defaults.bool(forKey: "notive.recording.system-audio")
    }

    private static var transcriptionLocaleIdentifier: String {
        let stored = UserDefaults.standard.string(forKey: "notive.transcription.language") ?? "system"
        return stored == "system" || stored == "auto" ? Locale.current.identifier : stored
    }

    private static var savesRecordedAudio: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: RecordingPreferenceStore.savesAudioKey) == nil { return true }
        return defaults.bool(forKey: RecordingPreferenceStore.savesAudioKey)
    }

    private func report(
        _ error: Error,
        operation: String,
        userMessage: String,
        context: String = "none",
        showBanner: Bool = true
    ) {
        DiagnosticLogger.failure(operation: operation, error: error, context: context)
        if showBanner { errorMessage = userMessage }
        Task {
            await notifications.send(
                title: "Atrium could not complete the action",
                body: userMessage,
                preferenceKey: "notive.notifications.errors",
                defaultEnabled: true
            )
        }
    }
}

private struct PendingExternalAsk: Sendable {
    let question: String
    let evidence: [AskEvidence]
    let configuration: AIConfiguration
}

private struct ExternalAskDestination: Hashable {
    let provider: AIProvider
    let endpoint: String

    init(configuration: AIConfiguration) {
        provider = configuration.provider
        endpoint = configuration.endpoint.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
