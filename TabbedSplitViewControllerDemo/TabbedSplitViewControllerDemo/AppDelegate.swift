//
//  AppDelegate.swift
//  TabbedSplitViewControllerDemo
//
//  Created by Pavel Kazantsev on 29/06/15.
//  Copyright (c) 2015 Pavel Kazantsev. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        if let viewController = self.window?.rootViewController as? TabbedSplitViewController {
            viewController.addTabBarItem(PKTabBarItem(viewController: ViewController(), title: "Controller", image: UIImage(named: "Peotr")!))
        }

        return true
    }

}

