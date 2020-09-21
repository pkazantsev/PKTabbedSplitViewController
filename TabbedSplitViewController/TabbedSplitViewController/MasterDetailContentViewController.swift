//
//  MasterDetailContentView.swift
//

import UIKit

private enum StackViewItem: Int {
    case master
    case detail

    var index: Int {
        return rawValue
    }
    var hierarchyIndex: Int {
        switch self {
        case .master: return 1
        case .detail: return 0
        }
    }
}

class MasterDetailContentViewController: UIViewController {

    var config: TabbedSplitViewController.Configuration = .zero {
        didSet {
            self.updateConfig(from: oldValue)
        }
    }

    var hideMasterView: Bool = false
    var hideDetailView: Bool = false {
        didSet {
            // When detail view is hidden the master view takes all available space
            masterViewWidthConstraint.isActive = !hideDetailView
        }
    }

    var defaultDetailViewController: UIViewController? {
        didSet {
            detailVC.defaultViewController = self.defaultDetailViewController
        }
    }
    var masterViewController: UIViewController? {
        didSet {
            masterVC.viewController = self.masterViewController
        }
    }

    var logger: DebugLogger?

    private var masterViewWidth: CGFloat = 320 {
        didSet {
            masterViewWidthConstraint.constant = masterViewWidth
        }
    }
    private(set) var masterViewWidthConstraint: NSLayoutConstraint!

