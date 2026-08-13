import AppKit
import ApplicationServices
import CoreGraphics
import NotiveCore
import Speech
import SwiftUI
import UserNotifications

struct SettingsView: View {
    let store: AppStore?
    let updater: UpdaterService
    @AppStorage("ubundi-meet-brand-theme") private var themeRaw = BrandTheme.firstMotive.rawValue
    @AppStorage("notive.appearance") private var appearance = "system"
    @Environment(\.colorScheme) private var colorScheme

    private var theme: BrandTheme {
        BrandTheme(rawValue: themeRaw) ?? .firstMotive
    }

    var body: some View {
        TabView {
            GeneralSettingsView(store: store, updater: updater)
                .tabItem { Label("General", systemImage: "gearshape") }
            PermissionSettingsView()
                .tabItem { Label("Permissions", systemImage: "hand.raised") }
            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintpalette") }
            RecordingSettingsView()
                .tabItem { Label("Recording", systemImage: "record.circle") }
            DictationSettingsView()
                .tabItem { Label("Dictation", systemImage: "waveform") }
            TranscriptionSettingsView()
                .tabItem { Label("Transcription", systemImage: "text.bubble") }
            SummarySettingsView()
                .tabItem { Label("Summary", systemImage: "sparkles") }
            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .environment(\.brandTheme, theme)
        .tint(BrandPalette.palette(for: theme, colorScheme: colorScheme).accent)
        .preferredColorScheme(
            theme == .firstMotive
                ? .dark
                : appearance == "light" ? .light : appearance == "dark" ? .dark : nil
        )
        .frame(width: 760, height: 580)
        .scenePadding()
    }
}

private struct PermissionSettingsView: View {
    @State private var microphone = "Checking"
    @State private var speech = "Checking"
    @State private var screenRecording = "Checking"
    @State private var notifications = "Checking"
    @State private var accessibility = "Checking"

    var body: some View {
        Form {
            Section("Audio and transcription") {
                PermissionRow(title: "Microphone", status: microphone) {
                    Task {
                        if MicrophoneAuthorization.currentStatus == .notDetermined {
                            _ = await MicrophoneAuthorization.request()
                        } else {
                            openPrivacyPane("Privacy_Microphone")
                        }
                        await refresh()
                    }
                }
                PermissionRow(title: "Speech Recognition", status: speech) {
                    Task {
                        if SFSpeechRecognizer.authorizationStatus() == .notDetermined {
                            _ = await SpeechAuthorization.request()
                        } else {
                            openPrivacyPane("Privacy_SpeechRecognition")
                        }
                        await refresh()
                    }
                }
                PermissionRow(title: "Screen Recording", status: screenRecording) {
                    if !CGRequestScreenCaptureAccess() {
                        openPrivacyPane("Privacy_ScreenCapture")
                    }
                    Task { await refresh() }
                }
            }
            Section("System integration") {
                PermissionRow(title: "Notifications", status: notifications) {
                    Task {
                        let center = UNUserNotificationCenter.current()
                        let settings = await center.notificationSettings()
                        if settings.authorizationStatus == .notDetermined {
                            _ = try? await center.requestAuthorization(options: [.alert, .sound])
                        } else {
                            openNotificationsSettings()
                        }
                        await refresh()
                    }
                }
                PermissionRow(title: "Accessibility", status: accessibility) {
                    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
                    if !AXIsProcessTrustedWithOptions(options) {
                        openPrivacyPane("Privacy_Accessibility")
                    }
                    Task { await refresh() }
                }
            }
        }
        .formStyle(.grouped)
        .task { await refresh() }
    }

    private func refresh() async {
        microphone = Self.label(MicrophoneAuthorization.currentStatus)
        speech = Self.label(SFSpeechRecognizer.authorizationStatus())
        screenRecording = CGPreflightScreenCaptureAccess() ? "Allowed" : "Not allowed"
        accessibility = AXIsProcessTrusted() ? "Allowed" : "Not allowed"
        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        notifications = Self.label(notificationSettings.authorizationStatus)
    }

    private func openPrivacyPane(_ pane: String) {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?\(pane)"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    private func openNotificationsSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    private static func label(_ status: MicrophoneAuthorizationStatus) -> String {
        switch status {
        case .authorized: "Allowed"
        case .denied: "Not allowed"
        case .notDetermined: "Not requested"
        }
    }

