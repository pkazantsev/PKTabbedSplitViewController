//
//  TabbedSplitViewController.swift
//
//  Created by Pavel Kazantsev on 29/06/15.
//  Copyright (c) 2015 Pavel Kazantsev. All rights reserved.
//

import UIKit

public struct PKTabBarItem {
    /// Item title
    public let title: String
    /// Item image (up to 60pt)
    public let image: UIImage
    /// Item image – selected state
    public let selectedImage: UIImage?
    /// View controller that should be opened by tap on the item
    public let viewController: UIViewController

    public init(viewController: UIViewController, title: String, image: UIImage, selectedImage: UIImage? = nil) {
        self.title = title
        self.image = image
        self.selectedImage = selectedImage;
        self.viewController = viewController
    }
}

public class TabbedSplitViewController: UIViewController {

    public typealias SizeChangedCallback = ((CGSize, UITraitCollection, Configuration) -> Bool)

    public struct Configuration {
        /// Width of a vertical TabBar. **Default – 70**.
        public var tabBarWidth: CGFloat = 70
        /// Width of a master view. **Default – 320**.
        public var masterViewWidth: CGFloat = 320
        /// Minimal width of a detail view. **Default – 320**.
        ///
        /// If there is no space for a detail view it is hidden to be presented as a modal view.
        public var detailViewMinWidth: CGFloat = 320
        /// Color of a vertical TabBar. **Default – .white**.
        public var tabBarBackgroundColor: UIColor = .white

        /// Called when ether size or traits collection of the view is changed
        ///  to determine if tab bar should be hidden from main view and shown
        ///   as a slidable side bar.
        public var showTabBarAsSideBarWithSizeChange: SizeChangedCallback?
        /// Called when ether size or traits collection of the view is changed
        ///   to determine if master view should be hidden from main view and shown
        ///   as a slidable side bar.
        ///
        /// **Should not return true when** `showTabBarAsSideBarWithSizeChange` **callback returns true!**
        public var showMasterAsSideBarWithSizeChange: SizeChangedCallback?
        /// Called when ether size or traits collection of the view is changed
        ///   to determine if detail view should be hidden from main view and shown
        ///   as a modal view.
        ///
        /// **Should not return true when** `showMasterAsSideBarWithSizeChange` **callback returns true!**
        public var showDetailAsModalWithSizeChange: SizeChangedCallback?

        fileprivate func widthChanged(old oldValue: Configuration) -> Bool {
            return tabBarWidth != oldValue.tabBarWidth
                || masterViewWidth != oldValue.masterViewWidth
                || detailViewMinWidth != oldValue.detailViewMinWidth
        }

        fileprivate static let zero: Configuration = Configuration(tabBarWidth: 0, masterViewWidth: 0, detailViewMinWidth: 0, tabBarBackgroundColor: .white, showTabBarAsSideBarWithSizeChange: nil, showMasterAsSideBarWithSizeChange: nil, showDetailAsModalWithSizeChange: nil)
    }

    public var config = Configuration() {
        didSet {
            update(oldConfig: oldValue)
        }
    }

    private(set) var masterViewController: UIViewController?
    private var detailViewController: UIViewController?

    private let masterVC = PKMasterViewController()
    private let detailVC = PKDetailViewController()
    private let tabBar = PKTabBar()
    private let mainView: PKTabbedSplitView
    private var masterViewIsHidden: Bool = false

    private var futureTraits: UITraitCollection?

    public init(items: [PKTabBarItem]) {
        mainView = PKTabbedSplitView(tabBarView: tabBar.view, masterView: masterVC.view, detailView: detailVC.view)

        super.init(nibName: nil, bundle: nil)

        tabBar.items = items
    }

    public required init?(coder aDecoder: NSCoder) {
        mainView = PKTabbedSplitView(tabBarView: tabBar.view, masterView: masterVC.view, detailView: detailVC.view)

        super.init(coder: aDecoder)
    }

