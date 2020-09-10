//
//  TabbedSplitViewController.swift
//
//  Created by Pavel Kazantsev on 29/06/15.
//  Copyright (c) 2015 Pavel Kazantsev. All rights reserved.
//

import UIKit

public typealias TabBarAction = () -> Void
/**
 * vc: UIViewController instance to be displayed
 *
 * isFullWidth: declares that the tab opens a screen that takes all the space
 *   beside the tab bar that otherwise would show master and detail screens.
 */
public typealias TabBarScreenConfiguration = (vc: UIViewController, isFullWidth: Bool)
public typealias ConfigureNavigationBar = ([PKTabBarItem<TabBarScreenConfiguration>], [PKTabBarItem<TabBarAction>], @escaping (PKTabBarItem<TabBarScreenConfiguration>, Int) -> Void, ((PKTabBarItem<TabBarAction>, Int) -> Void)?, Int) -> UIViewController

private typealias State = (tabBarHidden: Bool, masterHidden: Bool, detailHidden: Bool)

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
    /// Default types are `TabBarScreenConfiguration` for the main tab bar
    ///   and `TabBarAction` closure for the action bar.
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

extension PKTabBarItem where T == TabBarScreenConfiguration {

    /// Convinience initializer for non-full-width view controllers
    public init(title: String, image: UIImage, selectedImage: UIImage? = nil, navigationBarImage: UIImage? = nil, navigationBarSelectedImage: UIImage? = nil, action vc: UIViewController) {
        self.title = title
        self.image = image
        self.selectedImage = selectedImage
        self.action = (vc: vc, isFullWidth: false)

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
        /// Set to true if you don't want the detail view be displayed as modal on
        ///   iPad in 1/3 split-view, but instead keep it in main view, and not
        ///   allow master and tab bar be displayed while detail is on.
        ///
        /// Is crucial on iPad when switching between split-view modes with an
        ///   app modal screen presented.
        ///
        /// **Default – false**.
        public var detailAsModalShouldStayInPlace: Bool = false

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

        static let zero: Configuration = Configuration(tabBarWidth: 0, masterViewWidth: 0, detailViewMinWidth: 0, tabBarBackgroundColor: .white, detailBackgroundColor: .white, verticalSeparatorColor: .gray, detailAsModalShouldStayInPlace: false, showTabBarAsSideBarWithSizeChange: nil, showMasterAsSideBarWithSizeChange: nil, showDetailAsModalWithSizeChange: nil)
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
        return SideBarWrapper(childVC: vc)
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
            masterDetailVC.defaultDetailViewController = self.defaultDetailViewController
        }
    }

    private let tabBarVC = PKTabBar()

    private let mainView: PKTabbedSplitView
    private let masterDetailVC: MasterDetailContentViewController
    private var currentContentVC: UIViewController

    private var configured: Bool = false

    private var futureTraits: UITraitCollection?
    private var futureSize: CGSize?

    private var sideBarViewController: UIViewController?

    private var state: State = (true, true, true)

    // MARK: - Init

    public init(items: [PKTabBarItem<TabBarScreenConfiguration>], actionItems: [PKTabBarItem<TabBarAction>] = [], config: Configuration? = nil) {
        self.config = config ?? Configuration()
        masterDetailVC = MasterDetailContentViewController()
        mainView = PKTabbedSplitView(tabBarView: tabBarVC.view, contentView: masterDetailVC.view)
        currentContentVC = masterDetailVC

        super.init(nibName: nil, bundle: nil)

        update(oldConfig: .zero)
        tabBarVC.tabBar.items = items
        tabBarVC.actionsBar.items = actionItems
    }

    public required init?(coder aDecoder: NSCoder) {
        self.config = Configuration()
        masterDetailVC = MasterDetailContentViewController()
        mainView = PKTabbedSplitView(tabBarView: tabBarVC.view, contentView: masterDetailVC.view)
        currentContentVC = masterDetailVC

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
            let isTheSameMasterVC = item.action.vc == self.masterDetailVC.masterViewController
            let itemChanged = (item.action.isFullWidth == (self.currentContentVC == self.masterDetailVC))
                                || !isTheSameMasterVC

            if itemChanged {
                self.selectedTabBarItemIndex = selectedIndex

                if item.action.isFullWidth {
                    self.replaceContent(with: item.action.vc)

                    if self.mainView.hideTabBarView || self.masterDetailVC.hideMasterView {
                        self.mainView.hideSideBar()
                    }
                    return
                }

                // Master-detail part until the end of the closure

                self.resetContentToMasterDetail()
                self.masterDetailVC.masterViewController = item.action.vc

                self.logger?.log("Hide tab bar: \(self.mainView.hideTabBarView)")
                self.logger?.log("Hide master view: \(self.masterDetailVC.hideMasterView)")
            }

            if self.mainView.hideTabBarView {
                // Hide navigation view while opening a detail
                self.mainView.hideSideBar()
            }
            else if self.masterDetailVC.hideMasterView {
                if self.mainView.sideBarIsHidden {
                    self.mainView.showSideBar()
                    self.tabBarVC.tabBar.isOpen = true
                } else if isTheSameMasterVC {
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

        addChild(tabBarVC)
        addChild(masterDetailVC)

        update(oldConfig: .zero)

        view.backgroundColor = .white
    }

    public override func viewWillAppear(_ animated: Bool) {
        if configured {
            super.viewWillAppear(animated)
            return
        }

        selectedTabBarItemIndex = 0

        let screenSize = view.frame.size.adjustedForSafeAreaInitially(logger)
        let traits = futureTraits ?? traitCollection

        var state: State = (tabBarHidden: true, masterHidden: true, detailHidden: true)

        if let hideTabBar = config.showTabBarAsSideBarWithSizeChange?(screenSize, traits, config) {
            // Update only if it's changed
            if mainView.hideTabBarView != hideTabBar {
                mainView.hideTabBarView = hideTabBar
                if hideTabBar {
                    addNavigationSideBar()
                }
            }
            state.tabBarHidden = hideTabBar
        }
        tabBarVC.didMove(toParent: self)

        if let hideMaster = config.showMasterAsSideBarWithSizeChange?(screenSize, traits, config) {
            // Update only if it's changed
            if self.masterDetailVC.hideMasterView != hideMaster {
                self.masterDetailVC.hideMasterView = hideMaster
                if hideMaster, let sideBar = self.masterDetailVC.prepareMasterForSideBar() {
                    self.addMasterSideBar(sideBar)
                    self.sideBarViewController = sideBar
                }
            }
            tabBarVC.tabBar.shouldDisplayArrow = hideMaster
            state.masterHidden = hideMaster
        }

        // Hide detail from main view if there is not enough width
        if let hideDetail = config.showDetailAsModalWithSizeChange?(screenSize, traits, config) {
            if self.masterDetailVC.hideDetailView != hideDetail {
                self.masterDetailVC.hideDetailView = hideDetail
                if hideDetail {
                    self.masterDetailVC.removeDetailView(removeFromViewHierarchy: !config.detailAsModalShouldStayInPlace)
                }
            }
            state.detailHidden = hideDetail
        }
        self.state = state

        tabBarVC.tabBarWidthConstraint.isActive = true
        tabBarVC.actionBarWidthConstraint.isActive = true
        self.masterDetailVC.masterViewWidthConstraint.isActive = true

        super.viewWillAppear(animated)
        configured = true
    }

    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        logger?.log("\(newCollection)")
        futureTraits = newCollection
    }
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        var (hideDetail, hideMaster, hideTabBar) = (false, false, false)
        var (updateDetail, updateMaster, updateTabBar) = (false, false, false)

        coordinator.animate(alongsideTransition: { _ in
            // Only here we could get our hand on the correct safe area values, not earlier
            let realSize = size.adjustedForSafeArea(of: self.view, self.logger)
            self.logger?.log("View is transitioning to \(realSize)")
            self.futureSize = realSize

            let traits = self.futureTraits ?? self.traitCollection
            if let hideDetailFunc = self.config.showDetailAsModalWithSizeChange {
                hideDetail = hideDetailFunc(realSize, traits, self.config)
                self.logger?.log("hide detail view: \(hideDetail)")
            }
            if let hideMasterFunc = self.config.showMasterAsSideBarWithSizeChange {
                hideMaster = hideMasterFunc(realSize, traits, self.config)
                self.logger?.log("hide master view: \(hideMaster)")
            }
            if hideDetail && hideMaster {
                self.logger?.log("We can't hide master and details at the same time!", level: .error, #function, #line)
            }
            else if let hideTabBarFunc = self.config.showTabBarAsSideBarWithSizeChange {
                hideTabBar = hideTabBarFunc(realSize, traits, self.config)
                self.logger?.log("hide Tab Bar: \(hideTabBar)")
            }
            updateDetail = self.masterDetailVC.hideDetailView != hideDetail
            updateMaster = self.masterDetailVC.hideMasterView != hideMaster
            updateTabBar = self.mainView.hideTabBarView != hideTabBar

            self.state = (hideTabBar, hideMaster, hideDetail)

            guard updateDetail || updateMaster || updateTabBar else { return }

            if updateMaster, !hideMaster {
                self.masterDetailVC.hideMasterView = false
            }
            if updateDetail, !hideDetail, !self.config.detailAsModalShouldStayInPlace {
                self.hideDetailAsModal()
            }

            let keepTabBarHidden = hideDetail && !hideTabBar && self.detailViewController != nil

            self.tabBarVC.tabBar.shouldDisplayArrow = hideMaster

            // First, adding to the Stack view
            if updateTabBar, !hideTabBar {
                self.removeNavigationSideBar(keepTabBarHidden: keepTabBarHidden)
            }
            if updateMaster, !hideMaster {
                if let sideBar = self.sideBarViewController {
                    self.sideBarViewController = nil
                    self.mainView.removeSideBar(sideBar.view)
                    self.masterDetailVC.putMasterBack()
                }
            }
            if updateDetail, !hideDetail {
                if self.config.detailAsModalShouldStayInPlace {
                    self.hideDetailAsModalInPlace()
                }
                self.masterDetailVC.addDetailView()
            }
            // Then, removing from the stack view
            if updateTabBar, hideTabBar {
                self.addNavigationSideBar()
            }
            if updateMaster, hideMaster, !hideDetail {
                if let sideBar = self.masterDetailVC.prepareMasterForSideBar() {
                    self.addMasterSideBar(sideBar)
                    self.sideBarViewController = sideBar
                }
            }
        }, completion: { _ in
            if updateMaster, hideMaster, !hideDetail {
                self.masterDetailVC.hideMasterView = true
            }
            if updateTabBar {
                self.mainView.hideTabBarView = hideTabBar
            }
            if updateDetail {
                self.masterDetailVC.hideDetailView = hideDetail
                if hideDetail {
                    self.presentDetailAsModal()
                }
            }
        })

        futureTraits = nil
    }

    // MARK: - Private functions

    private func addMasterSideBar(_ sideBar: UIViewController) {
        mainView.addSideBar(sideBar.view, leftOffset: config.tabBarWidth, willOpen: { [weak self] in
            self?.tabBarVC.tabBar.isOpen = true
        }, willClose: { [weak self] in
            self?.tabBarVC.tabBar.isOpen = false
        })
    }

    private func presentDetailAsModal() {
        if config.detailAsModalShouldStayInPlace {
            if detailViewController != nil {
                presentDetailInPlace()
            } else {
                self.masterDetailVC.removeDetailView(removeFromViewHierarchy: true)
            }
        } else {
            self.masterDetailVC.removeDetailView(removeFromViewHierarchy: true)
            if let detail = detailViewController {
                // Remove the view controller from the DetailVC, but keep it saved in TSVC
                masterDetailVC.setDetailViewController(nil, animate: false)
                detail.view.translatesAutoresizingMaskIntoConstraints = true
                self.present(detail, animated: false)
            }
        }
    }
    private func hideDetailAsModal() {
        if let detail = detailViewController {
            dismiss(animated: false) {
                self.masterDetailVC.setDetailViewController(detail, animate: false)
            }
        }
    }
    private func hideDetailAsModalInPlace() {
        logger?.log("Move detail back to the stack view")
        hideDetailInPlace(keepShown: !self.state.detailHidden, then: nil)
    }

    private func presentDetailInPlace() {
        let animator = UIViewPropertyAnimator(duration: 0.33, curve: .easeInOut, animations: nil)

        if !state.tabBarHidden {
            mainView.hideTabBar(animator: animator)
        }
        self.masterDetailVC.presentFullWidthDetailView(
            animator: animator,
            hideMaster: !state.masterHidden,
            initialOffset: state.tabBarHidden ? 0 : self.config.tabBarWidth
        )
        mainView.setSideBarGestureRecognizerEnabled(false)

        animator.startAnimation()
    }
    private func hideDetailInPlace(keepShown: Bool, then completion: (() -> Void)?) {
        let animator = UIViewPropertyAnimator(duration: 0.33, curve: .easeInOut, animations: nil)

        if let animationCompleted = completion {
            animator.addCompletion { _ in
                animationCompleted()
            }
        }
        if !state.tabBarHidden {
            mainView.showTabBar(animator: animator)
        }

        self.masterDetailVC.closeFullWidthDetailView(
            animator: animator,
            keepShown: keepShown,
            showMaster: !state.masterHidden,
            masterOffset: state.tabBarHidden ? 0 : self.config.tabBarWidth
        )
        mainView.setSideBarGestureRecognizerEnabled(true)

        animator.startAnimation()
    }

    private func addNavigationSideBar() {
        let navVC = configureNavigationBar(tabBarVC.tabBar.items, tabBarVC.actionsBar.items, tabBarVC.tabBar.didSelectCallback!, tabBarVC.actionsBar.didSelectCallback!, selectedTabBarItemIndex)
        sideBarViewController = navVC
        addChild(navVC)
        mainView.addNavigationBar(navVC.view)
        navVC.didMove(toParent: self)
    }
    private func removeNavigationSideBar(keepTabBarHidden: Bool) {
        guard let navVC = sideBarViewController else { return }

        navVC.willMove(toParent: nil)
        self.mainView.removeSideBar(navVC.view)
        self.mainView.putTabBarBack(keepHidden: keepTabBarHidden)
        navVC.removeFromParent()
        sideBarViewController = nil
    }

    private func replaceContent(with contentVC: UIViewController) {
        guard contentVC != self.currentContentVC else {
            return
        }

        let prevVC = self.currentContentVC
        self.currentContentVC = contentVC

        self.addChild(contentVC)
        contentVC.willMove(toParent: self)
        self.mainView.replaceContentView(with: contentVC.view) {
            prevVC.removeFromParent()
            prevVC.viewIfLoaded?.removeFromSuperview()
            contentVC.didMove(toParent: self)
        }


    }
    private func resetContentToMasterDetail() {
        self.replaceContent(with: self.masterDetailVC)
    }

    // MARK: - Public functions

    /// Use TabbedSplitViewController.showDetailViewController(_:completion:) instead.
    public override func showDetailViewController(_ vc: UIViewController, sender: Any? = nil) {
        showDetailViewController(vc, completion: nil)
    }
    public func showDetailViewController(_ vc: UIViewController, completion: (() -> Void)? = nil) {
        // Show Detail screen if needed
        if self.masterDetailVC.hideDetailView {
            // Hide master view while opening a detail
            mainView.hideSideBar()

            if config.detailAsModalShouldStayInPlace {
                presentDetailInPlace()
                masterDetailVC.setDetailViewController(vc, animate: false, completion: completion)
            } else {
                present(vc, animated: true, completion: completion)
            }
        } else {
            if self.masterDetailVC.hideMasterView {
                // Hide master view while opening a detail
                mainView.hideSideBar()
            }
            masterDetailVC.setDetailViewController(vc, animate: true, completion: completion)
        }
        self.detailViewController = vc
    }

    public func dismissDetailViewController(animated flag: Bool = true, completion: (() -> Void)? = nil) {
        if self.masterDetailVC.hideDetailView {
            if config.detailAsModalShouldStayInPlace {
                hideDetailInPlace(keepShown: false, then: {
                    self.masterDetailVC.setDetailViewController(nil, animate: false, completion: completion)
                })
            } else {
                dismiss(animated: flag, completion: completion)
            }
        }
        else if detailViewController != nil {
            logger?.log("Removing presented detail VC from parent VC")
            masterDetailVC.setDetailViewController(nil, animate: true, completion: completion)
        }
        self.detailViewController = nil
    }

    /// Add an item with a view controller to open to the main tab bar
    /// - parameters:
    ///   - item: A tab bar item with a view controller as an action
    public func addToTabBar(_ item: PKTabBarItem<TabBarScreenConfiguration>) {
        tabBarVC.tabBar.appendItem(item)
    }
    /// Insert an item with a view controller at a specific position on the tab bar
    /// - parameters:
    ///   - item: A tab bar item with a view controller as an action
    ///   - index: Position on the tab bar
    public func insertToTabBar(_ item: PKTabBarItem<TabBarScreenConfiguration>, at index: Int) {
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
            tabBarVC.tabBarWidth = config.tabBarWidth
        }
        if config.tabBarBackgroundColor != oldConfig.tabBarBackgroundColor {
            tabBarVC.backgroundColor = config.tabBarBackgroundColor
        }
        if config.verticalSeparatorColor != oldConfig.verticalSeparatorColor {
            tabBarVC.verticalSeparatorColor = config.verticalSeparatorColor
        }
        masterDetailVC.config = config
    }

}
