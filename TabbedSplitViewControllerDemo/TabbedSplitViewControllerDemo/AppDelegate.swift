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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if let viewController = self.window?.rootViewController as? TabbedSplitViewController {
            viewController.add(PKTabBarItem(viewController: ViewController(), title: "Controller", image: UIImage(named: "Peotr")!))
        }

        return true
    }

}

