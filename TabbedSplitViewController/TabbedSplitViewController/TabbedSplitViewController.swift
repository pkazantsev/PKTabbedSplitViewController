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
    /// Tab Bar item image
    public let image: UIImage
    /// Tab Bar item image – selected state
    public var selectedImage: UIImage?
    /// Navigation Bar item image
    public var navigationBarImage: UIImage?
    /// Navigation Bar item image – selected state
    public var navigationBarSelectedImage: UIImage?
    /// View controller that should be opened by tap on the item
    public let viewController: UIViewController

    ///
    public init(with viewController: UIViewController, title: String, image: UIImage, selectedImage: UIImage? = nil, navigationBarImage: UIImage? = nil, navigationBarSelectedImage: UIImage? = nil) {
        self.title = title
        self.image = image
        self.selectedImage = selectedImage
        self.viewController = viewController

        self.navigationBarImage = navigationBarImage
        self.navigationBarSelectedImage = navigationBarSelectedImage
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
        /// Color of a vertical separator between tab bar and master view,
        ///   between master view and detail view.
        ///
        /// **Default – .white**.
        public var verticalSeparatorColor: UIColor = .gray

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

        fileprivate static let zero: Configuration = Configuration(tabBarWidth: 0, masterViewWidth: 0, detailViewMinWidth: 0, tabBarBackgroundColor: .white, verticalSeparatorColor: .gray, showTabBarAsSideBarWithSizeChange: nil, showMasterAsSideBarWithSizeChange: nil, showDetailAsModalWithSizeChange: nil)
    }

    /// Tabbed Split View Controller Configuration
    public var config = Configuration() {
        didSet {
            update(oldConfig: oldValue)
        }
    }

    /// This block returns a configured View Controller for a case when
    /// a tab bar is hidden and a slidable navigation bar is used instead.
    /// Accepts an array of items to configure the navigation view controller,
    /// and a callback that should be called when an item is selected
    public var configureNavigationBar: (_ items: [PKTabBarItem], _ didSelectCallback: @escaping (PKTabBarItem) -> Void) -> UIViewController = { items, callback in
        let vc = PKTabBarAsSideBar()
        vc.items = items
        vc.didSelectCallback = callback
        return vc
    }

    public var logger: DebugLogger? {
        didSet {
            mainView.logger = logger
        }
    }

    private weak var detailViewController: UIViewController?

    private let masterVC = PKMasterViewController()
    private let detailVC = PKDetailViewController()
    private let tabBarVC = PKTabBar()
    private let mainView: PKTabbedSplitView

    private var futureTraits: UITraitCollection?
    private var futureSize: CGSize?

    private var sideNavigationBarViewController: UIViewController?

    public init(items: [PKTabBarItem]) {
        mainView = PKTabbedSplitView(tabBarView: tabBarVC.view, masterView: masterVC.view, detailView: detailVC.view)

        super.init(nibName: nil, bundle: nil)

        tabBarVC.tabBar.items = items
    }

    public required init?(coder aDecoder: NSCoder) {
        mainView = PKTabbedSplitView(tabBarView: tabBarVC.view, masterView: masterVC.view, detailView: detailVC.view)

        super.init(coder: aDecoder)
    }

    public override func loadView() {
        view = mainView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tabBarVC.tabBar.didSelectCallback = { [unowned self] item in
            let isTheSameItem = (item.viewController == self.masterVC.viewController)
            if !isTheSameItem {
                self.masterVC.viewController = item.viewController

                self.logger?.log("Hide tab bar: \(self.mainView.hideTabBarView)")
                self.logger?.log("Hide master view: \(self.mainView.hideMasterView)")
            }
            if self.mainView.hideTabBarView {
                // Hide navigation view while opening a detail
                self.mainView.hideSideBar()
            }
            else if self.mainView.hideMasterView {
                if self.mainView.sideBarIsHidden {
                    self.mainView.showSideBar()
                } else if isTheSameItem {
                    self.mainView.hideSideBar()
                }
            }
        }

        addChildViewController(tabBarVC)
        addChildViewController(masterVC)
        addChildViewController(detailVC)

        masterVC.setWidthConstraint(mainView.masterViewWidthConstraint)

        update(oldConfig: .zero)

        view.backgroundColor = .gray

        tabBarVC.backgroundColor = .purple
        masterVC.view.backgroundColor = .green
        detailVC.view.backgroundColor = .blue
    }

    public override func viewWillAppear(_ animated: Bool) {
        let shouldAnimate = UIView.areAnimationsEnabled
        // Disable animations so that first layout is not animated.
        UIView.setAnimationsEnabled(false)

        let screenSize = futureSize ?? view.frame.size
        let traits = futureTraits ?? traitCollection

        // This method will be called also when user changes the split-screen mode
        //   from narrow to wide, if there was detail view open as a modal.

        if let hideTabBar = config.showTabBarAsSideBarWithSizeChange?(screenSize, traits, config) {
            // Update only if it's changed
            if mainView.hideTabBarView != hideTabBar {
                mainView.hideTabBarView = hideTabBar
                if hideTabBar {
                    addNavigationSideBar()
                }
            }
        }
        tabBarVC.didMove(toParentViewController: self)

        if let hideMaster = config.showMasterAsSideBarWithSizeChange?(screenSize, traits, config) {
            // Update only if it's changed
            if mainView.hideMasterView != hideMaster {
                mainView.hideMasterView = hideMaster
                if hideMaster {
                    mainView.addMasterSideBar()
                }
            }
        }
        masterVC.didMove(toParentViewController: self)

        // Hide detail from main view if there is not enough width
        if let hideDetail = config.showDetailAsModalWithSizeChange?(screenSize, traits, config) {
            if mainView.hideDetailView != hideDetail {
                mainView.hideDetailView = hideDetail
                if hideDetail {
                    mainView.removeDetailView()
                }
            }
        }
        detailVC.didMove(toParentViewController: self)

        tabBarVC.tabBar.selectedItemIndex = 0

        UIView.setAnimationsEnabled(shouldAnimate)
        super.viewWillAppear(animated)
    }

    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        logger?.log("\(newCollection)")
        futureTraits = newCollection
    }
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        logger?.log("\(size)")
        futureSize = size
        var hideDetail = false
        var hideMaster = false
        var hideTabBar = false

        let traits = futureTraits ?? traitCollection
        if let hideDetailFunc = config.showDetailAsModalWithSizeChange {
            hideDetail = hideDetailFunc(size, traits, config)
            logger?.log("hide detail view: \(hideDetail)")
        }
        if let hideMasterFunc = config.showMasterAsSideBarWithSizeChange {
            hideMaster = hideMasterFunc(size, traits, config)
            logger?.log("hide master view: \(hideMaster)")
        }
        if hideDetail && hideMaster {
            logger?.log("We can't hide master and details at the same time!", level: .error, #function, #line)
        } else if let hideTabBarFunc = config.showTabBarAsSideBarWithSizeChange {
            hideTabBar = hideTabBarFunc(size, traits, config)
            logger?.log("hide Tab Bar: \(hideTabBar)")
        }
        let updateDetail = mainView.hideDetailView != hideDetail
        let updateMaster = mainView.hideMasterView != hideMaster
        let updateTabBar = mainView.hideTabBarView != hideTabBar

        guard updateDetail || updateMaster || updateTabBar else { return }

        if updateMaster, !hideMaster {
            mainView.hideMasterView = false
        }
        if updateDetail, !hideDetail, let detail = detailViewController {
            dismiss(animated: false) {
                self.detailVC.viewController = detail
            }
        }

        coordinator.animate(alongsideTransition: { _ in
            // First, adding to the Stack view
            if updateTabBar, !hideTabBar {
                self.removeNavigationSideBar()
            }
            if updateMaster, !hideMaster {
                self.mainView.removeMasterSideBar()
            }
            if updateDetail, !hideDetail {
                self.mainView.addDetailView()
            }
            // Then, removing from the stack view
            if updateTabBar, hideTabBar {
                self.addNavigationSideBar()
            }
            if updateMaster, hideMaster, !hideDetail {
                self.mainView.addMasterSideBar()
            }
        }, completion: { _ in
            if updateMaster, hideMaster, !hideDetail {
                self.mainView.hideMasterView = true
            }
            if updateTabBar {
                self.mainView.hideTabBarView = hideTabBar
            }
            if updateDetail {
                self.mainView.hideDetailView = hideDetail
                if hideDetail {
                    self.mainView.removeDetailView()
                    self.presentDetailAsModal()
                }
            }
        })

        futureTraits = nil
    }

    private func presentDetailAsModal() {
        guard let detail = detailViewController else { return }

        detailVC.viewController = nil
        detail.view.translatesAutoresizingMaskIntoConstraints = true
        self.present(detail, animated: false)
    }

    private func addNavigationSideBar() {
        let navVC = configureNavigationBar(tabBarVC.tabBar.items, tabBarVC.tabBar.didSelectCallback!)
        sideNavigationBarViewController = navVC
        addChildViewController(navVC)
        mainView.addNavigationBar(navVC.view)
        navVC.didMove(toParentViewController: self)
    }
    private func removeNavigationSideBar() {
        guard let navVC = sideNavigationBarViewController else { return }

        navVC.willMove(toParentViewController: nil)
        self.mainView.removeNavigationBar(navVC.view)
        navVC.removeFromParentViewController()
        sideNavigationBarViewController = nil
    }

    public override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        // Show Detail screen if needed
        if mainView.hideDetailView {
            // Hide master view while opening a detail
            mainView.hideSideBar()

            show(vc, sender: sender)
        } else {
            if mainView.hideMasterView {
                // Hide master view while opening a detail
                mainView.hideSideBar()
            }
            detailVC.viewController = vc
        }
        detailViewController = vc
    }

    public func dismissDetailViewController(animated flag: Bool = true) {
        if mainView.hideDetailView {
            dismiss(animated: flag)
        }
        else if detailVC.viewController != nil {
            logger?.log("Removing presented detail VC from parent VC")
            detailVC.viewController = nil
        }
    }

    public func add(_ item: PKTabBarItem) {
        tabBarVC.tabBar.items.append(item)
    }

    private func update(oldConfig: Configuration) {
        if config.tabBarWidth != oldConfig.tabBarWidth {
            mainView.tabBarWidth = config.tabBarWidth
        }
        if config.masterViewWidth != oldConfig.masterViewWidth {
            mainView.masterViewWidth = config.masterViewWidth
        }
        if config.tabBarBackgroundColor != oldConfig.tabBarBackgroundColor {
            tabBarVC.backgroundColor = config.tabBarBackgroundColor
        }
        if config.verticalSeparatorColor != oldConfig.verticalSeparatorColor {
            tabBarVC.verticalSeparatorColor = config.verticalSeparatorColor
            masterVC.verticalSeparatorColor = config.verticalSeparatorColor
        }
    }

}


