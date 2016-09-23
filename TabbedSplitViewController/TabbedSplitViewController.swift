//
//  TabbedSplitViewController.swift
//
//  Created by Pavel Kazantsev on 29/06/15.
//  Copyright (c) 2015 Pavel Kazantsev. All rights reserved.
//

import UIKit

public struct PKTabBarItem {
    /// Item title
    let title: String
    /// Item image (up to 60pt)
    let image: UIImage
    /// Item image – selected state
    let selectedImage: UIImage?
    /// View controller that should be open by tap on the item
    let viewController: UIViewController

    init(viewController: UIViewController, title: String, image: UIImage, selectedImage: UIImage? = nil) {
        self.title = title
        self.image = image
        self.selectedImage = selectedImage;
        self.viewController = viewController
    }
}

public class TabbedSplitViewController: UIViewController {

    @IBInspectable
    var tabBarWidth: CGFloat = 70 {
        didSet {
            mainView.tabBarWidth = tabBarWidth
        }
    }
    @IBInspectable
    var masterViewWidth: CGFloat = 300 {
        didSet {
            mainView.masterViewWidth = masterViewWidth
        }
    }
    @IBInspectable
    var tabBarBackgroundColor: UIColor = .white {
        didSet {
            tabBar.backgroundColor = tabBarBackgroundColor
        }
    }

    var hideMasterInPortrait = false

    private(set) var masterViewController: UIViewController?
    private var detailViewController: UIViewController?

    private let masterVC = PKMasterViewController()
    private let detailVC = PKDetailViewController()
    private let tabBar = PKTabBar()
    private let mainView: PKTabbedSplitView
    private var masterViewIsHidden: Bool = false

    init(items: [PKTabBarItem]) {
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

        view.backgroundColor = .gray

    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Show detail if view size is appropriate
        if 320 < view.bounds.size.width - masterViewWidth - tabBarWidth {
            // Hide detail
        }
    }

    // This method compiles with the rest of your code 
    // but is only executed when your view is being prepared for display in Interface Builder.
    public override func prepareForInterfaceBuilder() {
        //
        tabBar.view.backgroundColor = .purple
        masterVC.view.backgroundColor = .green
    }

    public func add(_ item: PKTabBarItem) {
        tabBar.items.append(item)
    }

}

@IBDesignable
public class PKTabbedSplitView: UIView {
    fileprivate var tabBarWidth: CGFloat = 70 {
        didSet {
            tabBarWidthConstraint.constant = tabBarWidth
        }
    }
    fileprivate var masterViewWidth: CGFloat = 300 {
        didSet {
            masterViewWidthConstraint.constant = masterViewWidth
        }
    }
    private let tabBarWidthConstraint: NSLayoutConstraint!
    private let masterViewWidthConstraint: NSLayoutConstraint!

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

        addSubview(detailView)
        addSubview(masterView)
        addSubview(tabBarView)

        let views = ["detailView": detailView, "masterView": masterView, "tabBarView": tabBarView]

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[tabBarView]-0-[masterView]-0-[detailView]-0-|", options: .directionLeadingToTrailing, metrics: [:], views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[tabBarView]-|", options: .directionLeadingToTrailing, metrics: [:], views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[masterView]-|", options: .directionLeadingToTrailing, metrics: [:], views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[detailView]-|", options: .directionLeadingToTrailing, metrics: [:], views: views))
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

    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .green
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
private class PKDetailViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .gray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
