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

    var config = Configuration() {
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

    private var hideTabBarView: Bool = false {
        didSet {
            tabBar.view.isHidden = hideTabBarView
        }
    }
    private var hideMasterView: Bool = false {
        didSet {
            masterVC.view.isHidden = hideMasterView
        }
    }
    private var hideDetailView: Bool = false {
        didSet {
            detailVC.view.isHidden = hideDetailView
            masterVC.widthConstraint?.isActive = !hideDetailView
        }
    }

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
            hideTabBarView = hideTabBar
        }
        if let hideMaster = config.showMasterAsSideBarWithSizeChange?(view.frame.size, traitCollection, config) {
            hideMasterView = hideMaster
        }
        // Hide detail from main view if there is not enough width
        if let hideDetail = config.showDetailAsModalWithSizeChange?(view.frame.size, traitCollection, config) {
            hideDetailView = hideDetail
        }
    }

    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        print("\(#function) -> \(newCollection)")
        futureTraits = newCollection
    }
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("\(#function) -> \(size)")
        let traits = futureTraits ?? traitCollection
        if let hideDetailFunc = config.showDetailAsModalWithSizeChange {
            let hideDetail = hideDetailFunc(size, traits, config)
            print("hide detail view: \(hideDetail)")
            hideDetailView = hideDetail
        }
        if let hideMasterFunc = config.showMasterAsSideBarWithSizeChange {
            let hideMaster = hideMasterFunc(size, traits, config)
            print("hide master view: \(hideMaster)")
            hideMasterView = hideMaster
        }
        if let hideTabBarFunc = config.showTabBarAsSideBarWithSizeChange {
            let hideTabBar = hideTabBarFunc(size, traits, config)
            print("hide Tab Bar: \(hideTabBar)")
            hideTabBarView = hideTabBar
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

@IBDesignable
public class PKTabbedSplitView: UIView {
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

    public init(tabBarView: UIView, masterView: UIView, detailView: UIView) {
        tabBarWidthConstraint = NSLayoutConstraint(item: tabBarView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: tabBarWidth)
        masterViewWidthConstraint = NSLayoutConstraint(item: masterView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: masterViewWidth)

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

        let stackView = UIStackView(arrangedSubviews: [tabBarView, masterView, detailView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = 0
        addSubview(stackView)

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[stack]|", options: [], metrics: [:], views: ["stack": stackView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[stack]|", options: [], metrics: [:], views: ["stack": stackView]))
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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

    init() {
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

    init() {
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
