//
//  TabbedSplitViewController.swift
//
//  Created by Pavel Kazantsev on 29/06/15.
//  Copyright (c) 2015 Pavel Kazantsev. All rights reserved.
//

import UIKit

public typealias TabBarAction = () -> Void
public typealias ConfigureNavigationBar = ([PKTabBarItem<UIViewController>], [PKTabBarItem<TabBarAction>], @escaping (PKTabBarItem<UIViewController>) -> Void, ((PKTabBarItem<TabBarAction>) -> Void)?) -> UIViewController

public struct PKTabBarItem<T> {

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
    /// An action value that will be passed to the `OnSelection` callback
    ///
    /// Default types are `UIViewController` for the main tab bar and
    ///   `TabBarAction` closure for the action bar.
    public let action: T

    ///
    public init(title: String, image: UIImage, selectedImage: UIImage? = nil, navigationBarImage: UIImage? = nil, navigationBarSelectedImage: UIImage? = nil, action: T) {
        self.title = title
        self.image = image
        self.selectedImage = selectedImage
        self.action = action

        self.navigationBarImage = navigationBarImage
        self.navigationBarSelectedImage = navigationBarSelectedImage
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
        /// Color of a detail view area when there's no detail view open. **Default – .white**.
        public var detailBackgroundColor: UIColor = .white
        /// Color of a vertical separator between tab bar and master view,
        ///   between master view and detail view.
        ///
        /// **Default – .gray**.
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

        fileprivate static let zero: Configuration = Configuration(tabBarWidth: 0, masterViewWidth: 0, detailViewMinWidth: 0, tabBarBackgroundColor: .white, detailBackgroundColor: .white, verticalSeparatorColor: .gray, showTabBarAsSideBarWithSizeChange: nil, showMasterAsSideBarWithSizeChange: nil, showDetailAsModalWithSizeChange: nil)
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
    public var configureNavigationBar: ConfigureNavigationBar = { items, actionItems, callback, actionCallback in
        let vc = PKTabBarAsSideBar()
        vc.items = items
        vc.actionItems = actionItems
        vc.didSelectCallback = callback
        vc.actionSelectedCallback = actionCallback
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

    public init(items: [PKTabBarItem<UIViewController>], actionItems: [PKTabBarItem<TabBarAction>] = []) {
        mainView = PKTabbedSplitView(tabBarView: tabBarVC.view, masterView: masterVC.view, detailView: detailVC.view)

        super.init(nibName: nil, bundle: nil)

        tabBarVC.tabBar.items = items
        tabBarVC.actionsBar.items = actionItems
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
            let isTheSameItem = (item.action == self.masterVC.viewController)
            if !isTheSameItem {
                self.masterVC.viewController = item.action

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
                    self.tabBarVC.tabBar.isOpen = true
                } else if isTheSameItem {
                    self.mainView.hideSideBar()
                    self.tabBarVC.tabBar.isOpen = false
                } else {
                    self.tabBarVC.tabBar.isOpen = true
                }
            }
        }
        tabBarVC.actionsBar.didSelectCallback = { [unowned self] item in
            if self.mainView.hideTabBarView {
                self.mainView.hideSideBar()
            }
            item.action()
        }

        addChildViewController(tabBarVC)
        addChildViewController(masterVC)
        addChildViewController(detailVC)

        masterVC.setWidthConstraint(mainView.masterViewWidthConstraint)

        update(oldConfig: .zero)

        view.backgroundColor = .white
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
        let navVC = configureNavigationBar(tabBarVC.tabBar.items, tabBarVC.actionsBar.items, tabBarVC.tabBar.didSelectCallback!, tabBarVC.actionsBar.didSelectCallback!)
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

    /// Add an item with a view controller to open to the main tab bar
    /// - parameters:
    ///   - item: A tab bar item with a view controller as an action
    public func addToTabBar(_ item: PKTabBarItem<UIViewController>) {
        tabBarVC.tabBar.items.append(item)
    }
    /// Add an item with a closure to the bottom action bar
    /// - parameters:
    ///   - item: A tab bar item with a closure as an action
    public func addToActionBar(_ item: PKTabBarItem<TabBarAction>) {
        tabBarVC.actionsBar.items.append(item)
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
        if config.detailBackgroundColor != oldConfig.detailBackgroundColor {
            detailVC.backgroundColor = config.detailBackgroundColor
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

    fileprivate let tabBar = PKTabBarTabsList<UIViewController>()
    fileprivate let actionsBar = PKTabBarTabsList<TabBarAction>()

    fileprivate var shouldAddVerticalSeparator: Bool = true
    fileprivate var verticalSeparatorColor: UIColor = .gray {
        didSet {
            verticalSeparator.backgroundColor = verticalSeparatorColor
        }
    }
    fileprivate var backgroundColor: UIColor = .white {
        didSet {
            view.backgroundColor = backgroundColor
        }
    }

    private let verticalSeparator = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = backgroundColor

        actionsBar.isCompact = true

        addChildViewController(tabBar)
        addChildView(tabBar.view, bottom: false)
        addChildViewController(actionsBar)
        addChildView(actionsBar.view, top: false)

        tabBar.view.bottomAnchor.constraint(equalTo: actionsBar.view.topAnchor, constant: 8.0).isActive = true

        view.layoutIfNeeded()
        tabBar.didMove(toParentViewController: self)
        actionsBar.didMove(toParentViewController: self)

        tabBar.view.backgroundColor = nil
        tabBar.shouldDisplayArrow = true
        actionsBar.view.backgroundColor = nil
        // Should not change color when selected
        actionsBar.view.tintColor = .black
        actionsBar.shouldDisplayArrow = false

        if shouldAddVerticalSeparator {
            view.addVerticalSeparator(verticalSeparator, color: verticalSeparatorColor)
        }
    }
}
private class PKTabBarTabsList<Action>: UITableViewController {
    fileprivate var items = [PKTabBarItem<Action>]() {
        didSet {
            tableView.reloadData()
        }
    }
    fileprivate var isOpen: Bool = false {
        didSet {
            if shouldDisplayArrow, let cell = tableView.cellForRow(at: IndexPath(row: selectedItemIndex, section: 0)) as? PKTabBarItemTableViewCell {
                cell.isOpen = isOpen
            }
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
            if selectedItemIndex != oldValue {
                tableView.selectRow(at: IndexPath(row: selectedItemIndex, section: 0), animated: true, scrollPosition: .none)
            }
        }
    }
    /// The view is shrinked to the size of the tabs
    fileprivate var isCompact: Bool = false
    fileprivate var didSelectCallback: ((PKTabBarItem<Action>) -> Void)?
    fileprivate var shouldDisplayArrow = true

    private var heightConstraint: NSLayoutConstraint? = nil

    fileprivate override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "Tab Bar View"

        tableView.isScrollEnabled = false
        tableView.estimatedRowHeight = 40
        tableView.separatorStyle = .none

        if isCompact {
            heightConstraint = view.heightAnchor.constraint(equalToConstant: 44.0)
            heightConstraint?.isActive = true
        } else {
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 32))
        }

