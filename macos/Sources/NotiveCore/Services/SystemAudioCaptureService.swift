@preconcurrency import AVFoundation
@preconcurrency import ScreenCaptureKit
import CoreMedia
import Foundation

public enum SystemAudioCaptureError: LocalizedError {
    case noDisplay
    case couldNotWrite
    case noActiveCapture
    case alreadyCapturing

    public var errorDescription: String? {
        switch self {
        case .noDisplay:
            "Notive could not find a display for system audio capture."
        case .couldNotWrite:
            "Notive could not create the system audio recording."
        case .noActiveCapture:
            "There is no active system audio capture to stop."
        case .alreadyCapturing:
            "System audio capture is already active."
        }
    }
}

@MainActor
public final class SystemAudioCaptureService {
    private let sampleQueue = DispatchQueue(label: "Notive.system-audio")
    private var stream: SCStream?
    private var sampleWriter: SystemAudioSampleWriter?
    private var outputURL: URL?
    private var isStarting = false

    public func start(at url: URL) async throws {
        guard stream == nil, !isStarting else { throw SystemAudioCaptureError.alreadyCapturing }
        isStarting = true
        defer { isStarting = false }
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        guard let display = content.displays.first else {
            throw SystemAudioCaptureError.noDisplay
        }

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: url)

        let writer = try AVAssetWriter(outputURL: url, fileType: .m4a)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 48_000,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        guard writer.canAdd(input) else {
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: url)
            throw SystemAudioCaptureError.couldNotWrite
        }
        writer.add(input)
        let sampleWriter = SystemAudioSampleWriter(writer: writer, input: input)

        let filter = SCContentFilter(
            display: display,
            excludingApplications: [],
            exceptingWindows: []
        )
        let configuration = SCStreamConfiguration()
        configuration.width = 2
        configuration.height = 2
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        configuration.showsCursor = false
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 48_000
        configuration.channelCount = 2

        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        do {
            try stream.addStreamOutput(sampleWriter, type: .audio, sampleHandlerQueue: sampleQueue)
            self.sampleWriter = sampleWriter
            outputURL = url
            self.stream = stream
            try await stream.startCapture()
        } catch {
            self.stream = nil
            self.sampleWriter = nil
            outputURL = nil
            sampleWriter.cancel()
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    public func pause() {
        sampleWriter?.setAcceptsSamples(false)
    }

    public func resume() {
        sampleWriter?.setAcceptsSamples(true)
    }

    public func stop() async throws -> URL {
        guard let stream, let sampleWriter, let outputURL else {
            throw SystemAudioCaptureError.noActiveCapture
        }
        self.stream = nil
        self.sampleWriter = nil
        self.outputURL = nil
        do {
            try await stream.stopCapture()
            try? stream.removeStreamOutput(sampleWriter, type: .audio)
        } catch {
            try? stream.removeStreamOutput(sampleWriter, type: .audio)
            sampleWriter.cancel()
            try? FileManager.default.removeItem(at: outputURL)
            throw error
        }
        let completed = await sampleWriter.finish()
        guard completed else {
            try? FileManager.default.removeItem(at: outputURL)
            throw SystemAudioCaptureError.couldNotWrite
        }
        return outputURL
    }

    public func cancel() async {
        let activeStream = stream
        let activeWriter = sampleWriter
        let activeOutputURL = outputURL
        stream = nil
        sampleWriter = nil
        outputURL = nil
        try? await activeStream?.stopCapture()
        if let activeStream, let activeWriter {
            try? activeStream.removeStreamOutput(activeWriter, type: .audio)
        }
        activeWriter?.cancel()
        if let activeOutputURL { try? FileManager.default.removeItem(at: activeOutputURL) }
    }
}

private final class SystemAudioSampleWriter: NSObject, SCStreamOutput, @unchecked Sendable {
    private struct State {
        var acceptsSamples = true
        var startedSession = false
        var isFinished = false
    }

    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let lock = NSLock()
    private var state = State()

    init(writer: AVAssetWriter, input: AVAssetWriterInput) {
        self.writer = writer
        self.input = input
    }

    func setAcceptsSamples(_ acceptsSamples: Bool) {
        lock.withLock {
            guard !state.isFinished else { return }
            state.acceptsSamples = acceptsSamples
        }
    }

    func finish() async -> Bool {
        let didStart = lock.withLock {
            guard !state.isFinished else { return false }
            state.isFinished = true
            guard state.startedSession else { return false }
            input.markAsFinished()
            return true
        }
        guard didStart else {
            writer.cancelWriting()
            return false
        }
        await writer.finishWriting()
        return writer.status == .completed
    }

    func cancel() {
        lock.withLock {
            guard !state.isFinished else { return }
            state.isFinished = true
            writer.cancelWriting()
        }
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .audio,
              sampleBuffer.isValid,
              CMSampleBufferDataIsReady(sampleBuffer) else { return }

        lock.withLock {
            guard state.acceptsSamples, !state.isFinished else { return }
            if !state.startedSession {
                guard writer.startWriting() else {
                    state.isFinished = true
                    return
                }
                writer.startSession(atSourceTime: sampleBuffer.presentationTimeStamp)
                state.startedSession = true
            }
            if input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        }
    }
}
