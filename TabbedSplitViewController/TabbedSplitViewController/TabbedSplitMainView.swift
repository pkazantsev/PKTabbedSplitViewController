//
//  TabbedSplitMainView.swift
//

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
                stackView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor),
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
    fileprivate func makeTabBarPlaceholder(for tabBarView: UIView) -> UIView {
        let view = UIView()
        view.widthAnchor.constraint(equalToConstant: tabBarView.frame.width).isActive = true
        stackView.insertArrangedSubview(view, at: 0)
        stackView.insertSubview(view, belowSubview: tabBarView)

        return view
    }

    func hideTabBar(animator: UIViewPropertyAnimator) {
        let placeholderView = makeTabBarPlaceholder(for: tabBarView)

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
            placeholderView.removeFromSuperview()
        }
    }

    func showTabBar(animator: UIViewPropertyAnimator) {

        stackView.removeArrangedSubview(tabBarView)
        stackView.insertSubview(tabBarView, at: StackViewItem.tabBar.hierarchyIndex)

        let placeholderView = makeTabBarPlaceholder(for: tabBarView)
        placeholderView.isHidden = true

        tabBarView.translatesAutoresizingMaskIntoConstraints = true
        tabBarView.frame.size.height = stackView.frame.height
        tabBarView.frame.origin.x = -tabBarView.frame.width
        tabBarView.isHidden = false

        animator.addAnimations {
            placeholderView.isHidden = false
            self.tabBarView.frame.origin.x = 0
        }
        animator.addCompletion { _ in
            self.tabBarView.translatesAutoresizingMaskIntoConstraints = false
            self.stackView.insertArrangedSubview(self.tabBarView, at: StackViewItem.tabBar.index)
            placeholderView.removeFromSuperview()
        }
    }


    func replaceContentView(with contentView: UIView, then completion: @escaping () -> Void) {
        let prevContentView = self.contentView
        self.contentView = contentView

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.isHidden = true
        stackView.insertSubview(contentView, at: StackViewItem.content.hierarchyIndex)
        stackView.insertArrangedSubview(contentView, at: StackViewItem.content.index)

        UIView.animate(withDuration: 0.33, animations: {
            prevContentView.isHidden = true
            contentView.isHidden = false
        }) { _ in
            completion()
        }
    }

    // MARK: - Side bar

    func addNavigationBar(_ sideBarView: UIView) {
        logger?.log("Entered")
        tabBarView.removeFromSuperview()

        addSideBar(sideBarView)
    }

    func addSideBar(_ sideBarView: UIView, width: CGFloat? = nil) {
        sideBarIsHidden = true
        addSubview(sideBarView)

        let sideBarWidth = width ?? navigationBarWidth

        sideBarView.translatesAutoresizingMaskIntoConstraints = false
        sideBarView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        sideBarView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        sideBarView.isHidden = false

        let leading = sideBarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -sideBarWidth)
        leading.isActive = true

        let widthConstraint = sideBarView.widthAnchor.constraint(equalToConstant: sideBarWidth)
        widthConstraint.isActive = true
        navigationBarWidthConstraint = widthConstraint

        let helper = SideBarGestureRecognizerHelper(base: self, target: sideBarView, targetX: leading, targetWidth: sideBarWidth)
        helper.logger = logger
        helper.didOpen = { [unowned self] in
            self.sideBarIsHidden = false
        }
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

        if !keepHidden {
            tabBarView.isHidden = false
        }
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
