import Testing
@testable import AtriumCore

@Suite("Brand themes")
struct BrandThemeTests {
    @Test("Atrium is the first theme and default selection value")
    func atriumIsFirst() {
        #expect(BrandTheme.allCases.first == .atrium)
        #expect(BrandTheme.atrium.rawValue == "atrium")
        #expect(BrandTheme.atrium.title == "Atrium")
    }

    @Test("All brand themes remain selectable")
    func allThemesArePresent() {
        #expect(BrandTheme.allCases == [.atrium, .ubundi, .firstMotive])
    }
}
