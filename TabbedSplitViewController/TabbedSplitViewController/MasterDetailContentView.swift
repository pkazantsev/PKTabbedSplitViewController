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

    // MARK: - Master side bar

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

    func hideMasterView(animator: UIViewPropertyAnimator) {
        let masterView = self.view(for: .master)
        let newFrame = prepareForHiding(masterView)

        animator.addAnimations {
            masterView.frame = newFrame
        }
        animator.addCompletion { _ in
            masterView.isHidden = true
        }
    }

    func showMasterView(animator: UIViewPropertyAnimator, offset: CGFloat) {
        let masterView = self.view(for: .master)
        prepareForShowing(masterView, at: StackViewItem.master.hierarchyIndex)

        animator.addAnimations {
            masterView.frame.origin.x = offset
        }
        animator.addCompletion { _ in
            self.addArrangedView(.master)
        }
    }

    /// Present detail view in-place, hiding master and detail, if not already hidden
    func presentFullWidthDetailView(animator: UIViewPropertyAnimator) {
        let detailView = self.view(for: .detail)
        // Just add as a subview, will add to arranged after the animation
        stackView.insertSubview(detailView, at: StackViewItem.detail.hierarchyIndex)

        // Set frame to full screen and hide behind right edge
        detailView.frame = stackView.frame
        detailView.frame.origin.x = stackView.frame.maxX
        detailView.isHidden = false

        animator.addAnimations {
            detailView.frame.origin.x = 0
        }
        animator.addCompletion { _ in
            self.addArrangedView(.detail)
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
    func closeFullWidthDetailView(animator: UIViewPropertyAnimator, keepShown: Bool, offset: CGFloat) {
        let detailView = self.view(for: .detail)

        let detailNewFrame: CGRect
        if keepShown {
            detailNewFrame = .zero
            prepareForShowing(detailView, at: StackViewItem.detail.hierarchyIndex, pushRight: true)
        } else {
            detailNewFrame = prepareForHiding(detailView, pushRight: true)
        }
        animator.addAnimations {
            if keepShown {
                detailView.frame.origin.x = offset
            } else {
                detailView.frame = detailNewFrame
            }
        }
        animator.addCompletion { _ in
            if keepShown {
                self.addArrangedView(.detail)
            } else {
                detailView.isHidden = true
            }
        }
    }

    private func prepareForHiding(_ view: UIView, pushRight: Bool = false) -> CGRect {
        var newFrame = view.frame
        view.translatesAutoresizingMaskIntoConstraints = true
        stackView.removeArrangedSubview(view)
        newFrame.origin.x = pushRight ? stackView.frame.maxX : -view.frame.width

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
