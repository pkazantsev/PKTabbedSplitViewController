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

    ///
    public init(with viewController: UIViewController, title: String, image: UIImage, selectedImage: UIImage? = nil) {
        self.title = title
        self.image = image
        self.selectedImage = selectedImage;
        self.viewController = viewController
    }
}

public protocol PKDetailViewControllerPresenter {

    var viewController: UIViewController? { get set }

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

    private(set) var masterViewController: UIViewController? {
        didSet {
            self.masterVC.viewController = masterViewController
        }
    }
    private var detailViewController: UIViewController?

    private let masterVC = PKMasterViewController()
    private let detailVC = PKDetailViewController()
    private let tabBar = PKTabBar()
    private let mainView: PKTabbedSplitView

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

        tabBar.didSelectCallback = { [unowned self] item in
            let controller = item.viewController
            self.masterViewController = controller
        }

        addChildViewController(tabBar)
        addChildViewController(masterVC)
        //addChildViewController(detailVC)

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
                mainView.addMasterSideBar()
            }
        }
        // Hide detail from main view if there is not enough width
        if let hideDetail = config.showDetailAsModalWithSizeChange?(view.frame.size, traitCollection, config) {
            mainView.hideDetailView = hideDetail
            if !hideDetail {
                addChildViewController(detailVC)
            }
        }

        tabBar.selectedItemIndex = 0
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
        }
        if let hideMasterFunc = config.showMasterAsSideBarWithSizeChange {
            hideMaster = hideMasterFunc(size, traits, config)
            print("hide master view: \(hideMaster)")

            if mainView.hideMasterView != hideMaster {
                if !hideMaster {
                    coordinator.animate(alongsideTransition: { (_) in
                        self.mainView.removeMasterSideBar()
                        self.mainView.hideMasterView = false
                    }, completion: nil)
                } else if !hideDetail {
                    coordinator.animate(alongsideTransition: nil, completion: { (_) in
                        self.mainView.hideMasterView = true
                        self.mainView.addMasterSideBar()
                    })
                }
            }
        }
        if !(hideDetail && hideMaster), let hideTabBarFunc = config.showTabBarAsSideBarWithSizeChange {
            hideTabBar = hideTabBarFunc(size, traits, config)
            print("hide Tab Bar: \(hideTabBar)")

            if mainView.hideTabBarView != hideTabBar {
                if hideTabBar {
                    coordinator.animate(alongsideTransition: nil, completion: { (_) in
                        self.mainView.hideTabBarView = true
                    })
                } else {
                    coordinator.animate(alongsideTransition: { (_) in
                        self.mainView.hideTabBarView = false
                    }, completion: nil)
                }
            }
        }

        if mainView.hideDetailView != hideDetail {
            if hideDetail {
                coordinator.animate(alongsideTransition: nil, completion: { (_) in
                    self.mainView.removeDetailView()
                })
            } else {
                coordinator.animate(alongsideTransition: { (_) in
                    self.mainView.addDetailView()
                }, completion: nil)
            }
            mainView.hideDetailView = hideDetail
            if hideDetail {
                detailVC.removeFromParentViewController()
            }
        }

        futureTraits = nil
    }

    public override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        detailVC.viewController = vc

        // Show Detail screen if needed
        if mainView.hideDetailView {
//            present(detailVC, animated: true)
            show(detailVC, sender: nil)
        }
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
    var hierarchyIndex: Int {
        switch self {
        case .tabBar: return 2
        case .master: return 1
        case .detail: return 0
        }
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
        tabBarWidthConstraint = .init(item: tabBarView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: tabBarWidth)
        masterViewWidthConstraint = .init(item: masterView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: masterViewWidth)

        stackViewItems = [tabBarView, masterView, detailView]

        super.init(frame: CGRect())

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

    fileprivate func addDetailView() {
        let item = StackViewItem.detail
        let view = stackViewItems[item.index]
        stackView.insertSubview(view, at: item.hierarchyIndex)
        if item.index >= stackView.arrangedSubviews.count {
            stackView.addArrangedSubview(view)
        } else {
            stackView.insertArrangedSubview(view, at: item.index)
        }
    }
    fileprivate func removeDetailView() {
        let view = stackViewItems[StackViewItem.detail.index]
        stackView.removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    /// Creates a side bar then adds a master view there.
    /// Should be called after removing the view from the stack view!
    fileprivate func addMasterSideBar() {
        let view = stackViewItems[StackViewItem.master.index]
        stackView.removeArrangedSubview(view)
        stackView.insertSubview(view, at: StackViewItem.master.hierarchyIndex)

        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        let leadingConstraint = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -masterViewWidth)
        leadingConstraint.isActive = true

        let helper = SideBarGestureRecognizerHelper(source: self, target: view, targetX: leadingConstraint, targetViewWidth: masterViewWidth, tabBarWidth: tabBarWidth)
        sideBarGestRecHelper = helper
    }

    fileprivate func removeMasterSideBar() {
        sideBarGestRecHelper = nil
        let view = stackViewItems[StackViewItem.master.index]
        view.isHidden = true
        view.removeFromSuperview()
        stackView.insertSubview(view, at: StackViewItem.master.hierarchyIndex)
        stackView.insertArrangedSubview(view, at: StackViewItem.master.index)
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

    /// Initial value: -1, don't select anything. Can not set -1 anytime later.
    fileprivate var selectedItemIndex: Int = -1 {
        didSet {
            guard selectedItemIndex != oldValue else { return }

            if selectedItemIndex >= 0 || selectedItemIndex < items.count {
                didSelectCallback?(items[selectedItemIndex])
            } else {
                selectedItemIndex = 0
            }
        }
    }

    fileprivate var didSelectCallback: ((PKTabBarItem) -> Void)?

    fileprivate override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "Tab Bar View"

        tableView.isScrollEnabled = false
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40));
        tableView.estimatedRowHeight = 40
        tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
