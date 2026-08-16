import Testing
@testable import AtriumCore

@Suite("Brand themes")
struct BrandThemeTests {
    @Test("Only company themes are selectable")
    func allThemesArePresent() {
        #expect(BrandTheme.allCases == [.ubundi, .firstMotive])
    }
}
