import SwiftUI
import Photos
import ImageIO
import OSLog

struct ImageMetadata: Equatable {
    let width: Int
    let height: Int
    let orientation: Int
    static func read(_ data: Data) throws -> Self {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return Self(width: width, height: height, orientation: props[kCGImagePropertyOrientation] as? Int ?? 1)
    }
}

struct AssetRecord: Identifiable {
    let id: String
    let width: Int
    let height: Int
}

@MainActor final class LibraryModel: ObservableObject {
    @Published private(set) var assets: [AssetRecord] = []
    @Published private(set) var status = "Not loaded"
    private let logger = Logger(subsystem: "org.portfolio.PhotosLab", category: "Library")
    func reload() async {
        status = "Loading"
        // A pre-authorized simulator should not invoke the permission request UI.
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        logger.info("Photo library authorization before loading: \(current.rawValue)")
        let auth: PHAuthorizationStatus
        if current == .notDetermined {
            status = "Awaiting photo permission"
            auth = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        } else {
            auth = current
        }
        guard auth == .authorized || auth == .limited else {
            assets = []; status = "Access denied (\(auth.rawValue))"; logger.error("Photo library authorization status: \(auth.rawValue)"); return
        }
        let result = PHAsset.fetchAssets(with: .image, options: nil)
        var records: [AssetRecord] = []
        result.enumerateObjects { asset, _, _ in
            records.append(.init(id: asset.localIdentifier, width: asset.pixelWidth, height: asset.pixelHeight))
        }
        assets = records.sorted { $0.id < $1.id }
        status = "Loaded"
        logger.info("Loaded \(records.count) image assets")
    }
    func createAlbum() async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "PhotosLab QA")
            }
            status = "Album created"
        } catch { status = "Album creation failed"; logger.error("Album creation failed") }
    }
}

@main struct PhotosLabApp: App {
    @StateObject private var model = LibraryModel()
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack {
                    Text(model.status).accessibilityIdentifier("library.status")
                    Text("Images: \(model.assets.count)").accessibilityIdentifier("library.count")
                    Button("Load library") { Task { await model.reload() } }.accessibilityIdentifier("library.load")
                    Button("Create QA album") { Task { await model.createAlbum() } }.accessibilityIdentifier("library.album")
                    // Nine or more simulator assets can exceed the visible list area.
                    // Use a non-lazy stack so fixture labels remain discoverable by XCTest.
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(model.assets) { asset in
                                Text("\(asset.width) × \(asset.height)")
                                    .accessibilityIdentifier("asset.\(asset.width)x\(asset.height)")
                            }
                        }
                    }.accessibilityIdentifier("library.assets")
                }.navigationTitle("Photos QA Lab")
            }
        }
    }
}
