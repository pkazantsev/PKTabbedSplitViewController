import UIKit

private enum StackViewItem: Int {
    case tabBar
    case content

    var index: Int {
        return rawValue
    }
    var hierarchyIndex: Int {
        switch self {
        case .tabBar: return 1
        case .content: return 0
        }
    }
}

@IBDesignable
/**
 * Main view of the component
 */
class PKTabbedSplitView: UIView {

    var navigationBarWidth: CGFloat = 280 {
        didSet {
            navigationBarWidthConstraint?.constant = navigationBarWidth
        }
    }
    private(set) var navigationBarWidthConstraint: NSLayoutConstraint?

    var hideTabBarView: Bool = false

    var logger: DebugLogger?

    private(set) var sideBarIsHidden = true

    private var sideBarGestRecHelper: SideBarGestureRecognizerHelper?

    private let stackView = UIStackView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.alignment = .fill
        $0.distribution = .fill
        $0.axis = .horizontal
        $0.spacing = 0
    }
    /// Views saved here for us to be able to remove them from stack view and add back
    private let tabBarView: UIView
    private var contentView: UIView

    init(tabBarView: UIView, contentView: UIView) {
        self.tabBarView = tabBarView
        self.tabBarView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView = contentView
        self.contentView.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: .zero)

        // Different order from stackViewItems order due to layers order
        // (details view should be at the bottom, then master view, tab bar should be at the top)
        stackView.addSubview(contentView)
        stackView.addSubview(tabBarView)
        stackView.addArrangedSubview(tabBarView)
        stackView.addArrangedSubview(contentView)

        if #available(iOS 11.0, *) {
            addSubview(stackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let constraints = [
                stackView.leftAnchor.constraint(equalTo: leftAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).then { $0.priority = UILayoutPriority(999) },
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ]
            NSLayoutConstraint.activate(constraints)
        }
        else {
            addChildView(stackView)
        }
    }
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Switching mods for split-view

    /// This placeholder view will animate the stack view
    /// while we move the real tab bar to the left
    fileprivate func makeStackViewPlaceholderView(for sourceView: UIView, index: Int) -> UIView {
        let view = UIView()
        view.widthAnchor.constraint(equalToConstant: sourceView.frame.width).isActive = true
        stackView.insertArrangedSubview(view, at: index)
        stackView.insertSubview(view, belowSubview: sourceView)

        return view
    }

    func hideTabBar(animator: UIViewPropertyAnimator) {
        let placeholderView = makeStackViewPlaceholderView(for: tabBarView, index: StackViewItem.tabBar.index)

        var newFrame = tabBarView.frame
        tabBarView.translatesAutoresizingMaskIntoConstraints = true
        stackView.removeArrangedSubview(tabBarView)
        newFrame.origin.x = -tabBarView.frame.width

        animator.addAnimations {
            placeholderView.isHidden = true
            self.tabBarView.frame = newFrame
        }
        animator.addCompletion { _ in
            self.tabBarView.isHidden = true
            self.tabBarView.translatesAutoresizingMaskIntoConstraints = false
            placeholderView.removeFromSuperview()
        }
    }

    func showTabBar(animator: UIViewPropertyAnimator) {
        let item = StackViewItem.tabBar

        stackView.removeArrangedSubview(tabBarView)
        stackView.insertSubview(tabBarView, at: item.hierarchyIndex)
        // Without the next line the tab bar somehow loses its width
        tabBarView.layoutIfNeeded()

        let placeholderView = makeStackViewPlaceholderView(for: tabBarView, index: item.index)
        placeholderView.isHidden = true

        tabBarView.translatesAutoresizingMaskIntoConstraints = true
        tabBarView.frame.size.height = stackView.frame.height
        tabBarView.frame.origin = CGPoint(x: -tabBarView.frame.width, y: 0)
        tabBarView.isHidden = false

        animator.addAnimations {
            placeholderView.isHidden = false
            self.tabBarView.frame.origin.x = 0
        }
        animator.addCompletion { _ in
            self.tabBarView.translatesAutoresizingMaskIntoConstraints = false
            self.stackView.insertArrangedSubview(self.tabBarView, at: item.index)
            placeholderView.removeFromSuperview()
        }
    }

    func replaceContentView(with contentView: UIView, then completion: @escaping () -> Void) {
        let stackViewIndex = self.contentViewIndex()

        let prevContentView = self.contentView
        self.contentView = contentView

        // The placeholder view will prevent the stack view from animating
        // while we replace the content view
        let placeholderView = makeStackViewPlaceholderView(for: prevContentView, index: stackViewIndex)
        prevContentView.translatesAutoresizingMaskIntoConstraints = true

        stackView.removeArrangedSubview(prevContentView)

        let animate = UIView.areAnimationsEnabled
        // Somehow the size does not apply immediately but animates instead
        // but we need to have the final size before the animation.
        UIView.setAnimationsEnabled(false)
        contentView.translatesAutoresizingMaskIntoConstraints = true
        contentView.frame.size = prevContentView.frame.size
        contentView.frame.origin.x = prevContentView.frame.minX - prevContentView.frame.width
        stackView.insertSubview(contentView, aboveSubview: prevContentView)
        contentView.layoutIfNeeded()
        UIView.setAnimationsEnabled(animate)

        UIView.animate(withDuration: 0.33, animations: {
            prevContentView.frame.origin.x += prevContentView.frame.width
            contentView.frame.origin.x += contentView.frame.width
        }) { _ in
            placeholderView.removeFromSuperview()
            self.stackView.insertArrangedSubview(contentView, at: stackViewIndex)
            completion()
        }
    }

    private func contentViewIndex() -> Int {
        var index = StackViewItem.content.index
        if self.hideTabBarView {
            index -= 1
        }
        return index
    }

    // MARK: - Side bar

    func addNavigationBar(_ sideBarView: UIView) {
        logger?.log("Entered")

        // Don't actually need to animate anything here
        // but it's simpler than making the animator optional in hideTabBar
        let animator = UIViewPropertyAnimator(duration: 0.01, curve: .linear)
        hideTabBar(animator: animator)
        addSideBar(sideBarView)

        animator.startAnimation()
    }

    func addSideBar(_ sideBarView: UIView, width: CGFloat? = nil, leftOffset: CGFloat = 0, willOpen: (() -> Void)? = nil, willClose: (() -> Void)? = nil) {
        logger?.log("Entered")
        sideBarIsHidden = true
        if tabBarView.superview == nil {
            stackView.addSubview(sideBarView)
        }
        else {
            stackView.insertSubview(sideBarView, belowSubview: tabBarView)
        }

        let sideBarWidth = width ?? navigationBarWidth

        sideBarView.translatesAutoresizingMaskIntoConstraints = false
        sideBarView.topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
        sideBarView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
        sideBarView.isHidden = false

        let leading = sideBarView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -sideBarWidth)
        leading.isActive = true

        let widthConstraint = sideBarView.widthAnchor.constraint(equalToConstant: sideBarWidth)
        widthConstraint.isActive = true
        navigationBarWidthConstraint = widthConstraint

        let helper = SideBarGestureRecognizerHelper(base: stackView, target: sideBarView, targetX: leading, targetWidth: sideBarWidth, leftOffset: leftOffset)
        helper.logger = logger
        helper.willOpen = willOpen
        helper.didOpen = { [unowned self] in
            self.sideBarIsHidden = false
        }
        helper.willClose = willClose
        helper.didClose = { [unowned self] in
            self.sideBarIsHidden = true
        }
        sideBarGestRecHelper = helper
    }

    /// Removed the side bar view from the view hierarchy
    func removeSideBar(_ view: UIView) {
        logger?.log("\(view)")
        sideBarGestRecHelper = nil
        view.removeFromSuperview()

        navigationBarWidthConstraint?.isActive = false
        navigationBarWidthConstraint = nil
    }
    /// After removing a navigation side bar
    ///   we need to put the tab bar back to the stack view
    func putTabBarBack(keepHidden: Bool) {
        tabBarView.isHidden = keepHidden
        tabBarView.translatesAutoresizingMaskIntoConstraints = false

        stackView.insertSubview(tabBarView, at: StackViewItem.tabBar.hierarchyIndex)
        stackView.insertArrangedSubview(tabBarView, at: StackViewItem.tabBar.index)
    }

    func hideSideBar() {
        guard !sideBarIsHidden else { return }
        logger?.log("Closing side bar")
        sideBarGestRecHelper?.close(withDuration: sideBarAnimationDuration, animated: true, wasClosing: true)
    }
    func showSideBar() {
        guard sideBarIsHidden else { return }
        logger?.log("Opening side bar")
        sideBarGestRecHelper?.open(withDuration: sideBarAnimationDuration, animated: true, wasOpening: true)
    }

    func setSideBarGestureRecognizerEnabled(_ enabled: Bool) {
        sideBarGestRecHelper?.isEnabled = enabled
    }
    
}
