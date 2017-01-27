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

    var hideTabBarView: Bool = false {
        didSet {
            stackViewItems[StackViewItem.tabBar.index].isHidden = hideTabBarView
        }
    }
    var hideMasterView: Bool = false {
        didSet {
            stackViewItems[StackViewItem.master.index].isHidden = hideMasterView
        }
    }
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
        let view = stackViewItems[StackViewItem.master.index]
        stackView.removeArrangedSubview(view)
        stackView.insertSubview(view, at: StackViewItem.master.hierarchyIndex)

        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        let leadingConstraint = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -masterViewWidth)
        leadingConstraint.isActive = true

        let helper = SideBarGestureRecognizerHelper(base: self, target: view, targetX: leadingConstraint, targetWidth: masterViewWidth, leftOffset: tabBarWidth)
        sideBarGestRecHelper = helper
    }
    func addNavigationBar(_ view: UIView) {
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
        sideBarGestRecHelper = helper
    }

    func removeMasterSideBar() {
        sideBarGestRecHelper = nil
        let view = stackViewItems[StackViewItem.master.index]
        view.isHidden = true
        view.removeFromSuperview()
        stackView.insertSubview(view, at: StackViewItem.master.hierarchyIndex)
        stackView.insertArrangedSubview(view, at: StackViewItem.master.index)
    }
    func removeNavigationBar(_ view: UIView) {
        sideBarGestRecHelper = nil
        view.isHidden = true
        view.removeFromSuperview()

        let tabBar = stackViewItems[StackViewItem.tabBar.index]
        stackView.insertSubview(tabBar, at: StackViewItem.tabBar.hierarchyIndex)
        stackView.insertArrangedSubview(tabBar, at: StackViewItem.tabBar.index)
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

    private var startingPoint: CGFloat = 0

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
    }

    @objc private func handleGesture(_ rec: UIGestureRecognizer) {
        let isOpenGestRec = (rec == openViewRec)
        switch rec.state {
        case .began:
            let point = rec.location(ofTouch: 0, in: sourceView).x
            //print("\((isOpenGestRec ? "Open" : "Close")): gesture began: \(point)")
            startingPoint = point
            targetView.isHidden = false
            break
        case .changed:
            let point = rec.location(ofTouch: 0, in: sourceView).x
            //print("\((isOpenGestRec ? "Open" : "Close")): gesture changed: \(point)")
            if isOpenGestRec {
                let maxPoint = viewWidth + startingPoint
                xConstraint.constant = ((point < maxPoint) ? point - startingPoint - viewWidth : 0) + leftOffset
            } else {
                xConstraint.constant = ((point < startingPoint) ? point - startingPoint : 0) + leftOffset
            }
        //print("    constraint: \(xConstraint.constant)")
        case .ended:
            //print("\((isOpenGestRec ? "Open" : "Close")): gesture ended")
            let shouldOpen = abs(xConstraint.constant - leftOffset) < viewWidth / 2
            //print("    Should open: \(shouldOpen) (\(xConstraint.constant), \(abs(xConstraint.constant - leftOffset)))")
            let duration = 0.35 * ((abs(xConstraint.constant - leftOffset) / 2) / (viewWidth / 2))
            xConstraint.constant = (shouldOpen ? 0 : -viewWidth) + leftOffset
            //print("    constraint: \(xConstraint.constant)")
            UIView.animate(withDuration: TimeInterval(duration)) {
                self.sourceView.layoutIfNeeded()
            }
            if shouldOpen && isOpenGestRec {
                openViewRec.isEnabled = false
                didOpen?()
            }
            if !shouldOpen && !isOpenGestRec {
                openViewRec.isEnabled = true
            }
        case .cancelled:
            //print("gesture cancelled")
            break
        default:
            break
        }
    }
    
}
