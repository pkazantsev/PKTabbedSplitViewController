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
    private let stackViewItems: [UIView]

    private func view(for item: StackViewItem) -> UIView {
        return stackViewItems[item.index]
    }

    init(tabBarView: UIView, contentView: UIView) {
        stackViewItems = [tabBarView, contentView]
        stackViewItems.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

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

    func hideTabBar(animator: UIViewPropertyAnimator) {
        let tabBarView = self.view(for: .tabBar)

        var newFrame = tabBarView.frame
        tabBarView.translatesAutoresizingMaskIntoConstraints = true
        stackView.removeArrangedSubview(tabBarView)
        newFrame.origin.x = -tabBarView.frame.width

        animator.addAnimations {
            tabBarView.isHidden = true
            tabBarView.frame = newFrame
        }
        animator.addCompletion { _ in
            tabBarView.isHidden = true
        }
    }

    func showTabBar(animator: UIViewPropertyAnimator) {
        let tabBarView = self.view(for: .tabBar)

        stackView.removeArrangedSubview(tabBarView)
        stackView.insertSubview(tabBarView, at: StackViewItem.tabBar.hierarchyIndex)
        tabBarView.translatesAutoresizingMaskIntoConstraints = true
        tabBarView.frame.size.height = stackView.frame.height
        tabBarView.frame.origin.x = -tabBarView.frame.width
        tabBarView.isHidden = false

        animator.addAnimations {
            tabBarView.frame.origin.x = 0
        }
        animator.addCompletion { _ in
            self.addArrangedView(.tabBar)
        }
    }

    private func addArrangedView(_ item: StackViewItem) {
        let view = self.view(for: item)
        view.translatesAutoresizingMaskIntoConstraints = false
        if item.index >= stackView.arrangedSubviews.count {
            stackView.addArrangedSubview(view)
        } else {
            stackView.insertArrangedSubview(view, at: item.index)
        }
    }

    // MARK: - Side bar

    func addNavigationBar(_ sideBarView: UIView) {
        logger?.log("Entered")
        self.view(for: .tabBar).removeFromSuperview()

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

        let tabBar = self.view(for: .tabBar)
        if !keepHidden {
            tabBar.isHidden = false
        }
        stackView.insertSubview(tabBar, at: StackViewItem.tabBar.hierarchyIndex)
        stackView.insertArrangedSubview(tabBar, at: StackViewItem.tabBar.index)
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