private let pkTabBarItemCellIdentifier = "PkTabBarItemCellIdentifier"
private let pkSideBarTabBarItemCellIdentifier = "PkSideBarTabBarItemCellIdentifier"

private class PKTabBar: UIViewController {

    fileprivate let tabBar = PKTabBarTabsList()

    fileprivate var shouldAddVerticalSeparator: Bool = true
    fileprivate var verticalSeparatorColor: UIColor = .gray
    fileprivate var backgroundColor: UIColor = .white {
        didSet {
            view.backgroundColor = backgroundColor
        }
    }

    private let verticalSeparator = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil

        addChildViewController(tabBar)
        addChildView(tabBar.view)
        view.layoutIfNeeded()
        tabBar.didMove(toParentViewController: self)

        if shouldAddVerticalSeparator {
            view.addVerticalSeparator(verticalSeparator, color: verticalSeparatorColor)
        }
    }
}
private class PKTabBarTabsList: UITableViewController {
    fileprivate var items = [PKTabBarItem]() {
        didSet {
            tableView.reloadData()
        }
    }

    /// Initial value: -1, don't select anything. Can not set -1 anytime later.
    fileprivate var selectedItemIndex: Int = -1 {
        didSet {
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

        view.backgroundColor = nil
        view.accessibilityIdentifier = "Tab Bar View"

        tableView.isScrollEnabled = false
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40))
        tableView.estimatedRowHeight = 40
        tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
//        self.tableView.separatorStyle = .none

