import XCTest
import UIKit
@testable import PhotosLab

final class MetadataTests: XCTestCase {
    private func fixture() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 64, height: 32), format: {
            let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f
        }()).pngData { context in
            UIColor.red.setFill(); context.fill(CGRect(x: 0, y: 0, width: 64, height: 32))
        }
    }
    func testDimensions() throws {
        let metadata = try ImageMetadata.read(fixture())
        XCTAssertEqual(metadata.width, 64)
        XCTAssertEqual(metadata.height, 32)
        XCTAssertEqual(metadata.orientation, 1)
    }
    func testCorruptData() { XCTAssertThrowsError(try ImageMetadata.read(Data([0, 1, 2]))) }
    func testMetadataPerformance() {
        let data = fixture()
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 0..<100 { _ = try? ImageMetadata.read(data) }
        }
    }
}
