import UIKit
import Testing
@testable import PKTabbedSplitViewController

/// `SideBarGestureRecognizerHelper.updateWidth(_:)` (MPL-439) keeps the side bar where it's heading,
/// also when the width changes while an open or close animation is still running.
@MainActor
@Suite struct SideBarWidthUpdateTests {

    private let leftOffset: CGFloat = 70

    private struct Fixture {
        let base: UIView
        let sideBar: UIView
        let leading: NSLayoutConstraint
        let helper: SideBarGestureRecognizerHelper
    }

    /// A closed 300 pt side bar, laid out the way `PKTabbedSplitView.addSideBar` does it.
    private func makeFixture() -> Fixture {
        let base = UIView(frame: CGRect(x: 0, y: 0, width: 1133, height: 744))
        let sideBar = UIView()
        sideBar.translatesAutoresizingMaskIntoConstraints = false
        base.addSubview(sideBar)
        let leading = sideBar.leadingAnchor.constraint(equalTo: base.leadingAnchor, constant: -300)
        NSLayoutConstraint.activate([
            leading,
            sideBar.widthAnchor.constraint(equalToConstant: 300),
            sideBar.topAnchor.constraint(equalTo: base.topAnchor),
            sideBar.bottomAnchor.constraint(equalTo: base.bottomAnchor),
        ])
        let helper = SideBarGestureRecognizerHelper(base: base, target: sideBar, targetX: leading, targetWidth: 300, leftOffset: leftOffset)
        return Fixture(base: base, sideBar: sideBar, leading: leading, helper: helper)
    }

    @Test func wideningWhileOpeningKeepsTheOpenPosition() {
        let fixture = makeFixture()
        fixture.helper.open(withDuration: 0.35)  // still animating: didOpen hasn't run

        fixture.helper.updateWidth(400)

        #expect(fixture.leading.constant == leftOffset)
    }

    @Test func wideningWhileClosingEndsFullyHidden() {
        let fixture = makeFixture()
        // Package tests have no window, so animation completions never run here; this checks the
        // outcome, but unlike the opening case it can't tell old code (state from completions) apart.
        fixture.helper.open(withDuration: 0)
        fixture.helper.close(withDuration: 0.35)  // still animating: didClose hasn't run

        fixture.helper.updateWidth(400)

        #expect(fixture.leading.constant == -400 + leftOffset)
    }

    @Test func wideningWhileClosedStaysHidden() {
        let fixture = makeFixture()
        fixture.helper.close(withDuration: 0)

        fixture.helper.updateWidth(400)

        #expect(fixture.leading.constant == -400 + leftOffset)
    }
}
