import UIKit
import Testing
import PKTabbedSplitViewController

/// 30% of the longer side, ×1.2 at accessibility text sizes.
private func masterWidth(for size: CGSize, traits: UITraitCollection) -> CGFloat {
    let base = (max(size.width, size.height) * 0.3).rounded()
    return traits.preferredContentSizeCategory.isAccessibilityCategory ? (base * 1.2).rounded() : base
}

/// `Configuration.masterViewWidthWithSizeChange` (MPL-439): the controller asks it for the
/// master view width when it appears and when the text size changes, and applies the result.
///
/// Package tests run in a bare `xctest` process with no `UIApplication`, so the tests drive
/// appearance and trait changes through a parent view controller instead of a window.
@MainActor
@Suite struct MasterViewWidthCallbackTests {

    private final class Recorder {
        var sizes: [CGSize] = []
        var categories: [UIContentSizeCategory] = []
    }

    private let size = CGSize(width: 1194, height: 834)

    private func makeController(recorder: Recorder?) -> TabbedSplitViewController {
        let item = PKTabBarItem<TabBarScreenConfiguration>(title: "Tab", image: UIImage(), action: UIViewController())
        let controller = TabbedSplitViewController(items: [item])
        var config = controller.config
        config.masterViewWidth = 300
        if let recorder {
            config.masterViewWidthWithSizeChange = { size, traits, _ in
                recorder.sizes.append(size)
                recorder.categories.append(traits.preferredContentSizeCategory)
                return masterWidth(for: size, traits: traits)
            }
        }
        controller.config = config
        return controller
    }

    /// Embeds the controller in a parent sized like an 11" iPad in landscape and makes it appear.
    private func present(_ controller: UIViewController) -> UIViewController {
        let parent = UIViewController()
        parent.view.frame = CGRect(origin: .zero, size: size)
        parent.addChild(controller)
        controller.view.frame = parent.view.bounds
        parent.view.addSubview(controller.view)
        controller.didMove(toParent: parent)

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        return parent
    }

    @Test func appliesTheWidthWhenItAppears() {
        let recorder = Recorder()
        let controller = makeController(recorder: recorder)
        _ = present(controller)

        #expect(recorder.sizes.first == size)
        #expect(controller.config.masterViewWidth == 358)
    }

    @Test func withoutTheCallbackTheWidthStaysAsSet() {
        let controller = makeController(recorder: nil)
        _ = present(controller)

        #expect(controller.config.masterViewWidth == 300)
    }

    @Test func reappliesTheWidthWhenTheTextSizeChanges() {
        let recorder = Recorder()
        let controller = makeController(recorder: recorder)
        let parent = present(controller)
        #expect(controller.config.masterViewWidth == 358)

        let largeText = UITraitCollection(preferredContentSizeCategory: .accessibilityLarge)
        parent.setOverrideTraitCollection(largeText, forChild: controller)
        controller.view.layoutIfNeeded()

        #expect(recorder.categories.last == .accessibilityLarge)
        #expect(controller.config.masterViewWidth == 430)
    }
}