    public override func loadView() {
        view = mainView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        addChildViewController(tabBar)
        addChildViewController(masterVC)
        addChildViewController(detailVC)

        masterVC.setWidthConstraint(mainView.masterViewWidthConstraint)

        update(oldConfig: .zero)

        view.backgroundColor = .gray

        tabBar.view.backgroundColor = .purple
        masterVC.view.backgroundColor = .green
        detailVC.view.backgroundColor = .blue
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let hideTabBar = config.showTabBarAsSideBarWithSizeChange?(view.frame.size, traitCollection, config) {
            mainView.hideTabBarView = hideTabBar
        }
        if let hideMaster = config.showMasterAsSideBarWithSizeChange?(view.frame.size, traitCollection, config) {
            mainView.hideMasterView = hideMaster
            if hideMaster {
                self.mainView.remove(.master)
                self.mainView.addMasterSideBar()
            }
        }
        // Hide detail from main view if there is not enough width
        if let hideDetail = config.showDetailAsModalWithSizeChange?(view.frame.size, traitCollection, config) {
            mainView.hideDetailView = hideDetail
        }
    }

    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        print("\(#function) -> \(newCollection)")
        futureTraits = newCollection
    }
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("\(#function) -> \(size)")
        var hideDetail = false
        var hideMaster = false
        var hideTabBar = false

        let traits = futureTraits ?? traitCollection
        if let hideDetailFunc = config.showDetailAsModalWithSizeChange {
            hideDetail = hideDetailFunc(size, traits, config)
            print("hide detail view: \(hideDetail)")

            if mainView.hideDetailView != hideDetail {
                if hideDetail {
                    coordinator.animate(alongsideTransition: nil, completion: { (_) in
                        self.mainView.remove(.detail)
                    })
                } else {
                    coordinator.animate(alongsideTransition: { (_) in
                        self.mainView.add(.detail)
                    }, completion: nil)
                }
            }

            mainView.hideDetailView = hideDetail
        }
        if !hideDetail, let hideMasterFunc = config.showMasterAsSideBarWithSizeChange {
            hideMaster = hideMasterFunc(size, traits, config)
            print("hide master view: \(hideMaster)")

            if mainView.hideMasterView != hideMaster {
                if hideMaster {
                    coordinator.animate(alongsideTransition: nil, completion: { (_) in
                        self.mainView.remove(.master)
                        self.mainView.addMasterSideBar()
                    })
                } else {
                    coordinator.animate(alongsideTransition: { (_) in
                        self.mainView.removeMasterSideBar()
                        self.mainView.add(.master)
                    }, completion: nil)
                }
            }

            mainView.hideMasterView = hideMaster
        }
        if !(hideDetail && hideMaster), let hideTabBarFunc = config.showTabBarAsSideBarWithSizeChange {
            hideTabBar = hideTabBarFunc(size, traits, config)
            print("hide Tab Bar: \(hideTabBar)")

            if mainView.hideTabBarView != hideTabBar {
                if hideTabBar {
                    coordinator.animate(alongsideTransition: nil, completion: { (_) in
                        self.mainView.remove(.tabBar)
                    })
                } else {
                    coordinator.animate(alongsideTransition: { (_) in
                        self.mainView.add(.tabBar)
                    }, completion: nil)
                }
            }

            mainView.hideTabBarView = hideTabBar
        }
        futureTraits = nil
    }

    public func add(_ item: PKTabBarItem) {
        tabBar.items.append(item)
    }

    private func update(oldConfig: Configuration) {
        if config.tabBarWidth != oldConfig.tabBarWidth {
            mainView.tabBarWidth = config.tabBarWidth
        }
        if config.masterViewWidth != oldConfig.masterViewWidth {
            mainView.masterViewWidth = config.masterViewWidth
        }
        if config.tabBarBackgroundColor != oldConfig.tabBarBackgroundColor {
            tabBar.backgroundColor = config.tabBarBackgroundColor
        }
    }

}

private enum StackViewItem: Int {
    case tabBar
    case master
    case detail

    var index: Int {
        return rawValue
    }
}

@IBDesignable
private class PKTabbedSplitView: UIView {
    fileprivate var tabBarWidth: CGFloat = 0 {
        didSet {
            tabBarWidthConstraint.constant = tabBarWidth
        }
    }
    fileprivate var masterViewWidth: CGFloat = 0 {
        didSet {
            masterViewWidthConstraint.constant = masterViewWidth
        }
    }
    fileprivate let tabBarWidthConstraint: NSLayoutConstraint
    fileprivate let masterViewWidthConstraint: NSLayoutConstraint

    fileprivate var hideTabBarView: Bool = false {
        didSet {
            stackViewItems[StackViewItem.tabBar.index].isHidden = hideTabBarView
        }
    }
    fileprivate var hideMasterView: Bool = false {
        didSet {
            stackViewItems[StackViewItem.master.index].isHidden = hideMasterView
        }
    }
    fileprivate var hideDetailView: Bool = false {
        didSet {
            stackViewItems[StackViewItem.detail.index].isHidden = hideDetailView
            // When detail view is hidden the master view takes all available space
            masterViewWidthConstraint.isActive = !hideDetailView
        }
    }

    private var sideBarGestRecHelper: SideBarGestureRecognizerHelper?

    private let stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.alignment = .fill
        $0.distribution = .fill
        $0.axis = .horizontal
        $0.spacing = 0

