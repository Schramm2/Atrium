@preconcurrency import AVFoundation
import Foundation

public actor VoiceClusterService {
    public init() {}

    public func label(
        _ segments: [TranscriptSegment],
        audioURL: URL
    ) throws -> [TranscriptSegment] {
        let file = try AVAudioFile(forReading: audioURL)
        let sampleRate = file.processingFormat.sampleRate
        let channelCount = file.processingFormat.channelCount
        guard sampleRate > 0, channelCount > 0 else { return segments }

        let features = try segments.map { segment -> [Float]? in
            guard let start = segment.audioStartTime,
                  let end = segment.audioEndTime,
                  end > start else { return nil }
            let startFrame = AVAudioFramePosition(start * sampleRate)
            let available = max(0, file.length - startFrame)
            let requested = AVAudioFrameCount(min(
                Double(available),
                min((end - start) * sampleRate, 3 * sampleRate)
            ))
            guard requested > 0,
                  let buffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: requested
                  ) else { return nil }
            file.framePosition = startFrame
            try file.read(into: buffer, frameCount: requested)
            return Self.features(buffer, sampleRate: sampleRate)
        }

        let present = features.compactMap { $0 }
        var labelIterator = Self.labels(for: present).makeIterator()
        return zip(segments, features).map { segment, feature in
            guard feature != nil else { return segment }
            let speaker = labelIterator.next() ?? "Speaker 1"
            return TranscriptSegment(
                id: segment.id,
                meetingID: segment.meetingID,
                text: segment.text,
                timestamp: segment.timestamp,
                audioStartTime: segment.audioStartTime,
                audioEndTime: segment.audioEndTime,
                duration: segment.duration,
                speaker: speaker,
                speakerDisplayName: segment.speakerDisplayName
            )
        }
    }

    static func labels(for features: [[Float]], threshold: Float = 0.94) -> [String] {
        var centroids: [[Float]] = []
        var counts: [Int] = []
        return features.map { feature in
            let value = normalized(feature)
            let best = centroids.enumerated()
                .map { ($0.offset, dot(value, $0.element)) }
                .max { $0.1 < $1.1 }
            if let best, best.1 >= threshold {
                counts[best.0] += 1
                let count = Float(counts[best.0])
                centroids[best.0] = normalized(zip(centroids[best.0], value).map {
                    ($0 * (count - 1) + $1) / count
                })
                return "Speaker \(best.0 + 1)"
            }
            centroids.append(value)
            counts.append(1)
            return "Speaker \(centroids.count)"
        }
    }

    private static func features(
        _ buffer: AVAudioPCMBuffer,
        sampleRate: Double
    ) -> [Float]? {
        guard let channels = buffer.floatChannelData, buffer.frameLength > 0 else { return nil }
        let step = max(1, Int(sampleRate / 8_000))
        let frameCount = Int(buffer.frameLength)
        var samples: [Float] = []
        samples.reserveCapacity(frameCount / step)
        for index in stride(from: 0, to: frameCount, by: step) {
            samples.append(channels[0][index])
        }
        guard samples.count >= 320 else { return nil }

        let rms = sqrt(samples.reduce(Float(0)) { $0 + $1 * $1 } / Float(samples.count))
        var zeroCrossings: Float = 0
        var slope: Float = 0
        for index in 1..<samples.count {
            if (samples[index - 1] >= 0) != (samples[index] >= 0) { zeroCrossings += 1 }
            slope += abs(samples[index] - samples[index - 1])
        }
        zeroCrossings /= Float(samples.count - 1)
        slope /= Float(samples.count - 1)

        let downsampledRate = Float(sampleRate) / Float(step)
        let minLag = max(1, Int(downsampledRate / 300))
        let maxLag = min(samples.count / 2, Int(downsampledRate / 80))
        var bestLag = minLag
        var bestCorrelation: Float = -.infinity
        if maxLag >= minLag {
            for lag in minLag...maxLag {
                var correlation: Float = 0
                for index in lag..<samples.count {
                    correlation += samples[index] * samples[index - lag]
                }
                if correlation > bestCorrelation {
                    bestCorrelation = correlation
                    bestLag = lag
                }
            }
        }
        let pitch = bestLag > 0 ? downsampledRate / Float(bestLag) / 300 : 0

        let quarter = max(1, samples.count / 4)
        let envelope = (0..<4).map { part -> Float in
            let start = part * quarter
            let end = part == 3 ? samples.count : min(samples.count, start + quarter)
            guard start < end else { return 0 }
            return samples[start..<end].reduce(Float(0)) { $0 + abs($1) } / Float(end - start)
        }
        return normalized([rms, zeroCrossings, slope, pitch] + envelope)
    }

    private static func normalized(_ value: [Float]) -> [Float] {
        let magnitude = sqrt(value.reduce(Float(0)) { $0 + $1 * $1 })
        guard magnitude > .ulpOfOne else { return value }
        return value.map { $0 / magnitude }
    }

    private static func dot(_ lhs: [Float], _ rhs: [Float]) -> Float {
        zip(lhs, rhs).reduce(Float(0)) { $0 + $1.0 * $1.1 }
    }
}
