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
    public let selectedImage: UIImage?
    /// Navigation Bar item image
    public let navigationBarImage: UIImage?
    /// Navigation Bar item image – selected state
    public let navigationBarSelectedImage: UIImage?
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

    private var sideNavigationBarViewController: UIViewController?

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
            if hideTabBar {
                addNavigationSideBar()
            }
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
                        self.addNavigationSideBar()
                        self.mainView.hideTabBarView = true
                    })
                } else {
                    coordinator.animate(alongsideTransition: { (_) in
                        self.mainView.hideTabBarView = false
                        self.removeNavigationSideBar()
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

    private func addNavigationSideBar() {
        let navVC = configureNavigationBar(tabBar.items, tabBar.didSelectCallback!)
        sideNavigationBarViewController = navVC
        addChildViewController(navVC)
        mainView.addNavigationBar(navVC.view)
    }
    private func removeNavigationSideBar() {
        guard let navVC = sideNavigationBarViewController else { return }

        navVC.removeFromParentViewController()
        self.mainView.removeNavigationBar(navVC.view)
        sideNavigationBarViewController = nil
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


private let pkTabBarItemCellIdentifier = "PkTabBarItemCellIdentifier"
private let pkSideBarTabBarItemCellIdentifier = "PkSideBarTabBarItemCellIdentifier"

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

private class PKTabBarAsSideBar: PKTabBar {

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
        titleLabel.setContentHuggingPriority(249, for: .vertical)
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
        titleLabel.setContentHuggingPriority(249, for: .vertical)
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
