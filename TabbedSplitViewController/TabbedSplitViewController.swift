//
//  TabbedSplitViewController.swift
//
//  Created by Pavel Kazantsev on 29/06/15.
//  Copyright (c) 2015 Pavel Kazantsev. All rights reserved.
//

import UIKit

public class TabbedSplitViewController: UIViewController {

    @IBInspectable
    var tabBarWidth: CGFloat = 70 {
        didSet {
            self.mainView.tabBarWidth = tabBarWidth
        }
    }
    @IBInspectable
    var masterViewWidth: CGFloat = 300 {
        didSet {
            self.mainView.masterViewWidth = masterViewWidth
        }
    }
    @IBInspectable
    var tabBarBackgroundColor: UIColor = UIColor.whiteColor() {
        didSet {
            self.tabBar.backgroundColor = tabBarBackgroundColor
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

    init(tabBarItems: [PKTabBarItem]) {
        mainView = PKTabbedSplitView(tabBarView: tabBar.view, masterView: masterVC.view, detailView: detailVC.view)

        super.init(nibName: nil, bundle: nil)

        tabBar.items = tabBarItems
    }

    public required init?(coder aDecoder: NSCoder) {
        mainView = PKTabbedSplitView(tabBarView: tabBar.view, masterView: masterVC.view, detailView: detailVC.view)

        super.init(coder: aDecoder)
    }

    public override func loadView() {
        self.view = mainView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.addChildViewController(tabBar)
        self.addChildViewController(masterVC)
        self.addChildViewController(detailVC)

        self.view.backgroundColor = UIColor.grayColor()

    }

    public override func viewWillAppear(animated: Bool) {
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
        self.tabBar.view.backgroundColor = UIColor.purpleColor()
        self.masterVC.view.backgroundColor = UIColor.greenColor()
    }

    public func addTabBarItem(item: PKTabBarItem) {
        self.tabBar.items.append(item)
    }

}

@IBDesignable
public class PKTabbedSplitView: UIView {
    private var tabBarWidth: CGFloat = 70 {
        didSet {
            tabBarWidthConstraint.constant = tabBarWidth
        }
    }
    private var masterViewWidth: CGFloat = 300 {
        didSet {
            masterViewWidthConstraint.constant = masterViewWidth
        }
    }
    private let tabBarWidthConstraint: NSLayoutConstraint!
    private let masterViewWidthConstraint: NSLayoutConstraint!

    public init(tabBarView: UIView, masterView: UIView, detailView: UIView) {
        tabBarWidthConstraint = NSLayoutConstraint(item: tabBarView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: tabBarWidth)
        masterViewWidthConstraint = NSLayoutConstraint(item: masterView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: masterViewWidth)

        super.init(frame: CGRect())

        tabBarView.addConstraint(tabBarWidthConstraint)
        masterView.addConstraint(masterViewWidthConstraint)

        if #available(iOS 8.0, *) {
            detailView.preservesSuperviewLayoutMargins = true
            masterView.preservesSuperviewLayoutMargins = true
            tabBarView.preservesSuperviewLayoutMargins = true
        } else {
            // Fallback on earlier versions
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        detailView.translatesAutoresizingMaskIntoConstraints = false
        masterView.translatesAutoresizingMaskIntoConstraints = false
        tabBarView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(detailView)
        self.addSubview(masterView)
        self.addSubview(tabBarView)

        let views = ["detailView": detailView, "masterView": masterView, "tabBarView": tabBarView]

        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[tabBarView]-0-[masterView]-0-[detailView]-0-|", options: .DirectionLeadingToTrailing, metrics: [:], views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[tabBarView]-|", options: .DirectionLeadingToTrailing, metrics: [:], views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[masterView]-|", options: .DirectionLeadingToTrailing, metrics: [:], views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[detailView]-|", options: .DirectionLeadingToTrailing, metrics: [:], views: views))
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private let pkTabBarItemCellIdentifier = "PkTabBarItemCellIdentifier"

private class PKTabBar: UITableViewController {
    private var items = [PKTabBarItem]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    var backgroundColor: UIColor = UIColor.whiteColor() {
        didSet {
            self.view.backgroundColor = backgroundColor
        }
    }

    private override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.scrollEnabled = false
        self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40));
        self.tableView.estimatedRowHeight = 40
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
//        self.tableView.separatorStyle = .None
        self.tableView.registerClass(PkTabBarItemTableViewCell.self, forCellReuseIdentifier: pkTabBarItemCellIdentifier)
    }

    private override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    private override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(pkTabBarItemCellIdentifier, forIndexPath: indexPath) as! PkTabBarItemTableViewCell

        if items.count > indexPath.row {
            let item = self.items[indexPath.row]
            cell.titleLabel.text = item.title
            cell.iconImageView.image = item.image
        }

        return cell;
    }
}

private class PkTabBarItemTableViewCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let iconImageView = UIImageView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = UIFont.systemFontOfSize(10)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentHuggingPriority(249, forAxis: .Vertical)
        titleLabel.textAlignment = .Center

        iconImageView.contentMode = .Center
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(iconImageView)

        let views = ["titleLabel": titleLabel, "iconImageView": iconImageView]

//        self.contentView.preservesSuperviewLayoutMargins = true
        let constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-5-[iconImageView]-5-[titleLabel]-5-|", options: .DirectionLeadingToTrailing, metrics: nil, views: views)
        self.contentView.addConstraints(constraints)
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[iconImageView]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views));
        self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[titleLabel]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views));
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

public struct PKTabBarItem {
    let title: String
    let image: UIImage
    let selectedImage: UIImage?
    let viewController: UIViewController

    init(viewController: UIViewController, title: String, image: UIImage, selectedImage: UIImage? = nil) {
        self.title = title
        self.image = image
        self.selectedImage = selectedImage;
        self.viewController = viewController
    }
}

private class PKMasterViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = UIColor.greenColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
private class PKDetailViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = UIColor.grayColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
