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
            viewController.config.masterViewWidth = 320
            /// Use on iPad in portrait
            viewController.config.showMasterAsSideBarWithSizeChange = { size, traits, config in
                return traits.userInterfaceIdiom == .pad && size.width <= 768
            }
            /// Use on iPhone except Plus models in landscape
            viewController.config.showDetailAsModalWithSizeChange = { size, traits, config in
                return traits.horizontalSizeClass == .compact
            }
            viewController.add(PKTabBarItem(viewController: ViewController(), title: "Controller", image: UIImage(named: "Peotr")!))
        }

        return true
    }

}