    private let stackView = UIStackView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.alignment = .fill
        $0.distribution = .fill
        $0.axis = .horizontal
        $0.spacing = 0
    }

    private let masterVC = PKMasterViewController()
    private let detailVC = PKDetailViewController()

    private func view(for item: StackViewItem) -> UIView {
        switch item {
        case .master: return self.masterVC.view
        case .detail: return self.detailVC.view
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let masterView = masterVC.view!
        let detailView = detailVC.view!

        [masterView, detailView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.autoresizingMask = []
        }

        masterViewWidthConstraint = masterView.widthAnchor.constraint(equalToConstant: masterViewWidth)
        // For a case when we don't have detail view and we stretch master to all the parent width
        masterViewWidthConstraint.priority = UILayoutPriority(900)

        // Populate master-detail stack and put it into the container
        stackView.addSubview(detailView)
        stackView.addSubview(masterView)
        stackView.addArrangedSubview(masterView)
        stackView.addArrangedSubview(detailView)

        addChild(masterVC)
        addChild(detailVC)

        addChildView(stackView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        masterVC.didMove(toParent: self)
        detailVC.didMove(toParent: self)
    }

    func setDetailViewController(_ newVC: UIViewController?, animate: Bool, completion: (() -> Void)? = nil) {
        self.detailVC.setViewController(newVC, animate: animate, completion: completion)
    }

    // MARK: - Master side bar

    /// Creates a side bar then adds a master view there.
    /// Should be called after removing the view from the stack view!
    func prepareMasterForSideBar() -> UIViewController? {
        logger?.log("Entered")

        masterVC.willMove(toParent: nil)
        masterVC.view.removeFromSuperview()
        masterVC.removeFromParent()

        return masterVC
    }
    func putMasterBack() {
        masterVC.willMove(toParent: self)
        stackView.insertSubview(masterVC.view, at: StackViewItem.master.hierarchyIndex)
        stackView.insertArrangedSubview(masterVC.view, at: StackViewItem.master.index)
        addChild(masterVC)
    }

    // MARK: - Presenting detail view in-place

    /// Present detail view in-place, hiding master and detail, if not already hidden
    ///
    /// - Parameters:
    ///   - animator: the main animator that will animate the whole view
    ///   - hideMaster: hide the master view it it isn't already hidden
    func presentFullWidthDetailView(animator: UIViewPropertyAnimator, hideMaster: Bool, initialOffset: CGFloat) {
        let detailView = self.view(for: .detail)
        // Just add as a subview, will add to arranged after the animation
        stackView.insertSubview(detailView, at: StackViewItem.detail.hierarchyIndex)

        let masterView = self.view(for: .master)
        let newMasterViewFrame = hideMaster ? prepareForHiding(masterView) : nil

        detailView.translatesAutoresizingMaskIntoConstraints = true
        detailView.frame.origin.x = stackView.frame.maxX
        detailView.frame.size.width = stackView.frame.width + initialOffset
        detailView.isHidden = false

        animator.addAnimations {
            if let newFrame = newMasterViewFrame {
                masterView.frame = newFrame
            }
            detailView.frame.origin.x = 0
        }
        animator.addCompletion { _ in
            if hideMaster {
                masterView.isHidden = true
            }
            self.addArrangedView(.detail)
        }
    }

    /// Hide detail-view-in-place, showing tab bar and master
    ///  if they were hidden by `presentDetailViewSolo(hidingTabBar:hidingMaster:)`
    ///  but otherwise should be shown
    ///
    /// - Parameters:
    ///   - animator: the main animator that will animate the whole view
    ///   - keepShown: keep detail view on screen
    ///   - showMaster: add the master view back if it was hidden
    func closeFullWidthDetailView(animator: UIViewPropertyAnimator, keepShown: Bool, showMaster: Bool, masterOffset: CGFloat) {
        let detailView = self.view(for: .detail)
        let masterView = self.view(for: .master)

        var detailViewOffset: CGFloat = 0
        if showMaster {
            if !keepShown {
                // If we remove the detail view from hierarchy than means it is compact mode.
                // There is a chance that changed the window width.
                masterView.frame.size.width = detailView.frame.width - masterOffset
            }
            prepareForShowing(masterView, at: StackViewItem.master.hierarchyIndex)
            detailViewOffset += masterView.frame.width
        }

        let detailNewFrame: CGRect
        if keepShown {
            detailNewFrame = .zero
            prepareForShowing(detailView, at: StackViewItem.detail.hierarchyIndex, pushRight: true)
        } else {
            detailNewFrame = prepareForHiding(detailView, to: detailViewOffset)
        }
        animator.addAnimations {
            if showMaster {
                masterView.frame.origin.x = 0
            }
            if keepShown {
                detailView.frame.origin.x = detailViewOffset
            } else {
                detailView.frame = detailNewFrame
            }
        }
        animator.addCompletion { _ in
            if showMaster {
                self.addArrangedView(.master)
            }
            if keepShown {
                self.addArrangedView(.detail)
            } else {
                detailView.isHidden = true
            }
        }
    }

    private func prepareForHiding(_ view: UIView, to position: CGFloat? = nil) -> CGRect {
        var newFrame = view.frame
        view.translatesAutoresizingMaskIntoConstraints = true
        stackView.removeArrangedSubview(view)
        if let targetPosition = position {
            newFrame.origin.x = targetPosition
        }
        else {
            newFrame.origin.x = -view.frame.width
        }

        return newFrame
    }

    private func prepareForShowing(_ view: UIView, at position: Int, pushRight: Bool = false) {
        stackView.removeArrangedSubview(view)
        stackView.insertSubview(view, at: position)
        view.translatesAutoresizingMaskIntoConstraints = true
        view.frame.size.height = stackView.frame.height
        if !pushRight {
            view.frame.origin.x = -view.frame.width
        }
        view.isHidden = false
    }

    // MARK: -

    /// Add **detail** view back to the stack view
    func addDetailView() {
        let item = StackViewItem.detail
        let view = self.view(for: item)

        view.frame = CGRect(origin: .zero, size: view.frame.size)
        stackView.insertSubview(view, at: item.hierarchyIndex)
        addArrangedView(item)
        view.isHidden = false
    }
    /// Remove **detail** view from the stack view
    func removeDetailView(removeFromViewHierarchy: Bool) {
        let view = self.view(for: .detail)
        if removeFromViewHierarchy {
            view.removeFromSuperview()
        } else {
            view.isHidden = true
        }
    }

    // MARK: - Helper methods

    private func addArrangedView(_ item: StackViewItem) {
        let view = self.view(for: item)
        if item.index >= stackView.arrangedSubviews.count {
            stackView.addArrangedSubview(view)
        } else {
            stackView.insertArrangedSubview(view, at: item.index)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    private func updateConfig(from oldConfig: TabbedSplitViewController.Configuration) {
        if config.masterViewWidth != oldConfig.masterViewWidth {
            masterViewWidth = config.masterViewWidth
        }
        if config.detailBackgroundColor != oldConfig.detailBackgroundColor {
            detailVC.backgroundColor = config.detailBackgroundColor
        }
        if config.verticalSeparatorColor != oldConfig.verticalSeparatorColor {
            masterVC.verticalSeparatorColor = config.verticalSeparatorColor
        }
    }
}

// MARK: - Master view controller

private class PKMasterViewController: UIViewController {

    fileprivate var viewController: UIViewController? {
        didSet {
            if let prev = oldValue {
                prev.willMove(toParent: nil)
                prev.view.removeFromSuperview()
                prev.removeFromParent()
            }
            if let next = viewController {
                addChild(next)
                addChildView(next.view)
                if shouldAddVerticalSeparator {
                    view.addVerticalSeparator(verticalSeparator, color: verticalSeparatorColor)
                }
                view.layoutIfNeeded()
                next.didMove(toParent: self)
            }
        }
    }
    fileprivate var shouldAddVerticalSeparator: Bool = true
    fileprivate var verticalSeparatorColor: UIColor = .gray {
        didSet {
            verticalSeparator.backgroundColor = verticalSeparatorColor
        }
    }
    private let verticalSeparator = VerticalSeparatorView()

    fileprivate init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate override func viewDidLoad() {
        super.viewDidLoad()

        if shouldAddVerticalSeparator {
            view.addVerticalSeparator(verticalSeparator, color: verticalSeparatorColor)
        }

        view.accessibilityIdentifier = "Master View"
        view.backgroundColor = .white
    }

}

// MARK: - Detail view controller

private class PKDetailViewController: UIViewController {

    private var viewController: UIViewController?

    fileprivate var defaultViewController: UIViewController? {
        didSet {
            // Don't replace current VC if it's presented
            if viewController == nil, defaultViewController != nil {
                setViewController(defaultViewController, animate: false)
            }
        }
    }
    fileprivate var backgroundColor: UIColor = .white {
        didSet {
            view.backgroundColor = backgroundColor
        }
    }

    fileprivate init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "Detail View"
        view.backgroundColor = backgroundColor
    }

    fileprivate func setViewController(_ newVC: UIViewController?, animate: Bool, completion: (() -> Void)? = nil) {
        let oldVC = viewController
        viewController = newVC ?? defaultViewController
        replaceViewController(oldVC, with: viewController, animate: animate, completion: completion)
    }

    private func replaceViewController(_ oldVC: UIViewController?, with newVC: UIViewController?, animate: Bool, completion: (() -> Void)?) {

        if let next = newVC {
            addChild(next)
            addChildViewCentered(next.view)
        }
        oldVC?.willMove(toParent: nil)

        let completion = { [unowned self] in
            oldVC?.removeFromParent()
            oldVC?.view.removeFromSuperview()
            newVC?.didMove(toParent: self)
            completion?()
        }

        guard animate else {
            completion()
            return
        }

        if let prev = oldVC, let next = newVC {
            // Switching between two view controllers
            if let nextXPosition = next.view.constraint(for: .centerX) {
                nextXPosition.constant = -view.bounds.width
                view.layoutIfNeeded()

                nextXPosition.constant = 0
                prev.view.constraint(for: .centerX)?.constant = view.bounds.width
            }

            transition(from: prev, to: next, duration: 0.33, options: [.curveEaseInOut], animations: {
                self.view.layoutIfNeeded()
            }) { finished in
                if finished {
                    completion()
                }
            }
        } else if let view = oldVC?.view ?? newVC?.view {
            let isClosing = (newVC == nil)
            view.alpha = isClosing ? 1.0 : 0.0
            UIView.transition(with: view, duration: 0.33, options: [.curveEaseInOut], animations: {
                view.alpha = isClosing ? 0.0 : 1.0
            }) { finished in
                if finished {
                    completion()
                }
            }
        }
    }
}
