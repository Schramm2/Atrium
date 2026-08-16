import AppKit
import AtriumCore

@MainActor
enum AppIconService {
    static func apply(_ theme: BrandTheme) {
        let filename = switch theme {
        case .ubundi: "ubundi-icon"
        case .firstMotive: "first-motive-icon"
        }
        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: "png"
        ), let image = NSImage(contentsOf: url) else { return }
        NSApplication.shared.applicationIconImage = image
    }
}
