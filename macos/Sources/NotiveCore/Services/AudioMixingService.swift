@preconcurrency import AVFoundation
import Foundation

public enum AudioMixingError: LocalizedError {
    case missingTrack
    case unavailable
    case failed(String)

    public var errorDescription: String? {
        switch self {
        case .missingTrack:
            "Notive could not read an audio track for mixing."
        case .unavailable:
            "Notive could not create the audio mixer."
        case let .failed(message):
            "Audio mixing failed: \(message)"
        }
    }
}

public actor AudioMixingService {
    public init() {}

    public func mix(
        microphoneURL: URL,
        systemAudioURL: URL?,
        outputURL: URL
    ) async throws -> URL {
        try? FileManager.default.removeItem(at: outputURL)

        let composition = AVMutableComposition()
        let audioMix = AVMutableAudioMix()
        var parameters: [AVMutableAudioMixInputParameters] = []
        var sources = [(microphoneURL, Float(1))]
        if let systemAudioURL {
            sources.append((systemAudioURL, Float(0.82)))
        }

        for (url, volume) in sources {
            let asset = AVURLAsset(url: url)
            guard let sourceTrack = try await asset.loadTracks(withMediaType: .audio).first,
                  let destinationTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                  ) else {
                throw AudioMixingError.missingTrack
            }
            let duration = try await asset.load(.duration)
            try destinationTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: sourceTrack,
                at: .zero
            )
            let inputParameters = AVMutableAudioMixInputParameters(track: destinationTrack)
            inputParameters.setVolume(volume, at: .zero)
            parameters.append(inputParameters)
        }
        audioMix.inputParameters = parameters

        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A
        ) else { throw AudioMixingError.unavailable }
        exporter.audioMix = audioMix
        exporter.outputURL = outputURL
        exporter.outputFileType = .m4a
        await exporter.export()
        guard exporter.status == .completed else {
            throw AudioMixingError.failed(exporter.error?.localizedDescription ?? "Unknown export error")
        }
        return outputURL
    }
}
