import Foundation
import Testing

struct NoWebContentTests {
    @Test(
        "US7 FR-006: the app bundles no web pages and no prototype sounds",
        arguments: ["html", "wav"])
    func noWebResources(fileExtension: String) {
        let files =
            Bundle.main.urls(forResourcesWithExtension: fileExtension, subdirectory: nil) ?? []
        #expect(files.isEmpty, "Bundled: \(files.map(\.lastPathComponent))")
    }
}
