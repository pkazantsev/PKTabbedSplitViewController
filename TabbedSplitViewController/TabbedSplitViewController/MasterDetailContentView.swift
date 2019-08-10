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

class MasterDetailContentView: UIView {

    var masterViewWidth: CGFloat = 320 {
        didSet {
            masterViewWidthConstraint.constant = masterViewWidth
        }
    }
    let masterViewWidthConstraint: NSLayoutConstraint

    var hideMasterView: Bool = false
    var hideDetailView: Bool = false {
        didSet {
            // When detail view is hidden the master view takes all available space
            masterViewWidthConstraint.isActive = !hideDetailView
        }
    }

    var logger: DebugLogger?

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

    init(masterView: UIView, detailView: UIView) {
        stackViewItems = [masterView, detailView]
        stackViewItems.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        masterViewWidthConstraint = masterView.widthAnchor.constraint(equalToConstant: masterViewWidth)
        // For a case when we don't have detail view and we stretch master to all the parent width
        masterViewWidthConstraint.priority = UILayoutPriority(900)

        super.init(frame: .zero)

        // Populate master-detail stack and put it into the container
        stackView.addSubview(detailView)
        stackView.addSubview(masterView)
        stackView.addArrangedSubview(masterView)
        stackView.addArrangedSubview(detailView)

        addChildView(stackView)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Master sizde bar

    /// Creates a side bar then adds a master view there.
    /// Should be called after removing the view from the stack view!
    func prepareMasterForSideBar() -> UIView {
        logger?.log("Entered")
        let sideBarView = self.view(for: .master)
        // Remove the master view from the stack view but only to get rid of all the constraints
        sideBarView.removeFromSuperview()
        //stackView.insertSubview(sideBarView, at: StackViewItem.master.hierarchyIndex)

        return sideBarView
    }
    func putMasterBack() {
        let view = self.view(for: .master)
        view.removeFromSuperview()
        view.isHidden = false

        stackView.insertSubview(view, at: StackViewItem.master.hierarchyIndex)
        stackView.insertArrangedSubview(view, at: StackViewItem.master.index)
    }

    // MARK: - Presenting detail view in-place

    private func prepareForHiding(_ item: StackViewItem, pushRight: Bool = false) -> CGRect {
        let view = self.view(for: item)
        var newFrame = view.frame
        view.translatesAutoresizingMaskIntoConstraints = true
        stackView.removeArrangedSubview(view)
        newFrame.origin.x = pushRight ? stackView.frame.maxX : -view.frame.width

        return newFrame
    }
/*
    /// Present detail view in-place, hiding master and detail, if not already hidden
    func presentFullWidthDetailView(hidingTabBar: Bool, hidingMaster: Bool, animationFinished: (() -> Void)?) {
        let masterNewFrame = hidingMaster ? prepareForHiding(.master) : nil
        let tabBarNewFrame = hidingTabBar ? prepareForHiding(.tabBar) : nil

        let detailView = self.view(for: .detail)
        // Just add as a subview, will add to arranged after the animation
        stackView.insertSubview(detailView, at: StackViewItem.detail.hierarchyIndex)

        // Set frame to full screen and hide behind right edge
        detailView.frame = stackView.frame
        detailView.frame.origin.x = stackView.frame.maxX
        detailView.isHidden = false

        UIView.animate(withDuration: 0.33, animations: {
            if let newFrame = masterNewFrame {
                self.view(for: .master).frame = newFrame
            }
            if let newFrame = tabBarNewFrame {
                self.view(for: .tabBar).frame = newFrame
            }
            detailView.frame.origin.x = 0
        }) { _ in
            self.view(for: .master).isHidden = true
            self.view(for: .tabBar).isHidden = true
            self.addArrangedView(.detail)
            animationFinished?()
        }
    }

    /// Hide detail view in-place, showing tab bar and master
    ///  if they were hidden by `presentDetailViewSolo(hidingTabBar:hidingMaster:)`
    ///  but otherwise should be shown
    ///
    /// - Parameters:
    ///   - keepShown: keep detail view on screen
    ///   - addingTabBar: add the tab bar back
    ///   - addingMaster: add the master view back
    func closeFullWidthDetailView(keepShown: Bool, addingTabBar: Bool, addingMaster: Bool, animationFinished: (() -> Void)?) {
        func prepareForShowing(_ item: StackViewItem, pushRight: Bool = false) {
            let view = self.view(for: item)
            stackView.removeArrangedSubview(view)
            stackView.insertSubview(view, at: item.hierarchyIndex)
            view.translatesAutoresizingMaskIntoConstraints = true
            view.frame.size.height = stackView.frame.height
            if !pushRight {
                view.frame.origin.x = -view.frame.width
            }
            view.isHidden = false
        }
        if addingTabBar {
            prepareForShowing(.tabBar)
        }
        if addingMaster {
            prepareForShowing(.master)
        }
        let detailNewFrame: CGRect
        if keepShown {
            detailNewFrame = .zero
            prepareForShowing(.detail, pushRight: true)
        } else {
            detailNewFrame = prepareForHiding(.detail, pushRight: true)
        }
        UIView.animate(withDuration: 0.33, animations: {
            if addingTabBar {
                self.view(for: .tabBar).frame.origin.x = 0
            }
            if addingMaster {
                let masterX: CGFloat = addingTabBar ? self.view(for: .tabBar).frame.width : 0
                self.view(for: .master).frame.origin.x = masterX
            }
            if keepShown {
                var detailX: CGFloat = 0
                if addingTabBar {
                    detailX += self.view(for: .tabBar).frame.width
                }
                if addingMaster {
                    detailX += self.view(for: .master).frame.width
                }
                self.view(for: .detail).frame.origin.x = detailX
            } else {
                self.view(for: .detail).frame = detailNewFrame
            }
        }) { _ in
            if addingTabBar {
                self.addArrangedView(.tabBar)
            }
            if addingMaster {
                self.addArrangedView(.master)
            }
            if keepShown {
                self.addArrangedView(.detail)
            } else {
                self.view(for: .detail).isHidden = true
            }
            animationFinished?()
        }
    }
*/
    /// Add **detail** view back to the stack view
    func addDetailView() {
        let item = StackViewItem.detail
        let view = self.view(for: item)

        view.isHidden = true
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
        view.translatesAutoresizingMaskIntoConstraints = false
        if item.index >= stackView.arrangedSubviews.count {
            stackView.addArrangedSubview(view)
        } else {
            stackView.insertArrangedSubview(view, at: item.index)
        }
    }

}