        registerCells()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if selectedItemIndex >= 0, items.count > selectedItemIndex {
            tableView.selectRow(at: IndexPath(row: selectedItemIndex, section: 0), animated: true, scrollPosition: .none)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isCompact, let constraint = heightConstraint {
            let newHeight = tableView.contentSize.height + 16.0
            if constraint.constant != newHeight {
                constraint.constant = newHeight
                view.setNeedsLayout()
            }
        }
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
            cell.shouldDisplayArrow = shouldDisplayArrow
            cell.titleLabel.text = item.title
            cell.iconImageView.image = item.image
            // TODO: Add an image for selected state
        }

        return cell
    }

    fileprivate override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItemIndex = indexPath.row
    }
}

private class PKTabBarAsSideBar: PKTabBarTabsList<UIViewController> {

    fileprivate var actionItems: [PKTabBarItem<TabBarAction>] = []
    fileprivate var actionSelectedCallback: ((PKTabBarItem<TabBarAction>) -> Void)?

    fileprivate override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "Tab Bar Side Bar View"
    }

    fileprivate override func registerCells() {
        tableView.register(PKSideTabBarItemTableViewCell.self, forCellReuseIdentifier: pkSideBarTabBarItemCellIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return actionItems.isEmpty ? 1 : 2
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
        return actionItems.count
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "___"
        }
        return nil
    }

    fileprivate override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: pkSideBarTabBarItemCellIdentifier, for: indexPath) as! PKSideTabBarItemTableViewCell

        if indexPath.section == 0, items.count > indexPath.row {
            let item = items[indexPath.row]
            configureCell(cell, for: item)
        }
        if indexPath.section == 1, actionItems.count > indexPath.row {
            let item = actionItems[indexPath.row]
            configureCell(cell, for: item)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            super.tableView(tableView, didSelectRowAt: indexPath)
        } else if actionItems.count > indexPath.row {
            let item = actionItems[indexPath.row]
            actionSelectedCallback?(item)
        }
    }

    private func configureCell<T>(_ cell: PKSideTabBarItemTableViewCell, for item: PKTabBarItem<T>) {
        cell.shouldDisplayArrow = false
        cell.titleLabel.text = item.title
        cell.iconImageView.image = item.navigationBarImage ?? item.image
        // TODO: Add an image for selected state
    }
}

