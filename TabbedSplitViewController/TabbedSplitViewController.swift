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
    var masterViewWidth: CGFloat = 320 {
        didSet {
            self.mainView.masterViewWidth = masterViewWidth
        }
    }
    @IBInspectable
    var tabBarBackgroundColor: UIColor = UIColor.whiteColor()

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

    public required init(coder aDecoder: NSCoder) {
        mainView = PKTabbedSplitView(tabBarView: tabBar.view, masterView: masterVC.view, detailView: detailVC.view)

        super.init(coder: aDecoder)
    }

    public override func loadView() {
        self.view = mainView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.grayColor()

        // Show master if view size is appropriate
    }

    // This method compiles with the rest of your code 
    // but is only executed when your view is being prepared for display in Interface Builder.
    public override func prepareForInterfaceBuilder() {
        //
        self.tabBar.view.backgroundColor = UIColor.purpleColor()
        self.masterVC.view.backgroundColor = UIColor.greenColor()
    }

}

@IBDesignable
public class PKTabbedSplitView: UIView {
    private var tabBarWidth: CGFloat = 70 {
        didSet {
            tabBarWidthConstraint.constant = tabBarWidth
        }
    }
    private var masterViewWidth: CGFloat = 320 {
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

        detailView.preservesSuperviewLayoutMargins = true
        masterView.preservesSuperviewLayoutMargins = true
        tabBarView.preservesSuperviewLayoutMargins = true
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        detailView.setTranslatesAutoresizingMaskIntoConstraints(false)
        masterView.setTranslatesAutoresizingMaskIntoConstraints(false)
        tabBarView.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.addSubview(detailView)
        self.addSubview(masterView)
        self.addSubview(tabBarView)

        var views = ["detailView": detailView, "masterView": masterView, "tabBarView": tabBarView]

        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[tabBarView]-0-[masterView]-0-[detailView]-0-|", options: .DirectionLeadingToTrailing, metrics: [:], views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[tabBarView]-|", options: .DirectionLeadingToTrailing, metrics: [:], views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[masterView]-|", options: .DirectionLeadingToTrailing, metrics: [:], views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[detailView]-|", options: .DirectionLeadingToTrailing, metrics: [:], views: views))
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        //
    }

}

private class PKTabBar: UITableViewController {
    private var items = [PKTabBarItem]()
}

struct PKTabBarItem {
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

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
private class PKDetailViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = UIColor.whiteColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
