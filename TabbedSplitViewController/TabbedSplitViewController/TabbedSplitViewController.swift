//
//  TabbedSplitViewController.swift
//
//  Created by Pavel Kazantsev on 29/06/15.
//  Copyright (c) 2015 Pavel Kazantsev. All rights reserved.
//

import UIKit

public typealias TabBarAction = () -> Void
public typealias ConfigureNavigationBar = ([PKTabBarItem<UIViewController>], [PKTabBarItem<TabBarAction>], @escaping (PKTabBarItem<UIViewController>, Int) -> Void, ((PKTabBarItem<TabBarAction>, Int) -> Void)?, Int) -> UIViewController

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

// MARK: - Main view controller

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
    public var config: Configuration {
        didSet {
            update(oldConfig: oldValue)
        }
    }

    /// This block returns a configured View Controller for a case when
    /// a tab bar is hidden and a slidable navigation bar is used instead.
    /// Accepts an array of items to configure the navigation view controller,
    /// and a callback that should be called when an item is selected
    public var configureNavigationBar: ConfigureNavigationBar = { items, actionItems, callback, actionCallback, selectedItemIndex in
        let vc = PKTabBarAsSideBar()
        vc.items = items
        vc.actionItems = actionItems
        vc.didSelectCallback = callback
        vc.actionSelectedCallback = actionCallback
        vc.selectedItemIndex = selectedItemIndex
        return vc
    }

    public var logger: DebugLogger? {
        didSet {
            mainView.logger = logger
        }
    }

    /// Currently open detail view controller
    public private(set) var detailViewController: UIViewController?

    public var selectedTabBarItemIndex: Int = -1 {
        didSet {
            // Double check – the same check is done on tab bar level.
            guard selectedTabBarItemIndex >= 0 || selectedTabBarItemIndex < tabBarVC.tabBar.items.count else {
                selectedTabBarItemIndex = oldValue
                return
            }
            if tabBarVC.tabBar.selectedItemIndex != selectedTabBarItemIndex {
                tabBarVC.tabBar.selectedItemIndex = selectedTabBarItemIndex
            }
        }
    }

    /// A view controller that, if set, will be displayed as a detail screen
    ///   before a detail screen opened and after a detail screen closed.
    public var defaultDetailViewController: UIViewController? {
        didSet {
            detailVC.defaultViewController = self.defaultDetailViewController
        }
    }

    private let masterVC = PKMasterViewController()
    private let detailVC = PKDetailViewController()
    private let tabBarVC = PKTabBar()
    private let mainView: PKTabbedSplitView

    private var futureTraits: UITraitCollection?
    private var futureSize: CGSize?
    private var sideNavigationBarViewController: UIViewController?

    // MARK: - Init

    public init(items: [PKTabBarItem<UIViewController>], actionItems: [PKTabBarItem<TabBarAction>] = [], config: Configuration? = nil) {
        self.config = config ?? Configuration()
        mainView = PKTabbedSplitView(tabBarView: tabBarVC.view, masterView: masterVC.view, detailView: detailVC.view)

        super.init(nibName: nil, bundle: nil)

        update(oldConfig: .zero)
        tabBarVC.tabBar.items = items
        tabBarVC.actionsBar.items = actionItems
    }

    public required init?(coder aDecoder: NSCoder) {
        self.config = Configuration()
        mainView = PKTabbedSplitView(tabBarView: tabBarVC.view, masterView: masterVC.view, detailView: detailVC.view)

        super.init(coder: aDecoder)
        update(oldConfig: .zero)
    }

    // MARK: - View lifecycle

    public override func loadView() {
        view = mainView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tabBarVC.tabBar.didSelectCallback = { [unowned self] item, selectedIndex in
            let isTheSameItem = (item.action == self.masterVC.viewController)
            if !isTheSameItem {
                self.selectedTabBarItemIndex = selectedIndex
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
        tabBarVC.actionsBar.didSelectCallback = { [unowned self] item, selectedIndex in
            if self.mainView.hideTabBarView {
                self.mainView.hideSideBar()
            }
            item.action()
            self.tabBarVC.actionsBar.selectedItemIndex = -1
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

        selectedTabBarItemIndex = 0

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
            tabBarVC.tabBar.shouldDisplayArrow = hideMaster
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
                self.detailVC.setViewController(detail, animate: false)
            }
        }

        tabBarVC.tabBar.shouldDisplayArrow = hideMaster

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

    // MARK: - Private functions

    private func presentDetailAsModal() {
        guard let detail = detailViewController, detail != defaultDetailViewController else { return }

        // Remove the view controller from the DetailVC, but keep it saved in TSVC
        detailVC.setViewController(nil, animate: false)
        detail.view.translatesAutoresizingMaskIntoConstraints = true
        self.present(detail, animated: false)
    }

    private func addNavigationSideBar() {
        let navVC = configureNavigationBar(tabBarVC.tabBar.items, tabBarVC.actionsBar.items, tabBarVC.tabBar.didSelectCallback!, tabBarVC.actionsBar.didSelectCallback!, selectedTabBarItemIndex)
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

    // MARK: - Public functions

    /// Use TabbedSplitViewController.showDetailViewController(_:completion:) instead.
    public override func showDetailViewController(_ vc: UIViewController, sender: Any? = nil) {
        showDetailViewController(vc, completion: nil)
    }
    public func showDetailViewController(_ vc: UIViewController, completion: (() -> Void)? = nil) {
        // Show Detail screen if needed
        if mainView.hideDetailView {
            // Hide master view while opening a detail
            mainView.hideSideBar()

            present(vc, animated: true, completion: completion)
        } else {
            if mainView.hideMasterView {
                // Hide master view while opening a detail
                mainView.hideSideBar()
            }
            detailVC.setViewController(vc, animate: true, completion: completion)
        }
        self.detailViewController = vc
    }

    public func dismissDetailViewController(animated flag: Bool = true, completion: (() -> Void)? = nil) {
        if mainView.hideDetailView {
            dismiss(animated: flag, completion: completion)
        }
        else if detailViewController != nil {
            logger?.log("Removing presented detail VC from parent VC")
            detailVC.setViewController(nil, animate: true, completion: completion)
        }
        self.detailViewController = nil
    }

    /// Add an item with a view controller to open to the main tab bar
    /// - parameters:
    ///   - item: A tab bar item with a view controller as an action
    public func addToTabBar(_ item: PKTabBarItem<UIViewController>) {
        tabBarVC.tabBar.appendItem(item)
    }
    /// Insert an item with a view controller at a specific position on the tab bar
    /// - parameters:
    ///   - item: A tab bar item with a view controller as an action
    ///   - index: Position on the tab bar
    public func insertToTabBar(_ item: PKTabBarItem<UIViewController>, at index: Int) {
        guard index >= 0 && index < tabBarVC.tabBar.items.count else { return }
        tabBarVC.tabBar.insertItem(item, at: index)
    }
    public func removeFromTabBar(at index: Int) {
        guard index >= 0 && index < tabBarVC.tabBar.items.count else { return }
        tabBarVC.tabBar.removeItem(at: index)
    }
    /// Add an item with a closure to the bottom action bar
    /// - parameters:
    ///   - item: A tab bar item with a closure as an action
    public func addToActionBar(_ item: PKTabBarItem<TabBarAction>) {
        tabBarVC.actionsBar.appendItem(item)
    }
    /// Insert an item with a closure to the bottom action bar at a specific position on the tab bar
    /// - parameters:
    ///   - item: A tab bar item with a closure as an action
    ///   - index: Position on the action bar
    public func insertToActionBar(_ item: PKTabBarItem<TabBarAction>, at index: Int) {
        guard index >= 0 && index < tabBarVC.actionsBar.items.count else { return }
        tabBarVC.actionsBar.insertItem(item, at: index)
    }
    public func removeFromActionBar(at index: Int) {
        guard index >= 0 && index < tabBarVC.actionsBar.items.count else { return }
        tabBarVC.actionsBar.removeItem(at: index)
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

// MARK: - Master view controller

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

    fileprivate func setWidthConstraint(_ constraint: NSLayoutConstraint) {
        if widthConstraint != nil {
            widthConstraint = constraint
        }
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
            addChildViewController(next)
            addChildViewCentered(next.view)
        }
        oldVC?.willMove(toParentViewController: nil)

        let completion = { [unowned self] in
            oldVC?.removeFromParentViewController()
            oldVC?.view.removeFromSuperview()
            newVC?.didMove(toParentViewController: self)
            completion?()
        }
        view.layoutIfNeeded()

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
