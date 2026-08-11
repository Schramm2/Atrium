import AVFoundation
import Foundation

@MainActor
public final class AudioPlaybackService {
    private var player: AVAudioPlayer?

    public init() {}

    public var isPlaying: Bool { player?.isPlaying == true }
    public var currentTime: TimeInterval { player?.currentTime ?? 0 }
    public var duration: TimeInterval { player?.duration ?? 0 }

    public func load(_ url: URL) throws {
        if player?.url == url { return }
        player?.stop()
        player = try AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
    }

    public func toggle() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }

    public func seek(to value: TimeInterval) {
        player?.currentTime = min(max(0, value), duration)
    }

    public func stop() {
        player?.stop()
        player = nil
    }
}

public enum MeetingAudioFiles {
    private static let extensions = ["m4a", "wav", "mp3", "mp4", "mov", "aac", "flac"]

    public static func primary(in folderPath: String?) -> URL? {
        guard let folderPath else { return nil }
        let folder = URL(fileURLWithPath: folderPath, isDirectory: true)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return nil }
        return files
            .filter { extensions.contains($0.pathExtension.lowercased()) }
            .sorted { lhs, rhs in
                if lhs.lastPathComponent == "audio.m4a" { return true }
                if rhs.lastPathComponent == "audio.m4a" { return false }
                return lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent) == .orderedAscending
            }
            .first
    }
}