private class PKTabBarItemTableViewCell: UITableViewCell {
    fileprivate let titleLabel = UILabel().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    fileprivate let iconImageView = UIImageView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    fileprivate let arrowImageView = UIImageView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.alpha = 0.0
        $0.contentMode = .center
        $0.tintColor = nil
    }
    fileprivate var shouldDisplayArrow = true {
        didSet {
            arrowImageView.isHidden = !shouldDisplayArrow
        }
    }
    fileprivate var isOpen = false {
        didSet {
            if shouldDisplayArrow {
                arrowImageView.image = isOpen ? closeArrowImage : openArrowImage
            }
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        titleLabel.textColor = isSelected ? self.tintColor : .black
    }

    private lazy var openArrowImage = UIImage(named: "Tab Bar Arrow Open", in: Bundle(for: PKTabBarItemTableViewCell.self), compatibleWith: nil)
    private lazy var closeArrowImage = UIImage(named: "Tab Bar Arrow Close", in: Bundle(for: PKTabBarItemTableViewCell.self), compatibleWith: nil)

    fileprivate override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureLabel()
        configureImageView()

        contentView.addSubview(titleLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(arrowImageView)

        addConstraints()

        configureCell()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        arrowImageView.alpha = 0.0
        iconImageView.tintColor = nil
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        let doSelect = {
            self.arrowImageView.alpha = selected ? 1.0 : 0.0
            self.titleLabel.textColor = selected ? self.tintColor : .black
            self.iconImageView.tintColor = selected ? self.tintColor : .black
            //iconImageView.image = selected ? selectedImage : image
        }
        if animated {
            UIView.animate(withDuration: 0.32, animations: doSelect)
        } else {
            doSelect()
        }
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

        let constraints: [[NSLayoutConstraint]] = [
            .constraints(withVisualFormat: "V:|-5-[iconImageView]-5-[titleLabel]-5-|", views: views),
            .constraints(withVisualFormat: "H:|[iconImageView]|", options: .directionLeadingToTrailing, views: views),
            .constraints(withVisualFormat: "H:|[titleLabel]|", options: .directionLeadingToTrailing, views: views)
        ]

        NSLayoutConstraint.activate(constraints.flatMap { $0 } + [
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6.0),
            arrowImageView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor)
        ])
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

        let constraints: [[NSLayoutConstraint]] = [
            .constraints(withVisualFormat: "H:|-[iconImageView]-[titleLabel]-|", options: .directionLeadingToTrailing, views: views),
            .constraints(withVisualFormat: "V:|-[iconImageView(24)]-|", views: views),
            .constraints(withVisualFormat: "V:|-[titleLabel]-|", views: views)
        ]
        NSLayoutConstraint.activate(constraints.flatMap { $0 })
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
                    view.addVerticalSeparator(verticalSeparator, color: verticalSeparatorColor)
                }
                view.layoutIfNeeded()
                next.didMove(toParentViewController: self)
            }
        }
    }
    private(set) var widthConstraint: NSLayoutConstraint!
    fileprivate var shouldAddVerticalSeparator: Bool = true
    fileprivate var verticalSeparatorColor: UIColor = .gray {
        didSet {
            verticalSeparator.backgroundColor = verticalSeparatorColor
        }
    }
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
        view.backgroundColor = .white
    }

    fileprivate func setWidthConstraint(_ constraint: NSLayoutConstraint) {
        if widthConstraint != nil {
            widthConstraint = constraint
        }
    }

}
private class PKDetailViewController: UIViewController {

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

}
