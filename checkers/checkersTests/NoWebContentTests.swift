import Foundation
import Testing

@testable import checkers

struct NoWebContentTests {
    @Test("US7 FR-006: the app bundles no web pages")
    func noWebPages() {
        let files = Bundle.main.urls(forResourcesWithExtension: "html", subdirectory: nil) ?? []
        #expect(files.isEmpty, "Bundled: \(files.map(\.lastPathComponent))")
    }

    /// The prototype's `move.wav` is gone: the bundle holds only the app's four sounds, which
    /// `scripts/make-sounds.py --check` holds to their recipes (E6 FR-019).
    @Test("US7 FR-006: the only sounds bundled are the app's own four, no prototype sounds")
    func onlyTheAppsSounds() {
        let files = Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: nil) ?? []
        #expect(
            Set(files.map(\.lastPathComponent)) == Set(SoundEffect.allCases.map(\.fileName)))
    }
}