        return $0
    }(UIStackView())
    /// Views saved here for us to be able to remove them from stack view and add back
    private let stackViewItems: [UIView]

    fileprivate init(tabBarView: UIView, masterView: UIView, detailView: UIView) {
        tabBarWidthConstraint = NSLayoutConstraint(item: tabBarView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: tabBarWidth)
        masterViewWidthConstraint = NSLayoutConstraint(item: masterView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: masterViewWidth)

        stackViewItems = [tabBarView, masterView, detailView]

        super.init(frame: CGRect())

        tabBarView.addConstraint(tabBarWidthConstraint)
        masterView.addConstraint(masterViewWidthConstraint)

        detailView.preservesSuperviewLayoutMargins = true
        masterView.preservesSuperviewLayoutMargins = true
        tabBarView.preservesSuperviewLayoutMargins = true

        translatesAutoresizingMaskIntoConstraints = false
        detailView.translatesAutoresizingMaskIntoConstraints = false
        masterView.translatesAutoresizingMaskIntoConstraints = false
        tabBarView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addSubview(detailView)
        stackView.addSubview(masterView)
        stackView.addSubview(tabBarView)

        stackView.addArrangedSubview(tabBarView)
        stackView.addArrangedSubview(masterView)
        stackView.addArrangedSubview(detailView)
        addSubview(stackView)

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[stack]|", options: [], metrics: [:], views: ["stack": stackView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[stack]|", options: [], metrics: [:], views: ["stack": stackView]))
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func add(_ item: StackViewItem) {
        let view = stackViewItems[item.index]
        if item.index >= stackView.arrangedSubviews.count {
            stackView.addArrangedSubview(view)
        } else {
            stackView.insertArrangedSubview(view, at: item.index)
        }
    }
    fileprivate func remove(_ item: StackViewItem) {
        let view = stackViewItems[item.index]
        stackView.removeArrangedSubview(view)
    }

    /// Creates a side bar then adds a master view there.
    /// Should be called after removing the view from the stack view!
    fileprivate func addMasterSideBar() {
        let view = stackViewItems[StackViewItem.master.index]

        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        let leadingConstraint = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -masterViewWidth)
        leadingConstraint.isActive = true

        let helper = SideBarGestureRecognizerHelper(source: self, target: view, targetX: leadingConstraint, targetViewWidth: masterViewWidth, tabBarWidth: tabBarWidth)
        sideBarGestRecHelper = helper
    }

    fileprivate func removeMasterSideBar() {
        sideBarGestRecHelper = nil
    }

}

private let pkTabBarItemCellIdentifier = "PkTabBarItemCellIdentifier"

private class PKTabBar: UITableViewController {
    fileprivate var items = [PKTabBarItem]() {
        didSet {
            tableView.reloadData()
        }
    }
    fileprivate var backgroundColor: UIColor = .white {
        didSet {
            view.backgroundColor = backgroundColor
        }
    }

    private override func viewDidLoad() {
        super.viewDidLoad()

        tableView.isScrollEnabled = false
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40));
        tableView.estimatedRowHeight = 40
        tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
//        self.tableView.separatorStyle = .None
        tableView.register(PkTabBarItemTableViewCell.self, forCellReuseIdentifier: pkTabBarItemCellIdentifier)
    }

    private override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    private override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: pkTabBarItemCellIdentifier, for: indexPath) as! PkTabBarItemTableViewCell

        if items.count > indexPath.row {
            let item = items[indexPath.row]
            cell.titleLabel.text = item.title
            cell.iconImageView.image = item.image
        }

        return cell;
    }
}

private class PkTabBarItemTableViewCell: UITableViewCell {
    fileprivate let titleLabel = UILabel()
    fileprivate let iconImageView = UIImageView()

    fileprivate override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentHuggingPriority(249, for: .vertical)
        titleLabel.textAlignment = .center

        iconImageView.contentMode = .center
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(iconImageView)

        let views: [String: UIView] = ["titleLabel": titleLabel, "iconImageView": iconImageView]

//        self.contentView.preservesSuperviewLayoutMargins = true
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[iconImageView]-5-[titleLabel]-5-|", options: .directionLeadingToTrailing, metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[iconImageView]|", options: .directionLeadingToTrailing, metrics: nil, views: views));
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[titleLabel]|", options: .directionLeadingToTrailing, metrics: nil, views: views));
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private class PKMasterViewController: UIViewController {

    private(set) var widthConstraint: NSLayoutConstraint!

    fileprivate init() {
        super.init(nibName: nil, bundle: nil)
    }

    private override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = "Master"
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        label.topAnchor.constraint(equalTo: view.topAnchor, constant: 32).isActive = true
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setWidthConstraint(_ constraint: NSLayoutConstraint) {
        if widthConstraint != nil {
            widthConstraint = constraint
        }
    }

}
private class PKDetailViewController: UIViewController {

    fileprivate init() {
        super.init(nibName: nil, bundle: nil)
    }

    private override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.text = "Detail"
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        label.topAnchor.constraint(equalTo: view.topAnchor, constant: 32).isActive = true
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    fileprivate init(source: UIView, target: UIView, targetX: NSLayoutConstraint, targetViewWidth: CGFloat, tabBarWidth: CGFloat) {
        sourceView = source
        targetView = target
        xConstraint = targetX
        viewWidth = targetViewWidth
        leftOffset = tabBarWidth

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
