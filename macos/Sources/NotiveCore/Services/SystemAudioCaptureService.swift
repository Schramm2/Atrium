@preconcurrency import AVFoundation
@preconcurrency import ScreenCaptureKit
import CoreMedia
import Foundation

public enum SystemAudioCaptureError: LocalizedError {
    case noDisplay
    case couldNotWrite
    case noActiveCapture

    public var errorDescription: String? {
        switch self {
        case .noDisplay:
            "Notive could not find a display for system audio capture."
        case .couldNotWrite:
            "Notive could not create the system audio recording."
        case .noActiveCapture:
            "There is no active system audio capture to stop."
        }
    }
}

public final class SystemAudioCaptureService: NSObject, SCStreamOutput, @unchecked Sendable {
    private let sampleQueue = DispatchQueue(label: "com.ubundi.meet.system-audio")
    private var stream: SCStream?
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var outputURL: URL?
    private var startedSession = false
    private var acceptsSamples = true

    public func start(at url: URL) async throws {
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
        guard writer.canAdd(input) else { throw SystemAudioCaptureError.couldNotWrite }
        writer.add(input)

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
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleQueue)
        self.writer = writer
        self.input = input
        outputURL = url
        startedSession = false
        acceptsSamples = true
        self.stream = stream
        try await stream.startCapture()
    }

    public func pause() {
        sampleQueue.async { self.acceptsSamples = false }
    }

    public func resume() {
        sampleQueue.async { self.acceptsSamples = true }
    }

    public func stop() async throws -> URL {
        guard let stream, let writer, let input, let outputURL else {
            throw SystemAudioCaptureError.noActiveCapture
        }
        try await stream.stopCapture()
        self.stream = nil
        sampleQueue.sync { input.markAsFinished() }
        await writer.finishWriting()
        self.writer = nil
        self.input = nil
        self.outputURL = nil
        startedSession = false
        acceptsSamples = true
        guard writer.status == .completed else {
            throw SystemAudioCaptureError.couldNotWrite
        }
        return outputURL
    }

    public func cancel() async {
        try? await stream?.stopCapture()
        stream = nil
        writer?.cancelWriting()
        if let outputURL { try? FileManager.default.removeItem(at: outputURL) }
        writer = nil
        input = nil
        outputURL = nil
        startedSession = false
        acceptsSamples = true
    }

    public func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .audio,
              acceptsSamples,
              sampleBuffer.isValid,
              CMSampleBufferDataIsReady(sampleBuffer),
              let writer,
              let input else { return }

        if !startedSession {
            guard writer.startWriting() else { return }
            writer.startSession(atSourceTime: sampleBuffer.presentationTimeStamp)
            startedSession = true
        }
        if input.isReadyForMoreMediaData {
            input.append(sampleBuffer)
        }
    }
}
