import XCTest

final class LibraryTests: XCTestCase {
    func testSeededLibrary() {
        let app = XCUIApplication()
        app.launch()

        let loadButton = app.buttons["library.load"]
        XCTAssertTrue(loadButton.waitForExistence(timeout: 10), "Load library button should be visible")
        loadButton.tap()

        // TCC permissions may be reset when XCTest launches the app, even when simctl
        // granted photo access during simulator setup. Handle the system sheet explicitly.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let status = app.staticTexts["library.status"]
        let authorizationPending = NSPredicate(format: "label == %@", "Awaiting photo permission")
        if status.waitForExistence(timeout: 5),
           authorizationPending.evaluate(with: status) {
            let alert = springboard.alerts.firstMatch
            if alert.waitForExistence(timeout: 8) {
                let allowed = [
                    "Allow Full Access",
                    "Allow Access to All Photos",
                    "Allow Access to All",
                    "Allow",
                    "OK"
                ]
                if let button = allowed.map({ alert.buttons[$0] }).first(where: { $0.exists }) {
                    button.tap()
                } else {
                    XCTFail("Photo permission dialog appeared with unexpected actions: \(alert.debugDescription)")
                    return
                }
            }
        }

        let predicate = NSPredicate(format: "label == %@ OR label BEGINSWITH %@", "Loaded", "Access denied")
        let reachedTerminalState = XCTNSPredicateExpectation(predicate: predicate, object: status)
        let result = XCTWaiter.wait(for: [reachedTerminalState], timeout: 25)
        guard result == .completed else {
            XCTFail("PhotoKit never completed loading. Status: \(status.label). App: \(app.debugDescription). SpringBoard: \(springboard.debugDescription)")
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.lifetime = .keepAlways
            add(attachment)
            return
        }
        guard status.label == "Loaded" else {
            XCTFail("PhotoKit access state: \(status.label)")
            return
        }
        // The Photos simulator may contain pre-existing assets. Validate that
        // every seeded fixture exists without assuming an otherwise empty library.
        let countLabel = app.staticTexts["library.count"].label
        let imageCount = Int(countLabel.replacingOccurrences(of: "Images: ", with: ""))
        XCTAssertNotNil(imageCount, "Unable to parse image count: \(countLabel)")
        XCTAssertGreaterThanOrEqual(imageCount ?? 0, 3, "Expected at least the three seeded fixtures")
        for dimensions in ["64 × 32", "640 × 480", "480 × 640"] {
            XCTAssertTrue(app.staticTexts[dimensions].firstMatch.exists,
                          "Missing seeded image with dimensions: \(dimensions)")
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