    private static func label(_ status: SFSpeechRecognizerAuthorizationStatus) -> String {
        switch status {
        case .authorized: "Allowed"
        case .denied, .restricted: "Not allowed"
        case .notDetermined: "Not requested"
        @unknown default: "Unknown"
        }
    }

    private static func label(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized, .provisional, .ephemeral: "Allowed"
        case .denied: "Not allowed"
        case .notDetermined: "Not requested"
        @unknown default: "Unknown"
        }
    }
}

private struct PermissionRow: View {
    let title: String
    let status: String
    let request: () -> Void

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(status)
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(title) status")
                .accessibilityValue(status)
            if status != "Allowed" {
                Button("Request", action: request)
                    .accessibilityLabel("Request \(title) access")
            }
        }
    }
}

private struct GeneralSettingsView: View {
    let store: AppStore?
    @Bindable var updater: UpdaterService
    @AppStorage("notive.notifications.recording") private var recordingNotifications = false
    @AppStorage("notive.notifications.transcription") private var transcriptionNotifications = true
    @AppStorage("notive.notifications.errors") private var errorNotifications = true
    @AppStorage("notive.notifications.sound") private var notificationSound = true
    @AppStorage("notive.notifications.paused") private var notificationsPaused = false
    @AppStorage(RecordingPreferenceStore.folderKey) private var recordingsFolder = ""
    @State private var notificationTestStatus: String?
    private let notificationService = NotificationService()

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Recording activity", isOn: $recordingNotifications)
                Toggle("Transcription complete", isOn: $transcriptionNotifications)
                Toggle("Problems that need attention", isOn: $errorNotifications)
                Toggle("Notification sound", isOn: $notificationSound)
                Toggle("Pause non-critical notifications", isOn: $notificationsPaused)
                HStack {
                    Button("Send test notification") {
                        Task {
                            let queued = await notificationService.sendTest()
                            notificationTestStatus = queued
                                ? "Test notification queued"
                                : "Allow notifications to run this test."
                        }
                    }
                    if let notificationTestStatus {
                        Text(notificationTestStatus)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("Updates") {
                Toggle("Automatic update checks", isOn: $updater.automaticallyChecksForUpdates)
                HStack {
                    Button(updater.primaryActionTitle, action: performUpdateAction)
                        .disabled(!updater.canPerformPrimaryAction)
                    if case .checking = updater.phase {
                        ProgressView()
                            .controlSize(.small)
                    } else if case .installing = updater.phase {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                if let installationBlockReason = updater.installationBlockReason,
                   updater.updateNoticeVersion != nil {
                    Text(installationBlockReason)
                        .foregroundStyle(.secondary)
                }
                Text(updater.statusText)
                    .foregroundStyle(statusColor)
            }
            Section("Data on this Mac") {
                LocalPathRow(
                    title: "Meeting data",
                    url: applicationSupportURL
                )
                LocalPathRow(
                    title: "Recordings",
                    url: recordingFolderURL
                )
            }
            if let store, let installation = store.previousInstallation {
                Section("Earlier installation") {
                    LabeledContent("Meetings found") {
                        Text("\(installation.importableMeetingCount)")
                    }
                    LocalPathRow(title: "Folder", url: installation.applicationSupportURL)
                    HStack {
                        Button("Restore Meetings") {
                            Task { await store.restorePreviousInstallation() }
                        }
                        .disabled(store.isRestoringPreviousData)
                        if store.isRestoringPreviousData {
                            ProgressView().controlSize(.small)
                        }
                        Spacer()
                    }
                    Text("Meetings you already have stay as they are.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let message = store.previousInstallationRestoreError {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var statusColor: Color {
        if case .failed = updater.phase { .red } else { .secondary }
    }

    private func performUpdateAction() {
        Task { await updater.performPrimaryAction() }
    }

    private var applicationSupportURL: URL {
        (try? SQLiteDatabase.defaultDatabaseURL().deletingLastPathComponent())
            ?? FileManager.default.homeDirectoryForCurrentUser
    }

    private var recordingFolderURL: URL {
        recordingsFolder.isEmpty
            ? RecordingPreferenceStore.defaultFolder
            : URL(fileURLWithPath: recordingsFolder, isDirectory: true)
    }
}

private struct AppearanceSettingsView: View {
    @AppStorage("ubundi-meet-brand-theme") private var themeRaw = BrandTheme.firstMotive.rawValue
    @AppStorage("notive.app-icon") private var iconRaw = BrandTheme.firstMotive.rawValue
    @AppStorage("notive.appearance") private var appearance = "system"

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Mode", selection: $appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }
            Section("Interface theme") {
                HStack(spacing: 12) {
                    ForEach(BrandTheme.allCases) { theme in
                        ThemeChoice(
                            theme: theme,
                            isSelected: themeRaw == theme.rawValue
                        ) {
                            themeRaw = theme.rawValue
                        }
                    }
                }
                Text(
                    themeRaw == BrandTheme.firstMotive.rawValue
                        ? "First Motive always uses its dark purple theme."
                        : "Ubundi follows your macOS light or dark appearance and uses navy accents."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Section("App icon") {
                Picker("Icon", selection: $iconRaw) {
                    ForEach(BrandTheme.allCases) { theme in
                        Text(theme.title).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: iconRaw) { _, value in
                    AppIconService.apply(BrandTheme(rawValue: value) ?? .firstMotive)
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct ThemeChoice: View {
    @Environment(\.brandTheme) private var activeTheme
    @Environment(\.colorScheme) private var colorScheme
    let theme: BrandTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                BrandMarkView(size: 36)
                    .environment(\.brandTheme, theme)
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.title)
                        .font(.headline)
                    Text(theme == .ubundi ? "Light · Navy" : "Dark · Purple")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? palette.accent : Color.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(.quaternary.opacity(isSelected ? 0.75 : 0.3), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? palette.accent : Color.secondary.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: activeTheme, colorScheme: colorScheme)
    }
}

private struct RecordingSettingsView: View {
    @AppStorage(RecordingPreferenceStore.savesAudioKey) private var savesAudio = true
    @AppStorage(RecordingPreferenceStore.folderKey) private var recordingFolder = ""
    @AppStorage("notive.notifications.recording") private var recordingNotification = false
    @AppStorage("notive.recording.microphone") private var microphone = ""
    @AppStorage("notive.recording.system-audio") private var systemAudio = true
    @State private var microphones: [AudioInputDevice] = []

    var body: some View {
        Form {
            Section("Audio files") {
                Toggle("Save audio recordings", isOn: $savesAudio)
                Toggle("Recording start notification", isOn: $recordingNotification)
                LabeledContent("Save location") {
                    Text(recordingFolderURL.lastPathComponent)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                HStack {
                    Button("Open Folder") { openRecordingFolder() }
                    Button("Choose Folder") { chooseRecordingFolder() }
                    if !recordingFolder.isEmpty {
                        Button("Use Default") { recordingFolder = "" }
                    }
                }
            }
            Section("Default audio devices") {
                Picker("Microphone", selection: $microphone) {
                    Text("System default").tag("")
                    ForEach(microphones) { device in
                        Text(device.name).tag(device.id)
                    }
                }
                Toggle("Capture system audio", isOn: $systemAudio)
            }
        }
        .formStyle(.grouped)
        .onAppear { microphones = AudioDeviceService.availableInputs() }
    }

    private var recordingFolderURL: URL {
        recordingFolder.isEmpty
            ? RecordingPreferenceStore.defaultFolder
            : URL(fileURLWithPath: recordingFolder, isDirectory: true)
    }

    private func openRecordingFolder() {
        try? FileManager.default.createDirectory(
            at: recordingFolderURL,
            withIntermediateDirectories: true
        )
        NSWorkspace.shared.open(recordingFolderURL)
    }

    private func chooseRecordingFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Recording Folder"
        panel.prompt = "Choose"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = recordingFolderURL
        guard panel.runModal() == .OK, let url = panel.url else { return }
        recordingFolder = url.path(percentEncoded: false)
    }
}

private struct DictationSettingsView: View {
    @AppStorage("notive.dictation.shortcut") private var shortcut = "Option + Space"
    @AppStorage("notive.dictation.microphone") private var microphone = ""
    @State private var microphones: [AudioInputDevice] = []

    var body: some View {
        Form {
            Section("Global shortcut") {
                Picker("Preset", selection: $shortcut) {
                    Text("Option + Space").tag("Option + Space")
                    Text("Command + Shift + D").tag("Command + Shift + D")
                }
            }
            Section("Dictation microphone") {
                Picker("Microphone", selection: $microphone) {
                    Text("System default").tag("")
                    ForEach(microphones) { device in
                        Text(device.name).tag(device.id)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { microphones = AudioDeviceService.availableInputs() }
    }
}

private struct TranscriptionSettingsView: View {
    @AppStorage("notive.transcription.language") private var language = "system"

    var body: some View {
        Form {
            Section("Speech model") {
                LabeledContent("Processing", value: "On this Mac")
            }
            Section("Language") {
                Picker("Transcription language", selection: $language) {
                    Text("System language").tag("system")
                    ForEach(Self.languages, id: \.code) { option in
                        Text(option.title).tag(option.code)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private static let languages: [(code: String, title: String)] = [
        ("en", "English"), ("zh", "Chinese"), ("de", "German"),
        ("es", "Spanish"), ("ru", "Russian"), ("ko", "Korean"),
        ("fr", "French"), ("ja", "Japanese"), ("pt", "Portuguese"),
        ("tr", "Turkish"), ("pl", "Polish"), ("ca", "Catalan"),
        ("nl", "Dutch"), ("ar", "Arabic"), ("sv", "Swedish"),
        ("it", "Italian"), ("id", "Indonesian"), ("hi", "Hindi"),
        ("fi", "Finnish"), ("vi", "Vietnamese"), ("he", "Hebrew"),
        ("uk", "Ukrainian"), ("el", "Greek"), ("ms", "Malay"),
        ("cs", "Czech"), ("ro", "Romanian"), ("da", "Danish"),
        ("hu", "Hungarian"), ("ta", "Tamil"), ("no", "Norwegian"),
        ("th", "Thai"), ("ur", "Urdu"), ("hr", "Croatian"),
        ("bg", "Bulgarian"), ("lt", "Lithuanian"),
    ]
}

private struct SummarySettingsView: View {
    @AppStorage("notive.summary.automatic") private var automatic = false
    @AppStorage("notive.summary.language") private var language = "auto"
    @AppStorage("notive.summary.template") private var template = SummaryTemplate.standard.rawValue
    @AppStorage("notive.ai.provider") private var providerRaw = AIProvider.apple.rawValue
    @AppStorage("notive.ai.model") private var model = AIConfiguration.defaultModel(for: .apple)
    @AppStorage("notive.ai.endpoint") private var endpoint = ""
    @State private var apiKey = ""
    @State private var saveMessage: String?
    @State private var availableModels: [String] = []
    @State private var modelActionMessage: String?
    @State private var isLoadingModels = false
    @State private var ollamaModelToPull = ""
    @State private var ollamaModelToDelete: String?
    private let modelService = ProviderModelService()

    private var provider: AIProvider {
        AIProvider(rawValue: providerRaw) ?? .apple
    }

    var body: some View {
        Form {
            Section("Auto Summary") {
                Toggle("Generate after a meeting stops", isOn: $automatic)
            }
            Section("Summary Language") {
                Picker("Language", selection: $language) {
                    Text("Auto").tag("auto")
                    ForEach(MeetingSummaryPreferenceStore.supportedLanguages) { language in
                        Text(language.title).tag(language.code)
                    }
                }
            }
            Section("Template") {
                Picker("Summary template", selection: $template) {
                    ForEach(SummaryTemplate.allCases) { template in
                        Text(template.title).tag(template.rawValue)
                    }
                }
            }
            Section("Model") {
                Picker("Provider", selection: $providerRaw) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.title).tag(provider.rawValue)
                    }
                }
                .onChange(of: providerRaw) { _, value in
                    let selected = AIProvider(rawValue: value) ?? .apple
                    model = AIConfiguration.defaultModel(for: selected)
                    endpoint = AIConfiguration.defaultEndpoint(for: selected)
                    apiKey = AIConfiguration.load().apiKey
                    availableModels = []
                    modelActionMessage = nil
                }
                if provider != .apple {
                    TextField("Model", text: $model)
                }
                if provider == .ollama || provider == .customOpenAI {
                    TextField("Endpoint", text: $endpoint)
                }
                if ![.apple, .ollama].contains(provider) {
                    SecureField("API key", text: $apiKey)
                }
                if provider.isExternal(endpoint: endpoint) {
                    Label(
                        "Summaries and transcript excerpts you approve will leave this Mac.",
                        systemImage: "network.badge.shield.half.filled"
                    )
                    .foregroundStyle(.secondary)
                }
                if provider != .apple {
                    HStack {
                        Button("Load Models") { Task { await loadModels() } }
                            .disabled(isLoadingModels)
                        Button("Test Connection") { Task { await testConnection() } }
                            .disabled(isLoadingModels)
                        if isLoadingModels { ProgressView().controlSize(.small) }
                    }
                    if !availableModels.isEmpty {
                        Picker("Available model", selection: $model) {
                            ForEach(availableModels, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                if provider == .ollama {
                    HStack {
                        TextField("Model to pull", text: $ollamaModelToPull)
                        Button("Pull") { Task { await pullOllamaModel() } }
                            .disabled(
                                isLoadingModels
                                    || ollamaModelToPull.trimmingCharacters(
                                        in: .whitespacesAndNewlines
                                    ).isEmpty
                            )
                    }
                    Button("Delete Selected Model", role: .destructive) {
                        ollamaModelToDelete = model
                    }
                    .disabled(model.isEmpty || isLoadingModels)
                }
                if let modelActionMessage {
                    Text(modelActionMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Save model settings") {
                    do {
                        try AIConfiguration(
                            provider: provider,
                            model: model,
                            endpoint: endpoint,
                            apiKey: apiKey
                        ).save()
                        saveMessage = "Model settings saved"
                    } catch {
                        DiagnosticLogger.failure(operation: "model_settings_save", error: error)
                        saveMessage = "Notive could not save the model settings. Check the values and try again."
                    }
                }
                if let saveMessage {
                    Text(saveMessage)
                        .font(.caption)
                        .foregroundStyle(saveMessage == "Model settings saved" ? Color.secondary : Color.red)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { apiKey = AIConfiguration.load().apiKey }
        .confirmationDialog(
            "Delete \(ollamaModelToDelete ?? "this model") from Ollama?",
            isPresented: Binding(
                get: { ollamaModelToDelete != nil },
                set: { if !$0 { ollamaModelToDelete = nil } }
            )
        ) {
            Button("Delete model", role: .destructive) {
                guard let name = ollamaModelToDelete else { return }
                ollamaModelToDelete = nil
                Task { await deleteOllamaModel(name: name) }
            }
            Button("Cancel", role: .cancel) { ollamaModelToDelete = nil }
        }
    }

    private var currentConfiguration: AIConfiguration {
        AIConfiguration(provider: provider, model: model, endpoint: endpoint, apiKey: apiKey)
    }

    private func loadModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        do {
            availableModels = try await modelService.listModels(configuration: currentConfiguration)
            modelActionMessage = "Found \(availableModels.count) model\(availableModels.count == 1 ? "" : "s")."
        } catch {
            DiagnosticLogger.failure(operation: "model_list", error: error)
            modelActionMessage = "Notive could not load models. Check the service address and try again."
        }
    }

    private func testConnection() async {
        await loadModels()
        if !availableModels.isEmpty {
            modelActionMessage = "Connection succeeded."
        }
    }

    private func pullOllamaModel() async {
        let name = ollamaModelToPull.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        isLoadingModels = true
        defer { isLoadingModels = false }
        do {
            try await modelService.pullOllamaModel(name: name, configuration: currentConfiguration)
            ollamaModelToPull = ""
            availableModels = try await modelService.listModels(configuration: currentConfiguration)
            model = name
            modelActionMessage = "Downloaded \(name)."
        } catch {
            DiagnosticLogger.failure(operation: "model_download", error: error)
            modelActionMessage = "Notive could not download the model. Check the service address and try again."
        }
    }

    private func deleteOllamaModel(name: String) async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        do {
            try await modelService.deleteOllamaModel(
                name: name,
                configuration: currentConfiguration
            )
            availableModels = try await modelService.listModels(configuration: currentConfiguration)
            if model == name {
                model = availableModels.first ?? AIConfiguration.defaultModel(for: .ollama)
            }
            modelActionMessage = "Deleted \(name)."
        } catch {
            DiagnosticLogger.failure(operation: "model_delete", error: error)
            modelActionMessage = "Notive could not delete the model. Check the service address and try again."
        }
    }
}

private extension AIProvider {
    func isExternal(endpoint: String) -> Bool {
        AIConfiguration(provider: self, model: "", endpoint: endpoint).isExternal
    }
}

private struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 14) {
            BrandMarkView(size: 74)
            Text("Notive")
                .font(.largeTitle.weight(.semibold))
            Text("Version \(AppVersion.current)")
                .foregroundStyle(.secondary)
            Text("A private meeting assistant that keeps your data on this Mac.")
                .multilineTextAlignment(.center)
            HStack {
                Button("License") { openResource("LICENSE", extension: "md") }
                Button("Notices") { openResource("NOTICE", extension: "md") }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openResource(_ name: String, extension fileExtension: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct LocalPathRow: View {
    let title: String
    let url: URL

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(title == "Meeting data" ? "Stored on this Mac" : url.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button("Open") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