//        self.tableView.separatorStyle = .None
        tableView.register(PkTabBarItemTableViewCell.self, forCellReuseIdentifier: pkTabBarItemCellIdentifier)
    }

    fileprivate override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    fileprivate override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: pkTabBarItemCellIdentifier, for: indexPath) as! PkTabBarItemTableViewCell

        if items.count > indexPath.row {
            let item = items[indexPath.row]
            cell.titleLabel.text = item.title
            cell.iconImageView.image = item.image
        }

        return cell;
    }

    fileprivate override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectCallback?(items[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

private class PkTabBarItemTableViewCell: UITableViewCell {
    fileprivate let titleLabel = UILabel()
    fileprivate let iconImageView = UIImageView()

    fileprivate override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

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
        contentView.addConstraints(.constraints(withVisualFormat: "V:|-5-[iconImageView]-5-[titleLabel]-5-|", options: .directionLeadingToTrailing, metrics: nil, views: views))
        contentView.addConstraints(.constraints(withVisualFormat: "H:|[iconImageView]|", options: .directionLeadingToTrailing, metrics: nil, views: views));
        contentView.addConstraints(.constraints(withVisualFormat: "H:|[titleLabel]|", options: .directionLeadingToTrailing, metrics: nil, views: views));
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private class PKMasterViewController: UIViewController {

    fileprivate var viewController: UIViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let newViewController = viewController {
                addChildViewController(newViewController)
                addChildView(newViewController.view)
            }
        }
    }
    private(set) var widthConstraint: NSLayoutConstraint!

    fileprivate init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "Master View"
    }

    fileprivate func setWidthConstraint(_ constraint: NSLayoutConstraint) {
        if widthConstraint != nil {
            widthConstraint = constraint
        }
    }

}
private class PKDetailViewController: UIViewController, PKDetailViewControllerPresenter {

    fileprivate var viewController: UIViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let newViewController = viewController {
                addChildViewController(newViewController)
                addChildView(newViewController.view)
            }
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

fileprivate extension UIViewController {

    /// Add a view as a child to this view controller's view
    ///  attaching all sides.
    ///
    /// - Parameter childView: a child view that will take all parent's space
    fileprivate func addChildView(_ childView: UIView) {
        view.addSubview(childView)

        childView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            childView.leftAnchor.constraint(equalTo: view.leftAnchor),
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.rightAnchor.constraint(equalTo: view.rightAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        view.addConstraints(constraints)
    }

}

extension Array where Element: NSLayoutConstraint {

    static func constraints(withVisualFormat format: String, options opts: NSLayoutFormatOptions = [], metrics: [String : Any]?, views: [String : Any]) -> [NSLayoutConstraint] {
        return NSLayoutConstraint.constraints(withVisualFormat: format, options: opts, metrics: metrics, views: views)
    }
}
