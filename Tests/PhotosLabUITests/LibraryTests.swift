import XCTest
final class LibraryTests: XCTestCase {
    func testSeededLibrary() {
        let app = XCUIApplication(); app.launch()
        app.buttons["library.load"].tap()
        let loaded = app.staticTexts["library.status"]
        let predicate = NSPredicate(format: "label == %@ OR label BEGINSWITH %@", "Loaded", "Access denied")
        let reachedTerminalState = XCTNSPredicateExpectation(predicate: predicate, object: loaded)
        let result = XCTWaiter.wait(for: [reachedTerminalState], timeout: 25)
        guard result == .completed else {
            XCTFail("PhotoKit never completed loading. Status: \(loaded.label). App hierarchy: \(app.debugDescription)")
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.lifetime = .keepAlways
            add(attachment)
            return
        }
        guard loaded.label == "Loaded" else {
            XCTFail("PhotoKit access state: \(loaded.label)")
            return
        }
        XCTAssertEqual(app.staticTexts["library.count"].label, "Images: 3")
        XCTAssertTrue(app.staticTexts["64 × 32"].firstMatch.exists)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.lifetime = .keepAlways; add(attachment)
    }
}