        registerCells()
    }

    fileprivate func registerCells() {
        tableView.register(PKTabBarItemTableViewCell.self, forCellReuseIdentifier: pkTabBarItemCellIdentifier)
    }

    fileprivate override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    fileprivate override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: pkTabBarItemCellIdentifier, for: indexPath) as! PKTabBarItemTableViewCell

        if items.count > indexPath.row {
            let item = items[indexPath.row]
            cell.titleLabel.text = item.title
            cell.iconImageView.image = item.image
            // TODO: Add an image for selected state
        }

        return cell
    }

    fileprivate override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectCallback?(items[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

private class PKTabBarAsSideBar: PKTabBarTabsList {

    fileprivate override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "Tab Bar Side Bar View"
    }

    fileprivate override func registerCells() {
        tableView.register(PKSideTabBarItemTableViewCell.self, forCellReuseIdentifier: pkSideBarTabBarItemCellIdentifier)
    }

    fileprivate override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: pkSideBarTabBarItemCellIdentifier, for: indexPath) as! PKSideTabBarItemTableViewCell

        if items.count > indexPath.row {
            let item = items[indexPath.row]
            cell.titleLabel.text = item.title
            cell.iconImageView.image = item.navigationBarImage ?? item.image
            // TODO: Add an image for selected state
        }

        return cell
    }
}

