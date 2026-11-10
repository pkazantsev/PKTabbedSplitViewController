import UIKit
import Testing
@testable import TabbedSplitViewControllerDemo
import PKTabbedSplitViewController

/// The demo's detail-collapse rule follows the current master width (MPL-439): a master view
/// widened for a large text size can leave the detail view too narrow even in regular width.
@MainActor
@Suite struct DemoDetailCollapseTests {

    private func demoConfig() throws -> TabbedSplitViewController.Configuration {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        let splitVC = try #require(delegate?.window?.rootViewController as? TabbedSplitViewController)
        return splitVC.config
    }

    /// iPhone Plus in landscape: 736 pt wide, regular width, master view inline.
    private let plusLandscape = CGSize(width: 736, height: 414)
    private let plusTraits = UITraitCollection(traitsFrom: [
        UITraitCollection(horizontalSizeClass: .regular),
        UITraitCollection(userInterfaceIdiom: .phone),
    ])

    @Test(arguments: [(CGFloat(320), false), (CGFloat(384), true)])
    func plusLandscapeHidesDetailOnlyWhenTheMasterLeavesTooLittleRoom(masterWidth: CGFloat, hidesDetail: Bool) throws {
        var config = try demoConfig()
        config.masterViewWidth = masterWidth

        // 70 + 320 + 320 = 710 fits in 736; 70 + 384 + 320 = 774 doesn't.
        let hideDetail = try #require(config.showDetailAsModalWithSizeChange)
        let hide = hideDetail(plusLandscape, plusTraits, config)
        #expect(hide == hidesDetail)
    }
}
