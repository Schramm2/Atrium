import AtriumCore
import SwiftUI

/// The Home heading: a greeting, today's line, and the capture controls.
struct HomeGreetingHeader: View {
    @Bindable var store: AppStore
    @Environment(\.brandTheme) private var theme
    @AppStorage("notive.hub.profile-name") private var profileName = ""

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.largeTitle.weight(.semibold))
                    .tracking(-0.5)
                Text(todayLine)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 720, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 12)

            HomeCaptureView(store: store)
        }
        .accessibilityElement(children: .contain)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let part = switch hour {
        case ..<12: "Good morning"
        case ..<17: "Good afternoon"
        default: "Good evening"
        }
        guard let firstName = profileName
            .split(whereSeparator: \.isWhitespace)
            .first
            .map(String.init) else { return part }
        return "\(part), \(firstName)"
    }

    private var todayLine: String {
        let today = Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
        return "\(today) · what changed across \(theme.title) today"
    }
}
