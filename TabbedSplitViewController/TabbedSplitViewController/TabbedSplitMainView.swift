//
//  TabbedSplitMainView.swift
//  TabbedSplitViewController
//
//  Created by Pavel Kazantsev on 1/24/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import UIKit

private enum StackViewItem: Int {
    case tabBar
    case master
    case detail

    var index: Int {
        return rawValue
    }
    var hierarchyIndex: Int {
        switch self {
        case .tabBar: return 2
        case .master: return 1
        case .detail: return 0
        }
    }
}

private let sideBarAnimationDuration: TimeInterval = 0.35

@IBDesignable
class PKTabbedSplitView: UIView {

    var tabBarWidth: CGFloat = 0 {
        didSet {
            tabBarWidthConstraint.constant = tabBarWidth
        }
    }
    var masterViewWidth: CGFloat = 0 {
        didSet {
            masterViewWidthConstraint.constant = masterViewWidth
        }
    }
    var navigationBarWidth: CGFloat = 280 {
        didSet {
            navigationBarWidthConstraint?.constant = navigationBarWidth
        }
    }
    let tabBarWidthConstraint: NSLayoutConstraint
    let masterViewWidthConstraint: NSLayoutConstraint
    private(set) var navigationBarWidthConstraint: NSLayoutConstraint?

    var hideTabBarView: Bool = false
    var hideMasterView: Bool = false
    var hideDetailView: Bool = false {
        didSet {
            let detailView = stackViewItems[StackViewItem.detail.index]
            if hideDetailView {
                removeDetailView()
            } else if detailView.superview == nil {
                addDetailView()
            }
            // When detail view is hidden the master view takes all available space
            masterViewWidthConstraint.isActive = !hideDetailView
        }
    }

    var logger: DebugLogger?

    private var sideBarIsHidden = true

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

    init(tabBarView: UIView, masterView: UIView, detailView: UIView) {
        tabBarWidthConstraint = .init(item: tabBarView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: tabBarWidth)
        masterViewWidthConstraint = .init(item: masterView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: masterViewWidth)

        stackViewItems = [tabBarView, masterView, detailView]

        super.init(frame: .zero)

        tabBarView.addConstraint(tabBarWidthConstraint)
        masterView.addConstraint(masterViewWidthConstraint)

        // Different order from stackViewItems order due to layers order
        // (details view should be at the bottom, then master view, tab bar should be at the top)
        stackView.addSubview(detailView)
        stackView.addSubview(masterView)
        stackView.addSubview(tabBarView)

        for view in stackViewItems {
            stackView.addArrangedSubview(view)
        }

        addSubview(stackView)

        addConstraints(.constraints(withVisualFormat: "V:|[stack]|", options: [], metrics: [:], views: ["stack": stackView]))
        addConstraints(.constraints(withVisualFormat: "H:|[stack]|", options: [], metrics: [:], views: ["stack": stackView]))
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addDetailView() {
        let item = StackViewItem.detail
        let view = stackViewItems[item.index]
        stackView.insertSubview(view, at: item.hierarchyIndex)
        if item.index >= stackView.arrangedSubviews.count {
            stackView.addArrangedSubview(view)
        } else {
            stackView.insertArrangedSubview(view, at: item.index)
        }
    }
    func removeDetailView() {
        let view = stackViewItems[StackViewItem.detail.index]
        stackView.removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    /// Creates a side bar then adds a master view there.
    /// Should be called after removing the view from the stack view!
    func addMasterSideBar() {
        logger?.log("Entered")
        sideBarIsHidden = true
        let view = stackViewItems[StackViewItem.master.index]
        stackView.removeArrangedSubview(view)
        view.removeFromSuperview()
        stackView.insertSubview(view, at: StackViewItem.master.hierarchyIndex)

        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        let leadingConstraint = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -masterViewWidth)
        leadingConstraint.isActive = true

        let helper = SideBarGestureRecognizerHelper(base: self, target: view, targetX: leadingConstraint, targetWidth: masterViewWidth, leftOffset: tabBarWidth)
        helper.logger = logger
        helper.didOpen = { [unowned self] in
            self.sideBarIsHidden = false
        }
        helper.didClose = { [unowned self] in
            self.sideBarIsHidden = true
        }
        sideBarGestRecHelper = helper
    }
    func addNavigationBar(_ view: UIView) {
        logger?.log("Entered")
        sideBarIsHidden = true
        stackViewItems[StackViewItem.tabBar.index].removeFromSuperview()
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        let width = view.widthAnchor.constraint(equalToConstant: navigationBarWidth)
        width.isActive = true
        navigationBarWidthConstraint = width

        let leading = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -navigationBarWidth)
        leading.isActive = true

        let helper = SideBarGestureRecognizerHelper(base: self, target: view, targetX: leading, targetWidth: navigationBarWidth)
        helper.logger = logger
        helper.didOpen = { [unowned self] in
            self.sideBarIsHidden = false
        }
        helper.didClose = { [unowned self] in
            self.sideBarIsHidden = true
        }
        sideBarGestRecHelper = helper
    }

