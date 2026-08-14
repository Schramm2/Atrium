import Foundation
import SwiftUI

struct RecordingMeterView: View {
    let elapsed: TimeInterval
    let power: Float

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.red)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
            Text(Self.time(elapsed))
                .font(.caption.monospacedDigit())
            ProgressView(value: normalizedPower)
                .progressViewStyle(.linear)
                .accessibilityLabel("Recording level")
        }
        .accessibilityElement(children: .contain)
    }

    private var normalizedPower: Double {
        min(1, max(0, Double((power + 60) / 60)))
    }

    private static func time(_ value: TimeInterval) -> String {
        let seconds = Int(value)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
