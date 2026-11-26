import XCTest
final class LibraryTests: XCTestCase {
    func testSeededLibrary() {
        let app = XCUIApplication(); app.launch()
        app.buttons["library.load"].tap()
        let loaded = app.staticTexts["library.status"]
        let predicate = NSPredicate(format: "label == %@ OR label BEGINSWITH %@", "Loaded", "Access denied")
        expectation(for: predicate, evaluatedWith: loaded)
        waitForExpectations(timeout: 20)
        XCTAssertEqual(loaded.label, "Loaded", "PhotoKit access state: \(loaded.label)")
        XCTAssertEqual(app.staticTexts["library.count"].label, "Images: 3")
        XCTAssertTrue(app.staticTexts["64 × 32"].firstMatch.exists)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.lifetime = .keepAlways; add(attachment)
    }
}