private class PKTabBarItemTableViewCell: UITableViewCell {
    fileprivate let titleLabel = UILabel().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    fileprivate let iconImageView = UIImageView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    fileprivate override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureLabel()
        configureImageView()

        contentView.addSubview(titleLabel)
        contentView.addSubview(iconImageView)

        addConstraints()

        configureCell()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func configureCell() {
        selectionStyle = .none
    }

    fileprivate func configureLabel() {
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)
        titleLabel.textAlignment = .center
    }

    fileprivate func configureImageView() {
        iconImageView.contentMode = .center
    }

    fileprivate func addConstraints() {
        let views: [String: UIView] = ["titleLabel": titleLabel, "iconImageView": iconImageView]

        contentView.addConstraints(.constraints(withVisualFormat: "V:|-5-[iconImageView]-5-[titleLabel]-5-|", options: [], metrics: nil, views: views))
        contentView.addConstraints(.constraints(withVisualFormat: "H:|[iconImageView]|", options: .directionLeadingToTrailing, metrics: nil, views: views))
        contentView.addConstraints(.constraints(withVisualFormat: "H:|[titleLabel]|", options: .directionLeadingToTrailing, metrics: nil, views: views))
    }

}

private class PKSideTabBarItemTableViewCell: PKTabBarItemTableViewCell {

    fileprivate override func configureLabel() {
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)
    }

    fileprivate override func configureImageView() {
        iconImageView.contentMode = .scaleAspectFit
    }

    fileprivate override func addConstraints() {
        let views: [String: UIView] = ["titleLabel": titleLabel, "iconImageView": iconImageView]

        contentView.addConstraints(.constraints(withVisualFormat: "H:|-[iconImageView]-[titleLabel]-|", options: .directionLeadingToTrailing, metrics: nil, views: views))
        contentView.addConstraints(.constraints(withVisualFormat: "V:|-[iconImageView(24)]-|", options: [], metrics: nil, views: views))
        contentView.addConstraints(.constraints(withVisualFormat: "V:|-[titleLabel]-|", options: [], metrics: nil, views: views))
    }

}

private class PKMasterViewController: UIViewController {

    fileprivate var viewController: UIViewController? {
        didSet {
            if let prev = oldValue {
                prev.willMove(toParentViewController: nil)
                prev.view.removeFromSuperview()
                prev.removeFromParentViewController()
            }
            if let next = viewController {
                addChildViewController(next)
                addChildView(next.view)
                if shouldAddVerticalSeparator {
                    view.addVerticalSeparator(verticalSeparator)
                }
                view.layoutIfNeeded()
                next.didMove(toParentViewController: self)
            }
        }
    }
    private(set) var widthConstraint: NSLayoutConstraint!
    fileprivate var shouldAddVerticalSeparator: Bool = true
    fileprivate var verticalSeparatorColor: UIColor = .gray
    private let verticalSeparator = UIView()

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
            if let prev = oldValue {
                prev.willMove(toParentViewController: nil)
                prev.view.removeFromSuperview()
                prev.removeFromParentViewController()
            }
            if let next = viewController {
                addChildViewController(next)
                addChildView(next.view)
                next.didMove(toParentViewController: self)
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
