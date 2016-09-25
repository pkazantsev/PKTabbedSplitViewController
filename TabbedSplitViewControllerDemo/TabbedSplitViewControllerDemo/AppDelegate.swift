//
//  AppDelegate.swift
//  TabbedSplitViewControllerDemo
//
//  Created by Pavel Kazantsev on 29/06/15.
//  Copyright (c) 2015 Pavel Kazantsev. All rights reserved.
//

import UIKit
import TabbedSplitViewController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if let viewController = self.window?.rootViewController as? TabbedSplitViewController {
            var config = viewController.config
            config.showMasterAsSideBarWithSizeChange = { size, traits, config in
                /// Master should be hidden on iPad in Portrait or in multi-tasking mode unless it's iPhone-width.
                return traits.userInterfaceIdiom == .pad && size.width <= 768 && size.width > 370
            }
            config.showDetailAsModalWithSizeChange = { size, traits, config in
                /// Use on iPad in compact mode and on iPhone except Plus models in landscape
                return traits.horizontalSizeClass == .compact && size.width <= 370
            }
            config.showTabBarAsSideBarWithSizeChange = { size, traits, config in
                /// Use on iPad in compact mode and on iPhone 4s/5/5s/SE
                return traits.horizontalSizeClass == .compact && size.width <= 320
            }

            viewController.config = config
            viewController.add(PKTabBarItem(viewController: ViewController(), title: "Controller", image: UIImage(named: "Peotr")!))
        }

        return true
    }

}