    func removeMasterSideBar() {
        logger?.log("Entered")
        sideBarGestRecHelper = nil
        let view = stackViewItems[StackViewItem.master.index]
        view.removeFromSuperview()
        stackView.insertSubview(view, at: StackViewItem.master.hierarchyIndex)
        stackView.insertArrangedSubview(view, at: StackViewItem.master.index)
    }
    func removeNavigationBar(_ view: UIView) {
        logger?.log("\(view)")
        sideBarGestRecHelper = nil
        view.removeFromSuperview()

        let tabBar = stackViewItems[StackViewItem.tabBar.index]
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
    
}

private class SideBarGestureRecognizerHelper {

    private let sourceView: UIView
    private let targetView: UIView
    private let xConstraint: NSLayoutConstraint
    private let viewWidth: CGFloat
    private let leftOffset: CGFloat

    fileprivate let openViewRec: UIGestureRecognizer
    fileprivate let closeViewRec: UIGestureRecognizer
    fileprivate var didOpen: (() -> Void)?
    fileprivate var didClose: (() -> Void)?

    private var startingPoint: CGFloat = 0

    var logger: DebugLogger?

    fileprivate init(base: UIView, target: UIView, targetX: NSLayoutConstraint, targetWidth: CGFloat, leftOffset: CGFloat = 0) {
        sourceView = base
        targetView = target
        xConstraint = targetX
        viewWidth = targetWidth
        self.leftOffset = leftOffset

        let rec1 = UIScreenEdgePanGestureRecognizer()
        sourceView.addGestureRecognizer(rec1)
        openViewRec = rec1

        let rec2 = UIPanGestureRecognizer()
        targetView.addGestureRecognizer(rec2)
        closeViewRec = rec2

        rec1.edges = .left
        rec1.addTarget(self, action: #selector(handleGesture(_:)))
        rec2.addTarget(self, action: #selector(handleGesture(_:)))
    }
    deinit {
        sourceView.removeGestureRecognizer(openViewRec)
        targetView.removeGestureRecognizer(closeViewRec)
        xConstraint.isActive = false
        logger?.log("Deinit \(type(of: self))")
    }

    @objc private func handleGesture(_ rec: UIGestureRecognizer) {
        let isOpenGestRec = (rec == openViewRec)
        switch rec.state {
        case .began:
            let point = rec.location(ofTouch: 0, in: sourceView).x
            startingPoint = point
        case .changed:
            let point = rec.location(ofTouch: 0, in: sourceView).x
            if isOpenGestRec {
                let maxPoint = viewWidth + startingPoint
                xConstraint.constant = ((point < maxPoint) ? point - startingPoint - viewWidth : 0) + leftOffset
            } else {
                xConstraint.constant = ((point < startingPoint) ? point - startingPoint : 0) + leftOffset
            }
        case .ended:
            let shouldOpen = abs(xConstraint.constant - leftOffset) < viewWidth / 2
            let duration = sideBarAnimationDuration * TimeInterval(((abs(xConstraint.constant - leftOffset) / 2) / (viewWidth / 2)))

            if shouldOpen {
                open(withDuration: duration, animated: true, wasOpening: isOpenGestRec)
            } else {
                close(withDuration: duration, animated: true, wasClosing: !isOpenGestRec)
            }
        case .cancelled:
            break
        default:
            break
        }
    }

    func close(withDuration duration: TimeInterval, animated: Bool = true, wasClosing: Bool = true) {
        xConstraint.constant = -viewWidth + leftOffset
        logger?.log("Constant: \(self.xConstraint.constant)")
        UIView.animate(withDuration: duration) {
            self.sourceView.layoutIfNeeded()
        }

        if wasClosing {
            openViewRec.isEnabled = true
            didClose?()
        }
    }
    func open(withDuration duration: TimeInterval, animated: Bool = true, wasOpening: Bool = true) {
        xConstraint.constant = leftOffset
        logger?.log("Constant: \(self.xConstraint.constant)")
        UIView.animate(withDuration: duration) {
            self.sourceView.layoutIfNeeded()
        }

        if wasOpening {
            openViewRec.isEnabled = false
            didOpen?()
        }
    }

}
