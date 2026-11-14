import UIKit
import Testing
@testable import PKTabbedSplitViewController

/// A tab shows an arrow when its master view is a side bar; without it there is no sign the side bar exists.
/// The arrow images are package resources, so they have to load from the package's resource bundle.
@Suite struct TabBarArrowImageTests {

    @Test func theOpenArrowLoads() {
        #expect(TabBarImages.openArrow != nil)
    }

    @Test func theCloseArrowLoads() {
        #expect(TabBarImages.closeArrow != nil)
    }
}
